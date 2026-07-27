//! `field/@path` indexing and the rename-metadata-free projection
//! classification (issue #23).
//!
//! This slice classifies a node relative to a source/target schema pair
//! into exactly the categories that need no rename history: [`Same`],
//! [`SourceOnly`] (a compiled-only or stored-only field, depending on
//! which schema plays source for a given query), and [`DatatypeChanged`].
//! A node whose own `<field>` element carries automatic rename metadata
//! (`change_nbc_description` of `leaf_renamed`, `aos_renamed`, or
//! `structure_renamed`) is deliberately held in the distinct
//! [`RenamePending`] state instead of being folded into `SourceOnly` --
//! see that variant's doc comment for why this matters.
//!
//! [`Same`]: Classification::Same
//! [`SourceOnly`]: Classification::SourceOnly
//! [`DatatypeChanged`]: Classification::DatatypeChanged
//! [`RenamePending`]: Classification::RenamePending

use std::collections::HashMap;

/// Metadata captured from one `<field>` element's attributes, keyed by its
/// `path` attribute in [`FieldIndex`]. `previous_name`/`nbc_version` are
/// retained verbatim, uninterpreted -- this slice never parses their
/// comma-separated history shape or resolves a cutoff; that is issue
/// #24/#25's job. Keeping the raw strings here now means #24/#25 read
/// them from the already-built index instead of re-parsing the XML.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FieldMeta {
    data_type: String,
    carries_rename_metadata: bool,
    previous_name: Option<String>,
    nbc_version: Option<String>,
}

impl FieldMeta {
    pub fn data_type(&self) -> &str {
        &self.data_type
    }

    /// `true` when `change_nbc_description` names one of the three
    /// automatic, metadata-driven rename kinds (`leaf_renamed`,
    /// `aos_renamed`, `structure_renamed`) -- see #18's "Rename-map
    /// construction" decision. Any other `change_nbc_description` value
    /// (e.g. `type_changed`, `ids_renamed`) is not a rename the automatic
    /// seam follows, so it does not set this flag.
    pub fn carries_rename_metadata(&self) -> bool {
        self.carries_rename_metadata
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
}

const AUTOMATIC_RENAME_DESCRIPTIONS: &[&str] =
    &["leaf_renamed", "aos_renamed", "structure_renamed"];

/// A schema's fields indexed by their `field/@path` attribute (issue #23).
/// Built once per [`crate::schema::ParsedSchema`] and retained for the
/// life of the cached pair, so classification never re-parses the XML.
///
/// Alongside the by-path map, this also collects automatic-rename
/// predecessor references in [`FieldIndex::may_have_renamed_from`] -- see
/// that method's doc comment for why `classify` needs it.
#[derive(Debug, Default)]
pub struct FieldIndex {
    by_path: HashMap<String, FieldMeta>,
    rename_references: Vec<RenameReference>,
}

/// One predecessor reference attached to an automatic rename. This is only
/// enough to withhold a fabricated add/remove verdict; #24/#25 still own
/// resolving the reference into its replacement path.
#[derive(Debug)]
struct RenameReference {
    renamed_path: String,
    previous_name: String,
    cascades_to_descendants: bool,
}

impl RenameReference {
    fn may_refer_to(&self, path: &str) -> bool {
        if path == self.previous_name {
            return true;
        }

        if self.cascades_to_descendants
            && path
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
        for node in doc.descendants() {
            if !node.is_element() || node.tag_name().name() != "field" {
                continue;
            }
            let Some(path) = node.attribute("path") else {
                continue;
            };
            let change_nbc_description = node.attribute("change_nbc_description");
            let carries_rename_metadata =
                change_nbc_description.is_some_and(|d| AUTOMATIC_RENAME_DESCRIPTIONS.contains(&d));
            let previous_name = node.attribute("change_nbc_previous_name");
            if carries_rename_metadata {
                if let Some(previous_name) = previous_name {
                    rename_references.extend(previous_name.split(',').map(|previous_name| {
                        RenameReference {
                            renamed_path: path.to_string(),
                            previous_name: previous_name.trim().to_string(),
                            cascades_to_descendants: matches!(
                                change_nbc_description,
                                Some("aos_renamed" | "structure_renamed")
                            ),
                        }
                    }));
                }
            }
            by_path.insert(
                path.to_string(),
                FieldMeta {
                    data_type: node.attribute("data_type").unwrap_or("").to_string(),
                    carries_rename_metadata,
                    previous_name: previous_name.map(String::from),
                    nbc_version: node.attribute("change_nbc_version").map(String::from),
                },
            );
        }
        FieldIndex {
            by_path,
            rename_references,
        }
    }

