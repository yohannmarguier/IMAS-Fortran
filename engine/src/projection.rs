//! `field/@path` indexing and rename-metadata projection classification
//! (issues #23, #24).
//!
//! #23 classified a node into the categories that need no rename history:
//! [`Same`], [`SourceOnly`] (a compiled-only or stored-only field, depending
//! on which schema plays source for a given query), and [`DatatypeChanged`].
//! #24 adds real resolution for `change_nbc_description="leaf_renamed"`
//! metadata, including comma-separated successive histories, using the
//! version-cutoff rule researched from IMAS-Python in issue #13:
//! `may_have_renamed_from` for `aos_renamed`/`structure_renamed` -- deferred
//! to issue #25 -- still withholds a fabricated add/remove verdict in the
//! distinct [`RenamePending`] state; see that variant's doc comment.
//!
//! [`Same`]: Classification::Same
//! [`SourceOnly`]: Classification::SourceOnly
//! [`DatatypeChanged`]: Classification::DatatypeChanged
//! [`RenamePending`]: Classification::RenamePending

use std::collections::HashMap;

use crate::version::DdVersion;

/// Which automatic, metadata-driven rename kind a field's
/// `change_nbc_description` names (see #18's "Rename-map construction"
/// decision). Any other `change_nbc_description` value (e.g.
/// `type_changed`, `ids_renamed`) is not a rename the automatic seam
/// follows, so it parses to `None` rather than one of these variants.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RenameKind {
    /// A single leaf field renamed in place. Issue #24 resolves this kind
    /// into a real `same`/`rename` verdict, including a comma-separated
    /// successive history.
    Leaf,
    /// An array-of-structures renamed, cascading to its descendants.
    /// Resolution is issue #25's; #24 leaves this kind in
    /// [`Classification::RenamePending`].
    Aos,
    /// A plain structure renamed, cascading to its descendants. Resolution
    /// is issue #25's; #24 leaves this kind in
    /// [`Classification::RenamePending`].
    Structure,
}

fn parse_rename_kind(change_nbc_description: Option<&str>) -> Option<RenameKind> {
    match change_nbc_description {
        Some("leaf_renamed") => Some(RenameKind::Leaf),
        Some("aos_renamed") => Some(RenameKind::Aos),
        Some("structure_renamed") => Some(RenameKind::Structure),
        _ => None,
    }
}

/// Why [`FieldMeta::rename_history`] refused to parse a
/// `change_nbc_version`/`change_nbc_previous_name` pair into a usable
/// history (issue #24). The engine refuses to guess a resolution from
/// ambiguous or malformed metadata rather than fabricate a mapping.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RenameHistoryError {
    /// The comma-separated `change_nbc_version` and `change_nbc_previous_name`
    /// lists do not have the same number of non-empty entries (issue #13's
    /// aligned-history portability rule).
    ShapeMismatch,
    /// One of the comma-separated `change_nbc_version` entries does not
    /// parse as a `major.minor.patch` [`DdVersion`].
    UnparseableVersion,
    /// The `change_nbc_version` entries are not in strictly ascending
    /// semantic order (issue #13's ordering-validation portability rule).
    NotStrictlyAscending,
    /// More than one `leaf_renamed` field resolves to the same predecessor
    /// path at the requested endpoint, so choosing either would fabricate a
    /// mapping.
    AmbiguousPredecessor,
}

/// Metadata captured from one `<field>` element's attributes, keyed by its
/// `path` attribute in [`FieldIndex`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FieldMeta {
    data_type: String,
    rename_kind: Option<RenameKind>,
    previous_name: Option<String>,
    nbc_version: Option<String>,
}

impl FieldMeta {
    pub fn data_type(&self) -> &str {
        &self.data_type
    }

    /// `true` when [`FieldMeta::rename_kind`] is `Some`.
    pub fn carries_rename_metadata(&self) -> bool {
        self.rename_kind.is_some()
    }

    /// The automatic rename kind this field's `change_nbc_description`
    /// names, if any (issue #18's "Rename-map construction" decision).
    pub fn rename_kind(&self) -> Option<RenameKind> {
        self.rename_kind
    }

    /// Raw, uninterpreted `change_nbc_previous_name` (comma-separated for
    /// a successive-rename history). `None` when the attribute is absent.
    pub fn previous_name(&self) -> Option<&str> {
        self.previous_name.as_deref()
    }

    /// Raw, uninterpreted `change_nbc_version` (comma-separated, aligned
    /// with [`FieldMeta::previous_name`]). `None` when the attribute is
    /// absent.
    pub fn nbc_version(&self) -> Option<&str> {
        self.nbc_version.as_deref()
    }

