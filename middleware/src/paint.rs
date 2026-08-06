//! ANSI colour for the conversion report.
//!
//! The report is a warning channel (see `report.rs`), and a warning channel that reads as
//! one undifferentiated wall of text stops being read. Colour carries two axes here:
//!
//! - **Severity**, on the verdict label: refused is worse than lossy is worse than absent.
//! - **Provenance**, within a line: the DD 4.1.1 path the program *asked for* against the
//!   DD 3.39.0 path the value was *read from*. When a fold falls back to an obsolescent
//!   alias, which name the data actually came from is the whole question, so that is the
//!   part painted rather than the prose around it.
//!
//! Everything that is scaffolding — the `[imas-mw]` tag, the arrow, the rule id, a zero
//! counter — is dimmed instead of coloured, so what is left at full brightness is the
//! content. A clean run is mostly grey with green counts; a run with a refusal has exactly
//! one bold red thing in it.
//!
//! **Off unless stderr is a terminal.** Escapes in a redirected log are noise, and this
//! crate's output can end up in a CTest log whose `FAIL_REGULAR_EXPRESSION` is matched
//! against raw bytes. `NO_COLOR` (any value) and `TERM=dumb` also turn it off, and
//! `IMAS_MW_COLOR=always|never|auto` overrides the lot — `always` being the way to get
//! colour through a pipe into `less -R`.
//!
//! Deliberately *not* applied to `IMAS_MW_TRACE`: that is a hundreds-of-thousands-of-lines
//! firehose people grep and diff, where escapes cost more than they explain.

use std::ffi::c_int;
use std::sync::atomic::{AtomicU8, Ordering};

/// A colour role, named for what it means rather than for the colour it picks — so the
/// palette can change in one place without every call site lying about its intent.
#[derive(Clone, Copy)]
pub enum Style {
    /// A value withheld: the map calls it unmappable and the read returns nothing.
    Refused,
    /// Data discarded but a value delivered.
    Lossy,
    /// No source in the older version. Expected, not a defect.
    Absent,
    /// A gap in the map or in this shim rather than in the data.
    Skipped,
    /// An exact conversion, and any count of zero problems.
    Good,
    /// A DD path in the version the caller asked for.
    Wanted,
    /// A DD path in the version the value came from.
    Source,
    /// Headings.
    Heading,
    /// Scaffolding: tags, arrows, rule ids, counters that are zero.
    Faint,
}

impl Style {
    fn code(self) -> &'static str {
        match self {
            Style::Refused => "1;31", // bold red
            Style::Lossy => "31",     // red
            Style::Absent => "33",    // yellow
            Style::Skipped => "35",   // magenta
            Style::Good => "32",      // green
            Style::Wanted => "1",     // bold, no hue: it is the subject, not a severity
            Style::Source => "36",    // cyan
            Style::Heading => "1;36", // bold cyan
            Style::Faint => "2",      // dim
        }
    }
}

/// `text` wrapped in `style`, or `text` unchanged when colour is off.
pub fn paint(text: &str, style: Style) -> String {
    if !enabled() {
        return text.to_string();
    }
    format!("\x1b[{}m{text}\x1b[0m", style.code())
}

/// A count, painted by `style` when it is non-zero and dimmed when it is zero. Zero is the
/// good news in this report and should recede.
pub fn count(n: u64, style: Style) -> String {
    paint(&n.to_string(), if n == 0 { Style::Faint } else { style })
}

const UNSET: u8 = 0;
const ON: u8 = 1;
const OFF: u8 = 2;

static STATE: AtomicU8 = AtomicU8::new(UNSET);

/// Whether to emit escapes. Decided once and cached; the report is at most a few dozen
/// lines per run, so the cache is tidiness rather than a hot path.
pub fn enabled() -> bool {
    match STATE.load(Ordering::Relaxed) {
        ON => true,
        OFF => false,
        _ => {
            let on = decide();
            STATE.store(if on { ON } else { OFF }, Ordering::Relaxed);
            on
        }
    }
}

fn decide() -> bool {
    // An explicit request wins over everything, including NO_COLOR — someone typing
    // IMAS_MW_COLOR=always has said what they want.
    match std::env::var("IMAS_MW_COLOR")
        .map(|v| v.trim().to_ascii_lowercase())
        .as_deref()
    {
        Ok("always") | Ok("force") | Ok("1") | Ok("yes") => return true,
        Ok("never") | Ok("none") | Ok("0") | Ok("no") => return false,
        // "auto", anything else, or unset: fall through to detection.
        _ => {}
    }
    // https://no-color.org — presence is the signal, whatever the value.
    if std::env::var_os("NO_COLOR").is_some() {
        return false;
    }
    if matches!(std::env::var("TERM").as_deref(), Ok("dumb") | Ok("")) {
        return false;
    }
    is_terminal(STDERR_FILENO)
}

const STDERR_FILENO: c_int = 2;

extern "C" {
    /// From libc, which is linked into anything that got this far. Used rather than
    /// `std::io::IsTerminal` because that stabilised in Rust 1.70 — above this crate's
    /// declared 1.76 floor, but the `extern` is two lines and keeps the floor a choice
    /// rather than a consequence.
    fn isatty(fd: c_int) -> c_int;
}

fn is_terminal(fd: c_int) -> bool {
    // Safety: `isatty` reads no memory and tolerates any int, returning 0 for a bad fd.
    unsafe { isatty(fd) == 1 }
}

/// Force colour on or off, for tests that assert on rendered text. Not exposed outside
/// them: the environment is the supported way to override the decision.
#[cfg(test)]
pub fn force(on: bool) {
    STATE.store(if on { ON } else { OFF }, Ordering::Relaxed);
}

/// Held for the duration of any test that calls `force`. The decision is one global and
/// cargo runs tests on threads, so tests in `paint` and in `report` would otherwise flip it
/// under each other — which fails as an assertion about escape codes and reads as a bug in
/// the painting rather than in the test setup.
#[cfg(test)]
pub fn test_lock() -> std::sync::MutexGuard<'static, ()> {
    static LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());
    // A test that panicked while holding it poisons it; the guard protects a decision with
    // no invariant to corrupt, so recovering is right and beats a cascade of failures.
    LOCK.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn painting_is_exact_when_on_and_invisible_when_off() {
        let _colour = test_lock();
        force(false);
        assert_eq!(paint("LOSSY", Style::Lossy), "LOSSY");
        assert_eq!(count(0, Style::Good), "0");
        assert_eq!(count(7, Style::Lossy), "7");

        force(true);
        assert_eq!(paint("LOSSY", Style::Lossy), "\x1b[31mLOSSY\x1b[0m");
        assert_eq!(paint("REFUSED", Style::Refused), "\x1b[1;31mREFUSED\x1b[0m");
        // Zero recedes even when it was handed a severity colour.
        assert_eq!(count(0, Style::Lossy), "\x1b[2m0\x1b[0m");
        assert_eq!(count(7, Style::Lossy), "\x1b[31m7\x1b[0m");

        force(false);
    }
}
