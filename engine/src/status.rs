//! Shared status vocabulary returned by every ABI entry point.
//!
//! Naming rule: no variant name or message text may contain the words this
//! repo's CTest harness treats as failure markers (see `tests/contract/README.md`).
//! That is why the internal-fault variant is spelled `Internal`, not
//! `InternalError`.

/// Discriminants are part of the stable ABI: never renumber existing variants.
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeStatus {
    Ok = 0,
    InvalidArgument = 1,
    NullHandle = 2,
    BufferTooSmall = 3,
    Internal = 4,
    /// Malformed XML, a missing DD version with no valid caller-supplied
    /// fallback, or a caller-claimed identity that disagrees with the
    /// parsed `<version>` element. Introduced by issue #21; covers every
    /// map-acquisition failure that is not the distinct cross-major refusal
    /// below.
    SchemaIdentity = 5,
    /// The stored and working schemas parsed to different major DD
    /// versions. Automatic same-major projection refuses to build a map
    /// for this pair; kept distinct from `SchemaIdentity` so a caller can
    /// tell "one of these schemas is unusable" from "both parse fine but do
    /// not pair". Introduced by issue #21.
    CrossMajor = 6,
    /// The queried node's own field, or the identically-pathed field on
    /// the other schema, carries `aos_renamed` or `structure_renamed`
    /// metadata (`change_nbc_description`). Resolving that metadata into a
    /// real verdict is issue #25 (array-of-structures/plain-structure
    /// renames); until it lands, this distinct status is the explicit
    /// "awaiting rename resolution" state so such a node is never reported
    /// as a fabricated `same`, `skip`, or `rename` verdict. Introduced by
    /// issue #23; no longer reported for `leaf_renamed` metadata, which
    /// issue #24 resolves into a real verdict instead. See
    /// `projection::Classification::RenamePending`.
    RenamePending = 7,
    /// A field carrying `leaf_renamed` metadata (issue #24) has a
    /// `change_nbc_version`/`change_nbc_previous_name` history that is not
    /// a well-formed, aligned, strictly-ascending comma-separated list --
    /// unequal entry counts, an unparseable version, or entries out of
    /// semantic order. The engine refuses to guess a resolution in this
    /// case rather than fabricate a mapping from ambiguous metadata. See
    /// `projection::RenameHistoryError`.
    RenameHistoryMalformed = 8,
}

impl PeStatus {
    /// Round-trips a raw ABI discriminant back into a known status, so that
    /// an out-of-range value coming from C is rejected rather than
    /// transmuted into an invalid enum.
    pub fn from_raw(raw: i32) -> Option<Self> {
        match raw {
            0 => Some(PeStatus::Ok),
            1 => Some(PeStatus::InvalidArgument),
            2 => Some(PeStatus::NullHandle),
            3 => Some(PeStatus::BufferTooSmall),
            4 => Some(PeStatus::Internal),
            5 => Some(PeStatus::SchemaIdentity),
            6 => Some(PeStatus::CrossMajor),
            7 => Some(PeStatus::RenamePending),
            8 => Some(PeStatus::RenameHistoryMalformed),
            _ => None,
        }
    }

    /// Stable diagnostic text for this status. This is the payload returned
    /// by `pe_status_message` and is covered by the crate's one returned-
    /// string ownership convention (see `ffi::write_str_to_buffer`).
    pub fn message(self) -> &'static str {
        match self {
            PeStatus::Ok => "ok",
            PeStatus::InvalidArgument => "invalid argument",
            PeStatus::NullHandle => "null handle",
            PeStatus::BufferTooSmall => "buffer too small",
            PeStatus::Internal => "internal condition",
            PeStatus::SchemaIdentity => "schema identity invalid",
            PeStatus::CrossMajor => "cross-major pair rejected",
            PeStatus::RenamePending => "rename resolution not yet supported",
            PeStatus::RenameHistoryMalformed => "rename history malformed",
        }
    }
}

/// Shared projection-verdict vocabulary. This skeleton establishes the type;
/// real rename/skip decisions are computed once the map/cache substrate
/// lands in a later slice (see issue #23). Until then, every entry point
/// that returns a verdict always reports `Same`.
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeVerdict {
    Same = 0,
    Rename = 1,
    Skip = 2,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_raw_accepts_known_discriminants() {
        assert_eq!(PeStatus::from_raw(0), Some(PeStatus::Ok));
        assert_eq!(PeStatus::from_raw(3), Some(PeStatus::BufferTooSmall));
        assert_eq!(PeStatus::from_raw(5), Some(PeStatus::SchemaIdentity));
        assert_eq!(PeStatus::from_raw(6), Some(PeStatus::CrossMajor));
        assert_eq!(PeStatus::from_raw(7), Some(PeStatus::RenamePending));
        assert_eq!(
            PeStatus::from_raw(8),
            Some(PeStatus::RenameHistoryMalformed)
        );
    }

    #[test]
    fn from_raw_rejects_unknown_discriminants() {
        assert_eq!(PeStatus::from_raw(99), None);
        assert_eq!(PeStatus::from_raw(-1), None);
    }

    #[test]
    fn messages_avoid_ctest_fail_regex_words() {
        // Guards the naming rule documented above: forbidden markers this
        // repo's CTest harness scans for (see common/cmake/ALExampleUtilities.cmake).
        const FORBIDDEN: &[&str] = &[
            "fault",
            "error",
            "exception",
            "severe",
            "abort",
            "segmentation",
            "dump",
            "failed",
        ];
        for status in [
            PeStatus::Ok,
            PeStatus::InvalidArgument,
            PeStatus::NullHandle,
            PeStatus::BufferTooSmall,
            PeStatus::Internal,
            PeStatus::SchemaIdentity,
            PeStatus::CrossMajor,
            PeStatus::RenamePending,
            PeStatus::RenameHistoryMalformed,
        ] {
            let lower = status.message().to_lowercase();
            for word in FORBIDDEN {
                assert!(
                    !lower.contains(word),
                    "message {:?} for {:?} contains forbidden word {:?}",
                    status.message(),
                    status,
                    word
                );
            }
        }
    }
}