    /// Parses this field's `change_nbc_version`/`change_nbc_previous_name`
    /// into an aligned, strictly-ascending list of `(version, previous_name)`
    /// history entries (issue #24; issue #13's comma-separated-history
    /// portability rule). Meaningful only when [`FieldMeta::rename_kind`] is
    /// [`RenameKind::Leaf`] -- callers are expected to check that first.
    fn rename_history(&self) -> Result<Vec<(DdVersion, &str)>, RenameHistoryError> {
        let versions_raw = self.nbc_version.as_deref().unwrap_or("");
        let names_raw = self.previous_name.as_deref().unwrap_or("");
        let versions: Vec<&str> = versions_raw.split(',').map(str::trim).collect();
        let names: Vec<&str> = names_raw.split(',').map(str::trim).collect();
        if versions.len() != names.len()
            || versions.iter().any(|v| v.is_empty())
            || names.iter().any(|n| n.is_empty())
        {
            return Err(RenameHistoryError::ShapeMismatch);
        }

        let mut history = Vec::with_capacity(versions.len());
        for (version_text, name) in versions.iter().zip(names.iter()) {
            let version = DdVersion::parse(version_text)
                .map_err(|_| RenameHistoryError::UnparseableVersion)?;
            history.push((version, *name));
        }
        for window in history.windows(2) {
            if window[0].0 >= window[1].0 {
                return Err(RenameHistoryError::NotStrictlyAscending);
            }
        }
        Ok(history)
    }
}

/// Resolves the predecessor name of `new_path`'s leaf rename `history`
/// valid at `older_endpoint` (issue #24; issue #13's cutoff-selection
/// portability rule): scans `history` (already validated ascending) for
/// the first entry whose version is strictly greater than `older_endpoint`,
/// and expands that entry's previous name into a full path -- a full
/// previous name (containing `/`) is used verbatim, a bare (slash-free)
/// one is read as a sibling of `new_path`'s own parent. History predating
/// `older_endpoint` is ignored by construction: only the first qualifying
/// entry is ever consulted.
///
/// Returns `None` when every history entry's version is at or before
/// `older_endpoint`: every recorded rename already happened by that
/// version, so `new_path` itself, not a predecessor, is the name valid
/// there.
fn leaf_old_path_at(
    new_path: &str,
    history: &[(DdVersion, &str)],
    older_endpoint: DdVersion,
) -> Option<String> {
    let (_, previous_name) = history
        .iter()
        .find(|(version, _)| *version > older_endpoint)?;
    if previous_name.contains('/') {
        Some(previous_name.to_string())
    } else {
        match new_path.rsplit_once('/') {
            Some((parent, _)) => Some(format!("{parent}/{previous_name}")),
            None => Some(previous_name.to_string()),
        }
    }
}

/// A schema's fields indexed by their `field/@path` attribute (issue #23).
/// Built once per [`crate::schema::ParsedSchema`] and retained for the
/// life of the cached pair, so classification never re-parses the XML.
///
/// Alongside the by-path map, this also collects `aos_renamed`/
/// `structure_renamed` predecessor references in
/// [`FieldIndex::may_have_renamed_from`] (deferred to issue #25) and the
/// paths of every `leaf_renamed` field in [`FieldIndex::resolve_leaf_predecessor`]
/// (issue #24) -- see each method's doc comment for why `classify` needs
/// them.
#[derive(Debug, Default)]
pub struct FieldIndex {
    by_path: HashMap<String, FieldMeta>,
    rename_references: Vec<RenameReference>,
    leaf_tagged: Vec<String>,
}

/// One `aos_renamed`/`structure_renamed` predecessor reference. This is
/// only enough to withhold a fabricated add/remove verdict pending issue
/// #25; unlike `leaf_renamed`, resolving it into a replacement path is not
/// this crate's job yet.
#[derive(Debug)]
struct RenameReference {
    renamed_path: String,
    previous_name: String,
}

impl RenameReference {
    fn may_refer_to(&self, path: &str) -> bool {
        if path == self.previous_name {
            return true;
        }

        // Both remaining kinds (aos_renamed, structure_renamed) cascade to
        // descendants -- leaf_renamed never reaches this struct at all
        // (see FieldIndex::from_document), so no per-reference cascade
        // flag is needed here.
        if path
            .strip_prefix(&self.previous_name)
            .is_some_and(|suffix| suffix.starts_with('/'))
        {
            return true;
        }

        // A bare predecessor name is relative to the renamed field's
        // parent. Matching that parent prevents an unrelated same-named
        // leaf elsewhere in the schema from being withheld.
        !self.previous_name.contains('/')
            && path.rsplit_once('/').is_some_and(|(parent, leaf)| {
                leaf == self.previous_name
                    && self
                        .renamed_path
                        .rsplit_once('/')
                        .is_some_and(|(renamed_parent, _)| parent == renamed_parent)
            })
    }
}

