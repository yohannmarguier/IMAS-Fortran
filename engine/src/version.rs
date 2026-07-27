//! Semantic DD version identity: `major.minor.patch`, parsed from either
//! the XML `<version>` element or a caller-supplied fallback (see
//! [`crate::schema`]).
//!
//! Only ordering and major-version equality are needed by this slice
//! (issue #21's cross-major check and identity comparison); rename-history
//! cutoff comparisons land with issue #24.

use std::fmt;

/// A parsed `major.minor.patch` Data Dictionary version, e.g. `3.39.0`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct DdVersion {
    major: u32,
    minor: u32,
    patch: u32,
}

/// `raw` was not a well-formed `major.minor.patch` version string.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParseVersionError;

impl DdVersion {
    /// Parses a version of the exact form `major.minor.patch`, e.g.
    /// `"3.39.0"`. Leading/trailing whitespace is trimmed; anything else
    /// that is not three dot-separated non-negative integers is rejected.
    pub fn parse(raw: &str) -> Result<Self, ParseVersionError> {
        let raw = raw.trim();
        let mut parts = raw.split('.');
        let major = parts.next().ok_or(ParseVersionError)?;
        let minor = parts.next().ok_or(ParseVersionError)?;
        let patch = parts.next().ok_or(ParseVersionError)?;
        if parts.next().is_some() {
            return Err(ParseVersionError);
        }
        Ok(DdVersion {
            major: major.parse().map_err(|_| ParseVersionError)?,
            minor: minor.parse().map_err(|_| ParseVersionError)?,
            patch: patch.parse().map_err(|_| ParseVersionError)?,
        })
    }

    pub fn major(self) -> u32 {
        self.major
    }
}

impl fmt::Display for DdVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}.{}.{}", self.major, self.minor, self.patch)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_well_formed_version() {
        let v = DdVersion::parse("3.39.0").unwrap();
        assert_eq!(v.major(), 3);
        assert_eq!(v.to_string(), "3.39.0");
    }

    #[test]
    fn trims_surrounding_whitespace() {
        assert_eq!(DdVersion::parse("  3.39.0\n"), DdVersion::parse("3.39.0"));
    }

    #[test]
    fn rejects_wrong_component_count() {
        assert!(DdVersion::parse("3.39").is_err());
        assert!(DdVersion::parse("3.39.0.1").is_err());
        assert!(DdVersion::parse("3").is_err());
    }

    #[test]
    fn rejects_non_numeric_components() {
        assert!(DdVersion::parse("a.b.c").is_err());
        assert!(DdVersion::parse("3.x.0").is_err());
        assert!(DdVersion::parse("").is_err());
    }

    #[test]
    fn compares_by_numeric_value_not_lexical_order() {
        // Lexically "10.0.0" < "9.0.0", but numerically it is greater.
        let v9 = DdVersion::parse("9.0.0").unwrap();
        let v10 = DdVersion::parse("10.0.0").unwrap();
        assert!(v10 > v9);
        assert_eq!(v10.major(), 10);
    }

    #[test]
    fn equal_strings_parse_equal() {
        assert_eq!(
            DdVersion::parse("4.0.0").unwrap(),
            DdVersion::parse("4.0.0").unwrap()
        );
    }
}