    pub fn get(&self, path: &str) -> Option<&FieldMeta> {
        self.by_path.get(path)
    }

    /// `true` when automatic rename metadata may refer to `path` (issue
    /// #23), so `classify` must withhold an added/removed verdict.
    ///
    /// This exists so [`classify`] does not fabricate `SourceOnly` for a
    /// node that a real compiled walk would never see as "added" or
    /// "removed" in the first place: DD rename metadata is recorded only
    /// on the post-rename field, pointing backward, so the OLD field at
    /// its OLD path carries no tag of its own -- querying it as source
    /// against the NEW schema as target would otherwise see a plain
    /// absence and misclassify it. Besides exact matches, this recognizes a
    /// bare predecessor name within the renamed field's unchanged parent and
    /// descendants of a renamed structure or AoS. It deliberately does not
    /// select a successive history by version cutoff or derive replacement
    /// paths: #24/#25 own those decisions. This conservative check merely
    /// retains the explicit pending state until they do.
    pub fn may_have_renamed_from(&self, path: &str) -> bool {
        self.rename_references
            .iter()
            .any(|reference| reference.may_refer_to(path))
    }

    /// Paths present in `self` but absent from `other`: a schema-level
    /// fact retained regardless of whether any projection query ever
    /// visits them. When `self` is a stored schema and `other` is its
    /// working counterpart, this is exactly the "present in stored
    /// version, not loaded into working version" set issue #23 requires
    /// to be retained rather than lost -- because the compiled walk never
    /// visits a stored-only path, [`classify`] alone would never surface
    /// it, so this schema-fact enumeration is what keeps it available for
    /// issue #27's loss enumeration to consume later.
    pub fn only_in_self<'a>(&'a self, other: &FieldIndex) -> Vec<&'a str> {
        self.by_path
            .keys()
            .filter(|path| !other.by_path.contains_key(path.as_str()))
            .map(|path| path.as_str())
            .collect()
    }
}

/// The rename-metadata-free classification of one node relative to a
/// source/target schema pair (issue #23).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Classification {
    /// Present in both schemas under the identical path, with matching
    /// `data_type`, and neither side carries automatic rename metadata
    /// for it.
    Same,
    /// Present in the source schema, absent from the target schema under
    /// the identical path, and target has no automatic rename metadata that
    /// might refer to `path` (see [`FieldIndex::may_have_renamed_from`]).
    /// Depending on which schema plays source for a
    /// given query, this is either a compiled-only field (source is the
    /// working/compiled schema) or a stored-only field (source is the
    /// stored schema); the caller's own query direction disambiguates
    /// which, since both map to the same `PE_VERDICT_SKIP` outcome.
    SourceOnly,
    /// Present in both schemas under the identical path, but with
    /// different `data_type`, and neither side carries rename metadata.
    /// Every datatype change is an automatic-seam skip (see #18): this
    /// holds even when equivalent IMAS-Python metadata carries an
    /// explicit-conversion callback, because this classifier has no
    /// concept of a callback to consult in the first place.
    DatatypeChanged,
    /// The source's own field, or the identically-pathed field on the
    /// target side, carries automatic rename metadata
    /// (`change_nbc_description` of `leaf_renamed`, `aos_renamed`, or
    /// `structure_renamed`). Resolving that metadata into a real `same`/
    /// `rename` verdict is issue #24 (leaf renames, successive history)
    /// and issue #25 (array-of-structures and plain-structure renames,
    /// including cascade and missing-subtree collapsing); until then,
    /// this explicit state exists precisely so such a node is never
    /// silently folded into [`Classification::SourceOnly`] (added/
    /// removed) -- a naive by-path set difference would otherwise treat
    /// a renamed node as one field disappearing and an unrelated field
    /// appearing, discarding the very information #24/#25 need to
    /// resolve it correctly.
    RenamePending,
}