impl FieldIndex {
    /// Walks every `<field>` element in `doc`, regardless of its nesting
    /// depth, and indexes it by its own `path` attribute. Real DD XML
    /// nests `<field>` elements to mirror the IDS tree but also carries a
    /// redundant flattened `path` attribute on each one (e.g.
    /// `path="ids_properties/comment"`); this index is keyed purely by
    /// that attribute, so it is nesting-agnostic and a flat fixture is
    /// representationally equivalent to a nested one for this engine's
    /// purposes. A `<field>` with no `path` attribute is skipped: it
    /// cannot be looked up by this index's key and is not itself a
    /// projectable node.
    pub(crate) fn from_document(doc: &roxmltree::Document) -> Self {
        let mut by_path = HashMap::new();
        let mut rename_references = Vec::new();
        let mut leaf_tagged = Vec::new();
        for node in doc.descendants() {
            if !node.is_element() || node.tag_name().name() != "field" {
                continue;
            }
            let Some(path) = node.attribute("path") else {
                continue;
            };
            let change_nbc_description = node.attribute("change_nbc_description");
            let rename_kind = parse_rename_kind(change_nbc_description);
            let previous_name = node.attribute("change_nbc_previous_name");
            match rename_kind {
                Some(RenameKind::Leaf) => leaf_tagged.push(path.to_string()),
                Some(RenameKind::Aos | RenameKind::Structure) => {
                    if let Some(previous_name) = previous_name {
                        rename_references.extend(previous_name.split(',').map(|previous_name| {
                            RenameReference {
                                renamed_path: path.to_string(),
                                previous_name: previous_name.trim().to_string(),
                            }
                        }));
                    }
                }
                None => {}
            }
            by_path.insert(
                path.to_string(),
                FieldMeta {
                    data_type: node.attribute("data_type").unwrap_or("").to_string(),
                    rename_kind,
                    previous_name: previous_name.map(String::from),
                    nbc_version: node.attribute("change_nbc_version").map(String::from),
                },
            );
        }
        FieldIndex {
            by_path,
            rename_references,
            leaf_tagged,
        }
    }

    pub fn get(&self, path: &str) -> Option<&FieldMeta> {
        self.by_path.get(path)
    }

    /// `true` when `aos_renamed`/`structure_renamed` metadata may refer to
    /// `path` (issue #23), so `classify` must withhold an added/removed
    /// verdict pending issue #25's resolution. `leaf_renamed` metadata is
    /// excluded from this check by construction (see
    /// [`FieldIndex::from_document`]): issue #24 resolves it authoritatively
    /// through [`FieldIndex::resolve_leaf_predecessor`] instead, so this
    /// heuristic no longer needs to (and must not) also match it -- doing
    /// so would re-introduce the stale-history ambiguity issue #24 exists
    /// to resolve.
    ///
    /// This exists so [`classify`] does not fabricate `SourceOnly` for a
    /// node that a real compiled walk would never see as "added" or
    /// "removed" in the first place: DD rename metadata is recorded only
    /// on the post-rename field, pointing backward, so the OLD field at
    /// its OLD path carries no tag of its own -- querying it as source
    /// against the NEW schema as target would otherwise see a plain
    /// absence and misclassify it. Besides exact matches, this recognizes a
    /// bare predecessor name within the renamed field's unchanged parent and
    /// descendants of a renamed structure or AoS.
    pub fn may_have_renamed_from(&self, path: &str) -> bool {
        self.rename_references
            .iter()
            .any(|reference| reference.may_refer_to(path))
    }

    /// Attempts to resolve `queried_path` as the `leaf_renamed` predecessor
    /// name of some field in this index at `older_endpoint`'s DD version
    /// (issue #24). Returns `Ok(Some((new_path, meta)))` when exactly one
    /// field's history resolves, at `older_endpoint`, to `queried_path`;
    /// `Ok(None)` when no field's history matches.
    ///
    /// Scans every `leaf_renamed` field in this index (not just one
    /// candidate), because `queried_path` alone does not identify which
    /// tagged field it might be the predecessor of. A malformed history on
    /// ANY scanned field fails the whole call deterministically rather than
    /// being silently skipped: skipping past it could silently miss the one
    /// match `queried_path` was actually looking for, which is exactly the
    /// fabricated-mapping risk issue #24 exists to avoid. This only affects
    /// the non-production `PE_DIRECTION_STORED_TO_WORKING` testing
    /// direction (see [`classify`]); the forward direction resolves a
    /// single field's own history and so never has this breadth.
    fn resolve_leaf_predecessor(
        &self,
        queried_path: &str,
        older_endpoint: DdVersion,
    ) -> Result<Option<(&str, &FieldMeta)>, RenameHistoryError> {
        let mut resolved = None;
        for new_path in &self.leaf_tagged {
            let meta = self
                .by_path
                .get(new_path)
                .expect("every leaf_tagged path was inserted into by_path in the same pass");
            let history = meta.rename_history()?;
            if let Some(old_path) = leaf_old_path_at(new_path, &history, older_endpoint) {
                if old_path == queried_path {
                    if resolved.is_some() {
                        return Err(RenameHistoryError::AmbiguousPredecessor);
                    }
                    resolved = Some((new_path.as_str(), meta));
                }
            }
        }
        Ok(resolved)
    }
}

