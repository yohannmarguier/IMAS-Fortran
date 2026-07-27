//! XML parsing and DD-version identity resolution for one schema document
//! (issue #21). "Parsing" here is a `roxmltree` well-formedness check plus
//! locating the root's `<version>` child, plus (issue #23) building the
//! `field/@path` index used by real projection queries -- see
//! [`crate::projection`].
//!
//! Resolution rule (see issue #21's "What to build"): the XML `<version>`
//! element is authoritative when present, and the caller's claimed
//! identity must then agree with it. A caller-supplied fallback identity
//! is used only when the element is absent. Either way, a fabricated or
//! mismatched identity must never produce a [`ParsedSchema`].

use crate::projection::FieldIndex;
use crate::version::DdVersion;

/// One parsed, identity-validated DD schema document.
///
/// Holds the resolved version, the schema's own owned XML source (the
/// input is copied here rather than borrowed -- see `ffi::pe_map_acquire`'s
/// doc comment for why), and its [`FieldIndex`] (issue #23), built once
/// from the same parse rather than re-parsing the XML on every query.
#[derive(Debug)]
pub struct ParsedSchema {
    version: DdVersion,
    xml: String,
    field_index: FieldIndex,
}

impl ParsedSchema {
    pub fn version(&self) -> DdVersion {
        self.version
    }

    pub fn xml(&self) -> &str {
        &self.xml
    }

    pub fn field_index(&self) -> &FieldIndex {
        &self.field_index
    }
}

/// Why [`parse_and_resolve`] refused to produce a [`ParsedSchema`]. Every
/// variant maps to `PeStatus::SchemaIdentity` at the ABI boundary; they are
/// kept distinct here only so unit tests can assert on the specific cause.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SchemaError {
    /// `xml` is not well-formed.
    Malformed,
    /// No DD version could be determined: the `<version>` element is
    /// absent and the caller-supplied fallback does not itself parse as a
    /// `DdVersion`, or the element is present but its text does not parse.
    NoValidVersion,
    /// The `<version>` element is present and parses, but disagrees with
    /// the caller's claimed identity (or the claimed identity does not
    /// itself parse, which trivially disagrees with any real version).
    IdentityMismatch,
}

/// Parses `xml`, resolves its DD version against `claimed_version`, and
/// returns the validated, owned schema.
pub fn parse_and_resolve(xml: &str, claimed_version: &str) -> Result<ParsedSchema, SchemaError> {
    let doc = roxmltree::Document::parse(xml).map_err(|_| SchemaError::Malformed)?;

    let version_element_text = doc
        .root_element()
        .children()
        .find(|node| node.is_element() && node.tag_name().name() == "version")
        .and_then(|node| node.text());

    let version = match version_element_text {
        Some(text) => {
            let parsed = DdVersion::parse(text).map_err(|_| SchemaError::NoValidVersion)?;
            let claimed =
                DdVersion::parse(claimed_version).map_err(|_| SchemaError::IdentityMismatch)?;
            if parsed != claimed {
                return Err(SchemaError::IdentityMismatch);
            }
            parsed
        }
        None => DdVersion::parse(claimed_version).map_err(|_| SchemaError::NoValidVersion)?,
    };

    let field_index = FieldIndex::from_document(&doc);

    Ok(ParsedSchema {
        version,
        xml: xml.to_string(),
        field_index,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const VALID_XML: &str = "<IDSs><version>3.39.0</version></IDSs>";

    #[test]
    fn xml_version_element_is_authoritative_and_agrees_with_claim() {
        let schema = parse_and_resolve(VALID_XML, "3.39.0").unwrap();
        assert_eq!(schema.version(), DdVersion::parse("3.39.0").unwrap());
        assert_eq!(schema.xml(), VALID_XML);
    }

    #[test]
    fn malformed_xml_is_rejected() {
        let err = parse_and_resolve("<IDSs><version>3.39.0</version>", "3.39.0").unwrap_err();
        assert_eq!(err, SchemaError::Malformed);
    }

    #[test]
    fn missing_version_with_no_valid_fallback_is_rejected() {
        let err = parse_and_resolve("<IDSs><ids/></IDSs>", "not-a-version").unwrap_err();
        assert_eq!(err, SchemaError::NoValidVersion);
    }

    #[test]
    fn missing_version_falls_back_to_claimed_identity() {
        let schema = parse_and_resolve("<IDSs><ids/></IDSs>", "3.38.1").unwrap();
        assert_eq!(schema.version(), DdVersion::parse("3.38.1").unwrap());
    }

    #[test]
    fn present_version_element_with_garbled_text_is_rejected_even_with_valid_fallback() {
        // The element is present, so it is authoritative -- the fallback
        // must not be substituted for it even though the fallback itself
        // would have parsed fine.
        let err = parse_and_resolve("<IDSs><version>not-a-version</version></IDSs>", "3.39.0")
            .unwrap_err();
        assert_eq!(err, SchemaError::NoValidVersion);
    }

    #[test]
    fn claimed_identity_disagreeing_with_parsed_version_is_rejected() {
        let err = parse_and_resolve(VALID_XML, "4.0.0").unwrap_err();
        assert_eq!(err, SchemaError::IdentityMismatch);
    }

    #[test]
    fn unparseable_claimed_identity_is_rejected_as_mismatch_when_version_element_present() {
        let err = parse_and_resolve(VALID_XML, "not-a-version").unwrap_err();
        assert_eq!(err, SchemaError::IdentityMismatch);
    }

    #[test]
    fn fabricated_claim_cannot_override_a_real_parsed_version() {
        // Regression guard for "invalid or fabricated identities must
        // never produce a usable or cached map" (issue #21): even though
        // the fallback path would happily accept "9.9.9" on its own, the
        // presence of a real, different `<version>` element must still
        // win and be checked against the claim, not silently accepted.
        let err = parse_and_resolve(VALID_XML, "9.9.9").unwrap_err();
        assert_eq!(err, SchemaError::IdentityMismatch);
    }
}