/// Classifies `path`, read from `source`, against `target` (issue #23).
///
/// Returns `None` when `path` is not a field known to `source` at all --
/// the caller (`ffi::pe_project_node_query`) treats that as an invalid
/// argument rather than a classification, since a real compiled walk only
/// ever queries paths it already knows belong to its own schema.
///
/// Rename metadata is checked before presence/absence or datatype
/// comparison, on both the source's and the target's identically-pathed
/// field: either side carrying it is enough to withhold a same/added/
/// removed/datatype-changed verdict (see [`Classification::RenamePending`]).
/// When `path` is altogether absent from `target`, `target` is also
/// checked for automatic rename metadata that may refer to `path` (see
/// [`FieldIndex::may_have_renamed_from`]) before concluding `SourceOnly` --
/// otherwise querying a renamed field by its OLD path
/// (the non-production `PE_DIRECTION_STORED_TO_WORKING` testing
/// direction) would fabricate an added/removed verdict purely because DD
/// rename metadata is recorded only on the post-rename field, pointing
/// backward, so the old field's own entry carries no tag to catch above.
pub fn classify(source: &FieldIndex, target: &FieldIndex, path: &str) -> Option<Classification> {
    let source_meta = source.get(path)?;
    if source_meta.carries_rename_metadata() {
        return Some(Classification::RenamePending);
    }
    Some(match target.get(path) {
        None if target.may_have_renamed_from(path) => Classification::RenamePending,
        None => Classification::SourceOnly,
        Some(target_meta) if target_meta.carries_rename_metadata() => Classification::RenamePending,
        Some(target_meta) if target_meta.data_type() != source_meta.data_type() => {
            Classification::DatatypeChanged
        }
        Some(_) => Classification::Same,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn index(xml: &str) -> FieldIndex {
        let doc = roxmltree::Document::parse(xml).unwrap();
        FieldIndex::from_document(&doc)
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
        assert_eq!(classify(&source, &target, "does/not/exist"), None);
    }

    #[test]
    fn identical_path_and_data_type_on_both_sides_is_same() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        assert_eq!(classify(&source, &target, "a"), Some(Classification::Same));
    }

    #[test]
    fn present_in_source_only_is_source_only() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "a"),
            Some(Classification::SourceOnly)
        );
    }

    #[test]
    fn matching_path_with_different_data_type_is_datatype_changed() {
        let source = index(r#"<IDSs><field name="a" path="a" data_type="INT_0D"/></IDSs>"#);
        let target = index(r#"<IDSs><field name="a" path="a" data_type="FLT_0D"/></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "a"),
            Some(Classification::DatatypeChanged)
        );
    }

    #[test]
    fn source_side_rename_metadata_withholds_source_only() {
        // Without the rename-metadata check, this would classify as
        // `SourceOnly` (added/removed) purely because the path differs --
        // exactly the fabricated classification issue #23 forbids.
        let source = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_name"/></IDSs>"#,
        );
        let target = index(r#"<IDSs><field name="n" path="old_name" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "new_name"),
            Some(Classification::RenamePending)
        );
    }

    #[test]
    fn target_side_rename_metadata_also_withholds_a_fabricated_verdict() {
        // The identically-pathed target field is tagged even though the
        // source's own field is not: still must not fabricate `Same`.
        let source = index(r#"<IDSs><field name="n" path="shared" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="shared" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="structure_renamed"
                 change_nbc_previous_name="elsewhere"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "shared"),
            Some(Classification::RenamePending)
        );
    }

    #[test]
    fn querying_the_old_path_of_a_renamed_field_does_not_fabricate_source_only() {
        // The tag lives only on the post-rename field ("new_name"),
        // pointing backward -- "old_name" itself carries nothing. Without
        // `may_have_renamed_from`, classifying from source=old (the
        // PE_DIRECTION_STORED_TO_WORKING testing direction) would see a
        // plain absence in target and fabricate `SourceOnly` (a "removed"
        // field) even though this path is exactly the previous name of a
        // real, still-existing field.
        let source = index(r#"<IDSs><field name="n" path="old_name" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="new_name" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_name"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "old_name"),
            Some(Classification::RenamePending)
        );
    }

    #[test]
    fn a_previous_name_matching_one_entry_of_a_successive_history_is_still_caught() {
        let source =
            index(r#"<IDSs><field name="n" path="middle_name" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="thrice_renamed" data_type="STR_0D"
                 change_nbc_version="1.0.0,2.0.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="ancient_name,middle_name"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "middle_name"),
            Some(Classification::RenamePending)
        );
    }

    #[test]
    fn a_bare_previous_name_within_the_same_parent_is_held_pending() {
        // This does not resolve the rename. It only prevents a bare sibling
        // predecessor name from fabricating an added/removed verdict before
        // #24 applies actual rename semantics.
        let source =
            index(r#"<IDSs><field name="n" path="group/old_leaf" data_type="STR_0D"/></IDSs>"#);
        let target = index(
            r#"<IDSs><field name="n" path="group/renamed_leaf" data_type="STR_0D"
                 change_nbc_version="3.1.0" change_nbc_description="leaf_renamed"
                 change_nbc_previous_name="old_leaf"/></IDSs>"#,
        );
        assert_eq!(
            classify(&source, &target, "group/old_leaf"),
            Some(Classification::RenamePending)
        );
        let unrelated_source =
            index(r#"<IDSs><field name="n" path="other/old_leaf" data_type="STR_0D"/></IDSs>"#);
        assert_eq!(
            classify(&unrelated_source, &target, "other/old_leaf"),
            Some(Classification::SourceOnly)
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
            classify(&source, &target, "old_struct/child"),
            Some(Classification::RenamePending)
        );
        assert_eq!(
            classify(&source, &target, "old_aos/value"),
            Some(Classification::RenamePending)
        );
    }

    /// Durability guard for issue #23's own acceptance criterion that its
    /// vectors remain valid after #24 and #25 activate rename metadata:
    /// #24 is scoped to leaf renames and successive history only, so an
    /// `aos_renamed`/`structure_renamed` node stays `RenamePending` through
    /// #24 and is only resolved by #25. Unlike the C ABI contract-test
    /// vectors, this Rust-internal test is free to be updated once #25
    /// actually resolves it.
    #[test]
    fn structural_and_array_rename_metadata_stays_pending_independent_of_leaf_rename_resolution() {
        let source = index(
            r#"<IDSs><field name="n" path="new_aos" data_type="struct_array"
                 change_nbc_version="4.0.0" change_nbc_description="aos_renamed"
                 change_nbc_previous_name="old_aos"/></IDSs>"#,
        );
        let target = index(r#"<IDSs></IDSs>"#);
        assert_eq!(
            classify(&source, &target, "new_aos"),
            Some(Classification::RenamePending)
        );
    }

    #[test]
    fn only_in_self_reports_stored_only_schema_facts_even_though_no_query_ever_visits_them() {
        let stored = index(
            r#"<IDSs>
                 <field name="a" path="shared" data_type="INT_0D"/>
                 <field name="b" path="stored_only" data_type="INT_0D"/>
               </IDSs>"#,
        );
        let working = index(r#"<IDSs><field name="a" path="shared" data_type="INT_0D"/></IDSs>"#);
        assert_eq!(stored.only_in_self(&working), vec!["stored_only"]);
        assert!(working.only_in_self(&stored).is_empty());
    }
}