/// The classification of one node relative to a source/target schema pair
/// (issues #23, #24).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Classification {
    /// Present in both schemas under the identical path, with matching
    /// `data_type`, and neither side carries automatic rename metadata
    /// that applies to this path.
    Same,
    /// Present in the source schema, absent from the target schema under
    /// the identical path (after any rename resolution), and no rename
    /// metadata resolves to `path` either. Depending on which schema plays
    /// source for a given query, this is either a compiled-only field
    /// (source is the working/compiled schema) or a stored-only field
    /// (source is the stored schema); the caller's own query direction
    /// disambiguates which, since both map to the same `PE_VERDICT_SKIP`
    /// outcome.
    SourceOnly,
    /// Present in both schemas (directly, or via rename resolution), but
    /// with different `data_type`. Every datatype change is an
    /// automatic-seam skip (see #18): this holds even when equivalent
    /// IMAS-Python metadata carries an explicit-conversion callback,
    /// because this classifier has no concept of a callback to consult in
    /// the first place -- including when the datatype change coincides
    /// with a resolved rename.
    DatatypeChanged,
    /// The source's own field, or the identically-pathed field on the
    /// target side, carries `aos_renamed` or `structure_renamed` metadata
    /// (`change_nbc_description`). Resolving that metadata into a real
    /// `same`/`rename` verdict is issue #25 (array-of-structures and plain-
    /// structure renames, including cascade and missing-subtree
    /// collapsing); until then, this explicit state exists precisely so
    /// such a node is never silently folded into
    /// [`Classification::SourceOnly`] (added/removed) -- a naive by-path
    /// set difference would otherwise treat a renamed node as one field
    /// disappearing and an unrelated field appearing, discarding the very
    /// information #25 needs to resolve it correctly. `leaf_renamed`
    /// metadata no longer reaches this state (issue #24 resolves it into
    /// [`Classification::Renamed`], [`Classification::Same`], or
    /// [`Classification::DatatypeChanged`] instead).
    RenamePending,
    /// A `leaf_renamed` field resolved for this schema pair's older
    /// endpoint (issue #24). Carries the projected path on the *other*
    /// schema: the resolved predecessor path when the source carried the
    /// rename tag, or the tagged field's own current path when the bare
    /// predecessor name was queried.
    Renamed(String),
}

fn classify_matched_rename(
    projected_path: String,
    other_data_type: &str,
    this_data_type: &str,
) -> Classification {
    if other_data_type == this_data_type {
        Classification::Renamed(projected_path)
    } else {
        Classification::DatatypeChanged
    }
}

/// The two identically-pathed fields' `data_type`s decide `Same` vs.
/// `DatatypeChanged` (issue #18: every datatype change is an automatic-seam
/// skip). Shared by every `classify` arm that reaches an identical-path
/// comparison without a rename to resolve.
fn same_or_datatype_changed(other_data_type: &str, this_data_type: &str) -> Classification {
    if other_data_type == this_data_type {
        Classification::Same
    } else {
        Classification::DatatypeChanged
    }
}

