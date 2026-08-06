//! The context table: what absolute DD path an al-core context id stands for.
//!
//! This exists because `al_read_data` is not given a DD path. It is given a *context* and
//! a path **relative to that context**, and the interesting paths are all deep inside
//! one:
//!
//! ```text
//! al_begin_global_action(pulse, "equilibrium", …)      -> ctx 2   ""
//! al_begin_arraystruct_action(2, "time_slice", …)      -> ctx 6   "time_slice"
//! al_read_data(6, "profiles_1d/psi", …)                          "time_slice/profiles_1d/psi"
//! ```
//!
//! A traced `equilibrium` get shows this plainly: `time_slice` never appears in a field
//! name, and every profile is read as `profiles_1d/…` against ctx 6. The map's paths are
//! absolute and IDS-relative, so without this table the shim would have to guess which
//! map path a relative name belongs to by suffix — which is unsound the moment two
//! structures share a leaf name.
//!
//! Each frame carries **two** prefixes. `right` is what the DD 4.1.1 caller thinks the
//! context is, and is what the map is asked about. `left` is what al-core was actually
//! told to open, which is the DD 3.39.0 path once an array-of-structure has been
//! rewritten. Both are needed: a read resolves right → left absolutely, then has to be
//! expressed relative to the context al-core has, and after `boundary/gap` has been
//! opened as `boundary_separatrix/gap` the two no longer share a prefix.

use std::ffi::c_int;
use std::sync::Mutex;

/// al-core's `READ_OP` (`OP_ACCESS_0`, `wrapper/al_defs.f90`). A write context is
/// registered like any other so that an array-of-structure opened under it inherits the
/// mode — rewriting a *put*'s path would corrupt what it writes.
pub const READ_OP: c_int = 30;

struct Frame {
    id: c_int,
    /// The IDS this context belongs to, so a map only ever fires on the IDS it describes.
    ids: String,
    /// The context's path as the DD 4.1.1 caller sees it, IDS-relative, no trailing slash.
    right: String,
    /// The context's path as al-core has it — DD 3.39.0 once a rewrite has happened.
    left: String,
    read: bool,
}

/// Live contexts. A get holds a handful at a time (IDS root, one per nested
/// array-of-structure), so a linear scan of a short `Vec` beats anything with a hash.
static FRAMES: Mutex<Vec<Frame>> = Mutex::new(Vec::new());

/// A read expressed in both versions' terms.
pub struct Request {
    /// The absolute DD 4.1.1 path, to look up in the map.
    pub right: String,
    /// The context's DD 3.39.0 prefix, to make the map's answer relative again.
    pub left_prefix: String,
}

/// Register a context opened directly on an IDS — global, slice or timerange. Its path is
/// the IDS root unless al-core was given a `datapath`, which the Fortran wrapper leaves
/// empty.
pub fn open_root(id: c_int, ids: &str, datapath: &str, read: bool) {
    let path = normalise(datapath);
    insert(Frame {
        id,
        ids: ids.to_string(),
        right: path.clone(),
        left: path,
        read,
    });
}

/// Register an array-of-structure context under `parent`. `right_path` is what the caller
/// asked for and `left_path` what al-core was told, which differ exactly when the map
/// moved or renamed the structure. Does nothing if the parent is unknown: an unregistered
/// context means pass-through, and inventing a root for it would make relative paths
/// resolve against the wrong place.
pub fn open_child(parent: c_int, id: c_int, right_path: &str, left_path: &str) {
    let Some((ids, right, left, read)) = with_frame(parent, |frame| {
        (
            frame.ids.clone(),
            join(&frame.right, right_path),
            join(&frame.left, left_path),
            frame.read,
        )
    }) else {
        return;
    };
    insert(Frame {
        id,
        ids,
        right,
        left,
        read,
    });
}

/// Forget a context. al-core reuses ids, so a frame that outlived its `al_end_action`
/// would answer for whatever opens next.
pub fn close(id: c_int) {
    if let Ok(mut frames) = FRAMES.lock() {
        frames.retain(|frame| frame.id != id);
    }
}

/// Where `field` sits in both versions, or `None` when the context is unknown, belongs to
/// another IDS, or is not a read — all of which mean "forward untouched".
pub fn locate(id: c_int, field: &str, ids: &str) -> Option<Request> {
    with_frame(id, |frame| {
        if !frame.read || frame.ids != ids {
            return None;
        }
        Some(Request {
            // A leading `/` is how the generated code spells a path from the IDS root
            // (timebases do it); it overrides the context prefix rather than nesting.
            right: if field.starts_with('/') {
                normalise(field)
            } else {
                join(&frame.right, field)
            },
            left_prefix: frame.left.clone(),
        })
    })
    .flatten()
}

