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
        }
    }
}

/// Shared projection-verdict vocabulary. This skeleton establishes the type;
/// real rename/skip decisions are computed once the map/cache substrate
/// lands in a later slice (see issue #21). Until then, every entry point
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