/// Classifies `path`, read from `source`, against `target`, for a schema
/// pair whose semantically older endpoint is `older_endpoint` (issues #23,
/// #24).
///
/// Returns `Ok(None)` when `path` is not a field known to `source` at all --
/// the caller (`ffi::pe_project_node_query`) treats that as an invalid
/// argument rather than a classification, since a real compiled walk only
/// ever queries paths it already knows belong to its own schema. Returns
/// `Err` when resolving a `leaf_renamed` field's history fails (see
/// [`RenameHistoryError`]); the engine refuses to guess in that case rather
/// than fabricate a mapping.
///
/// `aos_renamed`/`structure_renamed` metadata is checked before presence/
/// absence or datatype comparison, on both the source's and the target's
/// identically-pathed field: either side carrying it is enough to withhold
/// a same/added/removed/datatype-changed verdict pending issue #25 (see
/// [`Classification::RenamePending`]). `leaf_renamed` metadata on the
/// source's own field is resolved immediately via its history and
/// `older_endpoint`; `leaf_renamed` metadata elsewhere in `target` is
/// consulted, via [`FieldIndex::resolve_leaf_predecessor`], only when
/// `path` is otherwise absent from `target` -- otherwise querying a
/// renamed field by its OLD path (the non-production
/// `PE_DIRECTION_STORED_TO_WORKING` testing direction) would fabricate an
/// added/removed verdict purely because DD rename metadata is recorded
/// only on the post-rename field, pointing backward, so the old field's
/// own entry carries no tag to catch above.
pub fn classify(
    source: &FieldIndex,
    target: &FieldIndex,
    path: &str,
    older_endpoint: DdVersion,
) -> Result<Option<Classification>, RenameHistoryError> {
    let Some(source_meta) = source.get(path) else {
        return Ok(None);
    };

    if let Some(kind) = source_meta.rename_kind() {
        if kind != RenameKind::Leaf {
            return Ok(Some(Classification::RenamePending));
        }
        let history = source_meta.rename_history()?;
        return Ok(Some(
            match leaf_old_path_at(path, &history, older_endpoint) {
                Some(old_path) => match target.get(&old_path) {
                    Some(target_meta) => classify_matched_rename(
                        old_path,
                        target_meta.data_type(),
                        source_meta.data_type(),
                    ),
                    None => Classification::SourceOnly,
                },
                // Every recorded rename predates older_endpoint: at that
                // version the field already carried its current name, so
                // `path` itself -- not a predecessor -- is the answer.
                None => match target.get(path) {
                    Some(target_meta) => {
                        same_or_datatype_changed(target_meta.data_type(), source_meta.data_type())
                    }
                    None => Classification::SourceOnly,
                },
            },
        ));
    }

    match target.get(path) {
        None => {
            if let Some((new_path, target_meta)) =
                target.resolve_leaf_predecessor(path, older_endpoint)?
            {
                return Ok(Some(classify_matched_rename(
                    new_path.to_string(),
                    target_meta.data_type(),
                    source_meta.data_type(),
                )));
            }
            if target.may_have_renamed_from(path) {
                Ok(Some(Classification::RenamePending))
            } else {
                Ok(Some(Classification::SourceOnly))
            }
        }
        Some(target_meta) => match target_meta.rename_kind() {
            // An identical-path match answers the query correctly for both
            // schemas' own current versions regardless of any leaf_renamed
            // history target_meta might separately carry (that history is
            // only relevant when resolving a *different*, older path -- see
            // FieldIndex::resolve_leaf_predecessor above). aos_renamed/
            // structure_renamed are different: issue #25's cascade/
            // collapsing is not yet safe to bypass, so those still withhold.
            Some(kind) if kind != RenameKind::Leaf => Ok(Some(Classification::RenamePending)),
            _ => Ok(Some(same_or_datatype_changed(
                target_meta.data_type(),
                source_meta.data_type(),
            ))),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn index(xml: &str) -> FieldIndex {
        let doc = roxmltree::Document::parse(xml).unwrap();
        FieldIndex::from_document(&doc)
    }

    fn v(raw: &str) -> DdVersion {
        DdVersion::parse(raw).unwrap()
    }

    #[test]
    fn indexes_fields_regardless_of_nesting_depth() {
        let flat = index(r#"<IDSs><field name="a" path="group/leaf" data_type="INT_0D"/></IDSs>"#);
        let nested = index(
            r#"<IDSs><field name="group" path="group" data_type="structure">
                 <field name="leaf" path="group/leaf" data_type="INT_0D"/>
               </field></IDSs>"#,
        );
        assert_eq!(
            flat.get("group/leaf").unwrap().data_type(),
            nested.get("group/leaf").unwrap().data_type()
        );
    }

    #[test]
    fn a_field_with_no_path_attribute_is_not_indexed() {
        let idx = index(r#"<IDSs><field name="orphan" data_type="INT_0D"/></IDSs>"#);
        assert!(idx.get("orphan").is_none());
    }

    #[test]
    fn reads_rename_metadata_attributes_verbatim() {
        let idx = index(
            r#"<IDSs><field name="n" path="renamed" data_type="STR_0D"
                 change_nbc_version="3.1.0,3.2.0"
                 change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient,middle"/></IDSs>"#,
        );
        let meta = idx.get("renamed").unwrap();
        assert!(meta.carries_rename_metadata());
        assert_eq!(meta.rename_kind(), Some(RenameKind::Leaf));
        assert_eq!(meta.previous_name(), Some("ancient,middle"));
        assert_eq!(meta.nbc_version(), Some("3.1.0,3.2.0"));
    }

    #[test]
    fn a_change_nbc_description_outside_the_automatic_set_does_not_carry_rename_metadata() {
        let idx = index(
            r#"<IDSs><field name="n" path="retyped" data_type="FLT_0D"
                 change_nbc_version="3.1.0" change_nbc_description="type_changed"/></IDSs>"#,
        );
        assert!(!idx.get("retyped").unwrap().carries_rename_metadata());
    }

    #[test]
    fn unknown_source_path_classifies_to_none() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "does/not/exist", v("1.0.0")),
            Ok(None)
        );
    }

    #[test]
    fn identical_path_and_data_type_on_both_sides_is_same() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "a", v("1.0.0")),
            Ok(Some(Classification::Same))
        );
    }

    #[test]
    fn present_in_source_only_is_source_only() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "a", v("1.0.0")),
            Ok(Some(Classification::SourceOnly))
        );
    }

    #[test]
    fn matching_path_with_different_data_type_is_datatype_changed() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs><field name="a" path="a" data_type="FLT_0D"/></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "a", v("1.0.0")),
            Ok(Some(Classification::DatatypeChanged))
        );
    }

    #[test]
    fn descendants_of_a_renamed_structure_or_aos_are_held_pending() {
        let source = index(
            r#"<IDSs>
                 <field name="n" path="old_struct/child" data_type="INT_0D"/>
                 <field name="n" path="old_aos/value" data_type="FLT_1D"/>
               </IDSs>"#,
        );
        let target = index(
            r#"<IDSs>
                 <field name="n" path="new_struct" data_type="structure"
                    change_nbc_description="structure_renamed"
                    change_nbc_previous_name="old_struct"/>
                 <field name="n" path="new_aos" data_type="struct_array"
                    change_nbc_description="aos_renamed"
                    change_nbc_previous_name="old_aos"/>
               </IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "old_struct/child", v("1.0.0")),
            Ok(Some(Classification::RenamePending))
        );
        assert_eq!(
            classify(&source, &target, "old_aos/value", v("1.0.0")),
            Ok(Some(Classification::RenamePending))
        );
    }

    #[test]
    fn structural_and_array_rename_metadata_stays_pending_independent_of_leaf_rename_resolution() {
        let source = index(
            r#"<IDSs><field name="n" path="new_aos" data_type="struct_array"
                 change_nbc_version="4.0.0" change_nbc_description="aos_renamed"
                 change_nbc_previous_name="old_aos"/></IDSs>"#,
        );
        let target = index(r#"<IDSs></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "new_aos", v("1.0.0")),
            Ok(Some(Classification::RenamePending))
        );
    }

    #[test]
    fn target_side_structure_rename_metadata_still_withholds_a_fabricated_verdict() {
        // Mirrors the leaf case's own identity-match test below, but for
        // structure_renamed: issue #25 has not yet defined the cascade/
        // collapsing semantics that make bypassing this safe.
        let source = index(r#"<IDSs><field name="n" path="shared" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="shared" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="structure_renamed"
                 change_nbc_previous_name="elsewhere"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "shared", v("1.0.0")),
            Ok(Some(Classification::RenamePending))
        );
    }

    #[test]
    fn a_stored_only_path_is_retained_in_the_index_even_though_no_query_ever_visits_it() {
        // The compiled walk never visits a stored-only path, so `classify`
        // alone would never surface it; retention lives in `by_path` itself
        // (built unconditionally over every `<field>`, not just queried
        // ones), which is what keeps this schema fact available for issue
        // #27's loss enumeration to consume later.
        let stored = index(
            r#"<IDSs>
                 <field name="a" path="shared" data_type="INT_0D"/>
                 <field name="b" path="stored_only" data_type="INT_0D"/>
               </IDSs>"#,
        );
        assert!(stored.get("stored_only").is_some());
    }

    /// Parity vector (issue #13/#18's cutoff-selection portability rule):
    /// a single `leaf_renamed` field resolves to its previous name when
    /// queried from the tagged (post-rename) side, and reciprocally when
    /// queried from the bare predecessor path.
    #[test]
    fn leaf_rename_resolves_reciprocally_in_both_directions() {
        let old = index(r#"<IDSs><field name="n" path="old_name" data_type="STR_0D"/></IDSs>"#);
        let new = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_name"/></IDSs>"#,
        );

        assert_eq!(
            classify(&new, &old, "new_name", v("3.0.0")),
            Ok(Some(Classification::Renamed("old_name".to_string())))
        );
        assert_eq!(
            classify(&old, &new, "old_name", v("3.0.0")),
            Ok(Some(Classification::Renamed("new_name".to_string())))
        );
    }

    #[test]
    fn a_bare_previous_name_within_the_same_parent_resolves_to_its_sibling() {
        let source =
            index(r#"<IDSs><field name="n" path="group/old_leaf" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="group/renamed_leaf" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_leaf"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "group/old_leaf", v("3.0.0")),
            Ok(Some(Classification::Renamed(
                "group/renamed_leaf".to_string()
            )))
        );

        // An unrelated field with the same bare leaf name under a
        // different parent must not be caught by the sibling heuristic.
        let unrelated_source =
            index(r#"<IDSs><field name="n" path="other/old_leaf" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&unrelated_source, &target, "other/old_leaf", v("3.0.0")),
            Ok(Some(Classification::SourceOnly))
        );
    }

    #[test]
    fn leaf_rename_at_an_identical_shared_path_is_not_withheld() {
        // Refines #23's original blanket withholding: unlike
        // aos_renamed/structure_renamed (see
        // target_side_structure_rename_metadata_still_withholds_a_fabricated_verdict),
        // a leaf_renamed tag never cascades, so an exact-path match still
        // correctly answers the query for both schemas' own current
        // versions regardless of any *other* historical alias the target
        // field separately carries.
        let source = index(r#"<IDSs><field name="n" path="shared" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="shared" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="elsewhere"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "shared", v("1.0.0")),
            Ok(Some(Classification::Same))
        );
    }

    /// Parity vector (issue #13/#18's cutoff-selection portability rule):
    /// a successive rename history selects the previous name associated
    /// with the first rename version greater than the older endpoint,
    /// ignoring history predating the gap.
    #[test]
    fn successive_history_selects_the_entry_just_after_the_older_endpoint() {
        let new = index(
            r#"<IDSs><field name="n" path="thrice_renamed" data_type="STR_0D"
                 change_nbc_version="1.0.0,2.0.0,3.0.0"
                 change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient_name,middle_name,recent_name"/></IDSs>"#,
        );
        let old_at_ancient =
            index(r#"<IDSs><field name="n" path="ancient_name" data_type="STR_0D"/></IDSs>"#);
        let old_at_middle =
            index(r#"<IDSs><field name="n" path="middle_name" data_type="STR_0D"/></IDSs>"#);
        let old_at_recent =
            index(r#"<IDSs><field name="n" path="recent_name" data_type="STR_0D"/></IDSs>"#);

        // Older endpoint before every recorded rename: the earliest entry
        // applies.
        assert_eq!(
            classify(&new, &old_at_ancient, "thrice_renamed", v("0.5.0")),
            Ok(Some(Classification::Renamed("ancient_name".to_string())))
        );
        // Older endpoint between the first and second entries: the first
        // entry (1.0.0) predates this gap and must be ignored in favour of
        // the second (2.0.0).
        assert_eq!(
            classify(&new, &old_at_middle, "thrice_renamed", v("1.5.0")),
            Ok(Some(Classification::Renamed("middle_name".to_string())))
        );
        // Older endpoint between the second and third entries.
        assert_eq!(
            classify(&new, &old_at_recent, "thrice_renamed", v("2.5.0")),
            Ok(Some(Classification::Renamed("recent_name".to_string())))
        );
        // Older endpoint at or after every recorded rename: the field's
        // own current name is already valid there.
        let new_only = index(
            r#"<IDSs><field name="n" path="thrice_renamed" data_type="STR_0D"
                 change_nbc_version="1.0.0,2.0.0,3.0.0"
                 change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient_name,middle_name,recent_name"/></IDSs>"#,
        );
        assert_eq!(
            classify(&new, &new_only, "thrice_renamed", v("3.5.0")),
            Ok(Some(Classification::Same))
        );

        // Reciprocal, bare-predecessor-name direction: querying the stale
        // "ancient_name" from a gap whose older endpoint is already past
        // it must not resolve -- that history predates the gap and is
        // ignored, so the true resolved name ("middle_name") does not
        // match this stale query.
        assert_eq!(
            classify(&old_at_ancient, &new, "ancient_name", v("1.5.0")),
            Ok(Some(Classification::SourceOnly))
        );
    }

    #[test]
    fn successive_history_resolution_is_independent_of_caller_endpoint_ordering() {
        let new = index(
            r#"<IDSs><field name="n" path="thrice_renamed" data_type="STR_0D"
                 change_nbc_version="1.0.0,2.0.0"
                 change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient_name,middle_name"/></IDSs>"#,
        );
        let old = index(r#"<IDSs><field name="n" path="middle_name" data_type="STR_0D"/></IDSs>"#);
        let older_endpoint = v("1.5.0");

        assert_eq!(
            classify(&new, &old, "thrice_renamed", older_endpoint),
            Ok(Some(Classification::Renamed("middle_name".to_string())))
        );
        assert_eq!(
            classify(&old, &new, "middle_name", older_endpoint),
            Ok(Some(Classification::Renamed("thrice_renamed".to_string())))
        );
    }

    /// Parity vector (issue #18's "every datatype change is an
    /// automatic-seam skip" rule): a resolved rename whose two sides differ
    /// in `data_type` reports the skip, not a fabricated rename, exactly as
    /// #23 already established for a non-renamed datatype change -- proving
    /// no semantic type-conversion callback executes even though the field
    /// also happens to have been renamed.
    #[test]
    fn datatype_change_wins_over_a_resolved_rename() {
        let old = index(r#"<IDSs><field name="n" path="old_name" data_type="INT_0D"/></IDSs>"#);
        let new = index(
            r#"<IDSs><field name="n" path="new_name" data_type="FLT_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_name"/></IDSs>"#,
        );
        assert_eq!(
            classify(&new, &old, "new_name", v("3.0.0")),
            Ok(Some(Classification::DatatypeChanged))
        );
        assert_eq!(
            classify(&old, &new, "old_name", v("3.0.0")),
            Ok(Some(Classification::DatatypeChanged))
        );
    }

    /// Parity vector (issue #13/#18's aligned-history portability rule):
    /// mismatched comma counts between `change_nbc_version` and
    /// `change_nbc_previous_name` fail deterministically instead of
    /// producing a fabricated mapping.
    #[test]
    fn shape_mismatch_between_version_and_name_history_is_rejected() {
        let new = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="1.0.0,2.0.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="only_one"/></IDSs>"#,
        );
        let old = index(r#"<IDSs><field name="n" path="only_one" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&new, &old, "new_name", v("1.0.0")),
            Err(RenameHistoryError::ShapeMismatch)
        );
    }

    #[test]
    fn an_unparseable_history_version_is_rejected() {
        let new = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="not-a-version" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_name"/></IDSs>"#,
        );
        let old = index(r#"<IDSs><field name="n" path="old_name" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&new, &old, "new_name", v("1.0.0")),
            Err(RenameHistoryError::UnparseableVersion)
        );
    }

    /// Parity vector (issue #13/#18's ordering-validation portability
    /// rule): out-of-order `change_nbc_version` entries fail deterministically
    /// instead of the engine guessing which entry the cutoff should prefer.
    #[test]
    fn non_ascending_history_versions_are_rejected() {
        let new = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="2.0.0,1.0.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient_name,middle_name"/></IDSs>"#,
        );
        let old = index(r#"<IDSs><field name="n" path="middle_name" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&new, &old, "new_name", v("1.5.0")),
            Err(RenameHistoryError::NotStrictlyAscending)
        );
    }

    #[test]
    fn a_malformed_history_elsewhere_fails_the_reverse_lookup_deterministically() {
        // The malformed field ("broken") is unrelated to the queried bare
        // path ("clean_old"), but resolve_leaf_predecessor must scan every
        // leaf_renamed field to answer a bare-path query, so it cannot
        // silently skip past a malformed one without risking exactly the
        // fabricated-mapping outcome issue #24 forbids.
        let old = index(r#"<IDSs><field name="n" path="clean_old" data_type="STR_0D"/></IDSs>"#);
        let new = index(
            r#"<IDSs>
                 <field name="n" path="broken" data_type="STR_0D"
                    change_nbc_version="1.0.0,2.0.0" change_nbc_description="leaf_renamed"
                    change_nbc_previous_name="only_one"/>
                 <field name="n" path="clean_new" data_type="STR_0D"
                    change_nbc_version="1.0.0" change_nbc_description="leaf_renamed"
                    change_nbc_previous_name="clean_old"/>
               </IDSs>"#,
        );
        assert_eq!(
            classify(&old, &new, "clean_old", v("0.5.0")),
            Err(RenameHistoryError::ShapeMismatch)
        );
    }

    #[test]
    fn duplicate_leaf_predecessors_are_rejected_deterministically() {
        let old = index(r#"<IDSs><field name="n" path="shared_old" data_type="STR_0D"/></IDSs>"#);
        let new = index(
            r#"<IDSs>
                 <field name="n" path="first_new" data_type="STR_0D"
                    change_nbc_version="1.0.0" change_nbc_description="leaf_renamed"
                    change_nbc_previous_name="shared_old"/>
                 <field name="n" path="second_new" data_type="STR_0D"
                    change_nbc_version="1.0.0" change_nbc_description="leaf_renamed"
                    change_nbc_previous_name="shared_old"/>
               </IDSs>"#,
        );
        assert_eq!(
            classify(&old, &new, "shared_old", v("0.5.0")),
            Err(RenameHistoryError::AmbiguousPredecessor)
        );
    }
}