/// Express an absolute left path relative to a context, the way al-core wants it.
/// `None` when the path does not live under the context at all — a value that moved to a
/// different parent cannot be fetched through this context, and reporting that beats
/// sending al-core a path that means something else.
pub fn relative(left_prefix: &str, absolute_left: &str) -> Option<String> {
    if left_prefix.is_empty() {
        return Some(absolute_left.to_string());
    }
    absolute_left
        .strip_prefix(left_prefix)
        .and_then(|rest| rest.strip_prefix('/'))
        .map(str::to_string)
}

fn insert(frame: Frame) {
    if let Ok(mut frames) = FRAMES.lock() {
        // al-core reuses ids after an end_action; replace rather than shadow so a stale
        // frame can never be found first.
        frames.retain(|open| open.id != frame.id);
        frames.push(frame);
    }
}

fn with_frame<R>(id: c_int, f: impl FnOnce(&Frame) -> R) -> Option<R> {
    let frames = FRAMES.lock().ok()?;
    frames.iter().find(|frame| frame.id == id).map(f)
}

/// `a/b` from a prefix and a relative path, tolerating empties and stray slashes — the
/// generated code passes both `path//"x"` and a bare `""`.
fn join(prefix: &str, rest: &str) -> String {
    let rest = rest.trim_matches('/');
    if prefix.is_empty() {
        return rest.to_string();
    }
    if rest.is_empty() {
        return prefix.to_string();
    }
    format!("{prefix}/{rest}")
}

fn normalise(path: &str) -> String {
    path.trim_matches('/').to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// One test drives the whole table: it is process-global, so splitting it into
    /// several would let cargo's threads see each other's frames.
    #[test]
    fn nested_contexts_reconstruct_absolute_paths_in_both_versions() {
        open_root(2, "equilibrium", "", true);

        // time_slice is spelled the same in both versions.
        open_child(2, 6, "time_slice", "time_slice");
        let request = locate(6, "profiles_1d/psi", "equilibrium").expect("ctx 6 is a read");
        assert_eq!(request.right, "time_slice/profiles_1d/psi");
        assert_eq!(request.left_prefix, "time_slice");
        assert_eq!(
            relative(&request.left_prefix, "time_slice/profiles_1d/psi").as_deref(),
            Some("profiles_1d/psi")
        );

        // boundary/gap was opened as boundary_separatrix/gap, so the two prefixes part
        // company — the case that makes carrying both necessary.
        open_child(6, 9, "boundary/gap", "boundary_separatrix/gap");
        let request = locate(9, "value", "equilibrium").expect("ctx 9 is a read");
        assert_eq!(request.right, "time_slice/boundary/gap/value");
        assert_eq!(request.left_prefix, "time_slice/boundary_separatrix/gap");
        assert_eq!(
            relative(
                &request.left_prefix,
                "time_slice/boundary_separatrix/gap/value"
            )
            .as_deref(),
            Some("value")
        );

        // A path outside the context cannot be expressed relative to it.
        assert_eq!(
            relative(&request.left_prefix, "time_slice/boundary/outline/r"),
            None
        );

        // Another IDS's read is not this map's business.
        assert!(locate(6, "profiles_1d/psi", "magnetics").is_none());

        // A leading slash means "from the IDS root", ignoring the context prefix.
        assert_eq!(
            locate(6, "/time", "equilibrium").map(|r| r.right),
            Some("time".to_string())
        );

        // Closing a context forgets it, including for ids al-core later reuses.
        close(9);
        assert!(locate(9, "value", "equilibrium").is_none());

        // A write context is registered but never rewritten, and its children inherit.
        open_root(3, "equilibrium", "", false);
        open_child(3, 4, "time_slice", "time_slice");
        assert!(locate(3, "time", "equilibrium").is_none());
        assert!(locate(4, "profiles_1d/psi", "equilibrium").is_none());

        // An unknown parent registers nothing rather than inventing a root.
        open_child(99, 100, "time_slice", "time_slice");
        assert!(locate(100, "profiles_1d/psi", "equilibrium").is_none());

        close(2);
        close(3);
        close(4);
        close(6);
    }
}
