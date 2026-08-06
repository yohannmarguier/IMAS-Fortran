//! What the conversion cost, on the terminal.
//!
//! `dd-maps/README.md` makes fidelity the notification channel: anything other than
//! `exact` means the engine must warn, and `unmappable` means it must refuse rather than
//! guess. This is that channel.
//!
//! It reports **per rule, not per read**. One `ids_get` of a two-slice equilibrium drives
//! ~1000 reads, and `drop-timeslice-ggd-grid` alone claims 37 paths, so a line per
//! occurrence would print thousands of lines saying thirty-odd things. Each distinct rule
//! prints once, the first time it fires, and the summary carries the hit counts.
//!
//! Exact conversions — renames, moves, the 32 COCOS sign flips — are counted but not
//! printed. They cost nothing, and burying six real losses under a few hundred exact
//! rewrites is how a warning channel stops being read.
//!
//! Colour follows the same priority (see `paint.rs`): the losses carry it, the scaffolding
//! is dimmed out of the way, and a counter of zero recedes rather than shouting a number
//! that means "nothing to see". It is off unless stderr is a terminal, so a redirected log
//! or a CTest capture is byte-for-byte what it always was.
//!
//! As everywhere in this crate, nothing here may panic: `eprintln!` would, if the write
//! failed, so every line goes out through `write!` with the result discarded, and a
//! poisoned lock silently drops the line rather than taking the process with it.

use std::collections::HashMap;
use std::io::Write;
use std::sync::Mutex;

use crate::map::{Note, Verdict};
use crate::paint::{count, paint, Style};

/// The colour each outcome is reported in. Refused is worst — a value withheld — then
/// lossy, then a skip, which is a gap in the map or this shim rather than in the data.
/// Absent is yellow because it is expected: DD 4 simply has fields DD 3 never had.
fn style_of(verdict: Verdict) -> Style {
    match verdict {
        Verdict::Refused => Style::Refused,
        Verdict::Lossy => Style::Lossy,
        Verdict::Absent => Style::Absent,
        Verdict::Mapped => Style::Good,
    }
}

struct Entry {
    verdict: Verdict,
    note: Note,
    hits: u64,
}

#[derive(Default)]
struct Ledger {
    /// Keyed by the plan's dedup key, which is the rule id.
    entries: HashMap<String, Entry>,
    /// Reads that took a plan of any kind.
    converted: u64,
    /// Values whose sign was flipped for COCOS 11 -> 17.
    flipped: u64,
    /// Reads the map answered but the open context could not express.
    unreachable: u64,
    /// Startup complaints, printed once each.
    notices: Vec<String>,
}

static LEDGER: Mutex<Option<Ledger>> = Mutex::new(None);

/// Print one line to stderr. Not `eprintln!`, which panics if the write fails.
fn emit(line: &str) {
    let mut err = std::io::stderr().lock();
    let _ = writeln!(err, "{} {line}", paint("[imas-mw]", Style::Faint));
}

fn with_ledger<R>(f: impl FnOnce(&mut Ledger) -> R) -> Option<R> {
    let mut guard = LEDGER.lock().ok()?;
    Some(f(guard.get_or_insert_with(Ledger::default)))
}

/// One rule's line: `VERDICT wanted <- source: why [rule]`.
///
/// The two paths are the point. `wanted` is bold — it is what the program asked for and
/// what a reader is scanning for — and `source` is cyan, because when a fold falls back to
/// an obsolescent alias, *which DD 3 name the value actually came from* is the one thing
/// the line exists to say. The arrow and the rule id are scaffolding and are dimmed.
fn render(verdict: Verdict, note: &Note, indent: &str, suffix: &str) -> String {
    format!(
        "{indent}{} {} {} {}{}{}{}",
        tag(verdict.label(), style_of(verdict)),
        paint(&note.wanted, Style::Wanted),
        paint("<-", Style::Faint),
        // Cyan means "a DD 3 path you can go and look at". Having no source is a different
        // kind of fact, so it recedes instead of impersonating one.
        paint(
            note.source_or_nothing(),
            if note.sourceless() {
                Style::Faint
            } else {
                Style::Source
            },
        ),
        paint(": ", Style::Faint),
        note.detail,
        paint(&format!(" [{}]{suffix}", note.rule), Style::Faint),
    )
}

/// A label painted and then padded to a fixed column.
///
/// The padding cannot go through `{:<8}`: escape codes are zero-width on screen but not to
/// the formatter, so formatting an already-painted string pads by nothing and every line
/// after the first colour ends up ragged. Width is counted on the text, applied outside the
/// escapes — which also keeps the coloured and uncoloured renderings aligned identically.
const LABEL_WIDTH: usize = 8;

fn tag(label: &str, style: Style) -> String {
    format!(
        "{}{}",
        paint(label, style),
        " ".repeat(LABEL_WIDTH.saturating_sub(label.chars().count()))
    )
}

/// A one-off message, printed immediately and repeated in the summary — the map banner
/// and anything the loader could not make sense of.
pub fn notice(line: &str) {
    emit(&paint(line, Style::Heading));
    with_ledger(|ledger| ledger.notices.push(line.to_string()));
}

/// Count one converted read, printing the rule's line the first time it fires.
pub fn record(verdict: Verdict, key: &str, note: &Note, flipped: bool) {
    let first = with_ledger(|ledger| {
        ledger.converted += 1;
        if flipped {
            ledger.flipped += 1;
        }
        match ledger.entries.get_mut(key) {
            Some(entry) => {
                entry.hits += 1;
                false
            }
            None => {
                ledger.entries.insert(
                    key.to_string(),
                    Entry {
                        verdict,
                        note: Note {
                            wanted: note.wanted.clone(),
                            source: note.source.clone(),
                            detail: note.detail.clone(),
                            rule: note.rule.clone(),
                        },
                        hits: 1,
                    },
                );
                verdict.is_loss()
            }
        }
    });
    if first == Some(true) {
        emit(&render(verdict, note, "", ""));
    }
}

/// Count a read the map answered but the context could not express. Printed once: it is a
/// gap in the map or in this shim, not a property of the data — which is why it gets a
/// colour of its own rather than borrowing a verdict's.
pub fn unreachable(right: &str, left: &str) {
    let first = with_ledger(|ledger| {
        ledger.unreachable += 1;
        ledger.unreachable == 1
    });
    if first == Some(true) {
        emit(&format!(
            "{} {} {} {}{}not reachable from the open context, read unchanged",
            tag("SKIPPED", Style::Skipped),
            paint(right, Style::Wanted),
            paint("<-", Style::Faint),
            paint(left, Style::Source),
            paint(": ", Style::Faint),
        ));
    }
}

/// The whole story, for a program to print when it is done reading.
pub fn summary() -> Vec<String> {
    with_ledger(|ledger| {
        let mut lines: Vec<String> = ledger
            .notices
            .iter()
            .map(|notice| paint(notice, Style::Heading))
            .collect();

        let tally = |want: Verdict| -> (usize, u64) {
            ledger
                .entries
                .values()
                .filter(|entry| entry.verdict == want)
                .fold((0, 0), |(rules, hits), entry| (rules + 1, hits + entry.hits))
        };

        // `label : <rules> rules, <hits> reads`, with both numbers dimmed when they are
        // zero. A run with nothing to answer for is then almost entirely grey, and the one
        // red number in a run that does have something is impossible to miss.
        let mut counter = |label: &str, rules: usize, hits: u64, style: Style| {
            lines.push(format!(
                "{label:<23}: {} rules, {} reads",
                count(rules as u64, style),
                count(hits, style),
            ));
        };
        let (rules, hits) = tally(Verdict::Mapped);
        counter("exact", rules, hits, Style::Good);
        let (rules, hits) = tally(Verdict::Lossy);
        counter("lossy", rules, hits, Style::Lossy);
        let (rules, hits) = tally(Verdict::Absent);
        counter("no DD3 source", rules, hits, Style::Absent);
        let (rules, hits) = tally(Verdict::Refused);
        counter("refused as unmappable", rules, hits, Style::Refused);

        lines.push(format!(
            "{:<23}: {} reads",
            "converted",
            count(ledger.converted, Style::Good)
        ));
        lines.push(format!(
            "{:<23}: {} values",
            "COCOS sign flips",
            count(ledger.flipped, Style::Good)
        ));
        if ledger.unreachable > 0 {
            lines.push(format!(
                "{:<23}: {} reads",
                "not reachable",
                count(ledger.unreachable, Style::Skipped)
            ));
        }

        // Losses in full, worst first, so the summary stands on its own even when the
        // first-sighting lines have scrolled away or been interleaved with stdout.
        for want in [Verdict::Refused, Verdict::Absent, Verdict::Lossy] {
            let mut group: Vec<&Entry> = ledger
                .entries
                .values()
                .filter(|entry| entry.verdict == want)
                .collect();
            group.sort_by_key(|entry| entry.note.wanted.clone());
            for entry in group {
                lines.push(render(
                    want,
                    &entry.note,
                    "  ",
                    &format!(" ({} reads)", entry.hits),
                ));
            }
        }
        lines
    })
    .unwrap_or_default()
}

/// Number of reads whose value the map could not deliver faithfully — lossy, absent,
/// refused or unreachable. A program can assert on it without parsing stderr.
pub fn losses() -> u64 {
    with_ledger(|ledger| {
        ledger.unreachable
            + ledger
                .entries
                .values()
                .filter(|entry| entry.verdict.is_loss())
                .map(|entry| entry.hits)
                .sum::<u64>()
    })
    .unwrap_or(0)
}

/// Print the summary. Exported so a Fortran program can ask for it at the end of a run
/// rather than depending on a destructor a `staticlib` does not reliably get.
#[no_mangle]
pub extern "C" fn imas_mw_conversion_report() {
    let lines = summary();
    if lines.is_empty() {
        emit(&paint("no DD conversion was active", Style::Faint));
        return;
    }
    emit(&paint("---- DD conversion report ----", Style::Faint));
    for line in lines {
        emit(&line);
    }
    emit(&paint("------------------------------", Style::Faint));
}

/// `report::losses()` for Fortran.
#[no_mangle]
pub extern "C" fn imas_mw_conversion_losses() -> u64 {
    losses()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paint;

    fn note(wanted: &str, source: &str, rule: &str) -> Note {
        Note {
            wanted: wanted.to_string(),
            source: source.to_string(),
            detail: "why".to_string(),
            rule: rule.to_string(),
        }
    }

    /// The ledger and the colour decision are both process-global, so this is one test
    /// rather than several racing ones. Colour is forced off first: what is asserted here
    /// is the content, and `paint`'s own test covers the escapes.
    #[test]
    fn the_ledger_counts_per_rule_and_totals_per_read() {
        let _colour = paint::test_lock();
        paint::force(false);

        let fold = note("profiles_1d/j_phi", "j_phi | j_tor", "fold-p1d-j");
        record(Verdict::Lossy, "fold-p1d-j", &fold, true);
        record(Verdict::Lossy, "fold-p1d-j", &fold, true);
        record(
            Verdict::Absent,
            "new-contour-tree",
            &note("contour_tree", "(nothing)", "new-contour-tree"),
            false,
        );
        record(
            Verdict::Mapped,
            "rename-bpol-probe",
            &note("b_field_pol_probe", "bpol_probe", "rename-bpol-probe"),
            false,
        );
        unreachable("a/b", "c/d");

        let summary = summary();
        let has = |needle: &str| summary.iter().any(|line| line.contains(needle));

        assert!(has("converted              : 4 reads"), "{summary:#?}");
        assert!(has("COCOS sign flips       : 2 values"), "{summary:#?}");
        assert!(has("lossy                  : 1 rules, 2 reads"), "{summary:#?}");
        assert!(has("no DD3 source          : 1 rules, 1 reads"), "{summary:#?}");
        assert!(has("exact                  : 1 rules, 1 reads"), "{summary:#?}");
        assert!(has("not reachable          : 1 reads"), "{summary:#?}");

        // 2 lossy + 1 absent + 1 unreachable; the exact rewrite is not a loss.
        assert_eq!(losses(), 4);

        // The detail block repeats every loss and no exact conversion.
        assert!(
            has("LOSSY    profiles_1d/j_phi <- j_phi | j_tor: why [fold-p1d-j] (2 reads)"),
            "{summary:#?}"
        );
        assert!(
            has("ABSENT   contour_tree <- (nothing): why [new-contour-tree] (1 reads)"),
            "{summary:#?}"
        );
        assert!(!has("MAPPED   b_field_pol_probe"), "exact conversions are not listed");
    }

    /// With colour on, the severity lands on the verdict and the provenance on the two
    /// paths — the two things the line exists to distinguish.
    #[test]
    fn a_rendered_loss_paints_the_verdict_and_both_paths() {
        let _colour = paint::test_lock();
        paint::force(true);
        let line = render(
            Verdict::Lossy,
            &note("profiles_1d/j_phi", "profiles_1d/j_tor", "fold-p1d-j"),
            "",
            "",
        );
        assert!(line.contains("\x1b[31mLOSSY\x1b[0m"), "{line:?}");
        assert!(line.contains("\x1b[1mprofiles_1d/j_phi\x1b[0m"), "{line:?}");
        assert!(line.contains("\x1b[36mprofiles_1d/j_tor\x1b[0m"), "{line:?}");
        assert!(line.contains("\x1b[2m [fold-p1d-j]\x1b[0m"), "{line:?}");

        // Refused is the one that gets bold red, since it is the only outcome where a
        // value is withheld rather than merely degraded.
        let line = render(
            Verdict::Refused,
            &note("chi_squared_r", "(nothing)", "transforms/redefine"),
            "",
            "",
        );
        assert!(line.contains("\x1b[1;31mREFUSED\x1b[0m"), "{line:?}");

        paint::force(false);
    }

    /// The column the paths start in must not move when colour goes on — the whole value of
    /// a fixed-width label is that the eye can run down it. This is the regression `{:<8}`
    /// on a painted string silently causes.
    #[test]
    fn the_label_column_is_the_same_painted_or_not() {
        let _colour = paint::test_lock();
        let column = |line: &str| {
            // Everything up to the first path, with escapes removed: that is what the
            // terminal actually advances by.
            strip(line).find("chi_squared_r").expect("the path is in the line")
        };
        let one = note("chi_squared_r", "(nothing)", "r");

        paint::force(false);
        let plain_refused = column(&render(Verdict::Refused, &one, "", ""));
        let plain_lossy = column(&render(Verdict::Lossy, &one, "", ""));
        paint::force(true);
        let painted_refused = column(&render(Verdict::Refused, &one, "", ""));
        let painted_lossy = column(&render(Verdict::Lossy, &one, "", ""));
        paint::force(false);

        assert_eq!(plain_refused, painted_refused, "colour moved the path column");
        assert_eq!(plain_lossy, painted_lossy, "colour moved the path column");
        assert_eq!(
            plain_refused, plain_lossy,
            "REFUSED and LOSSY must share a column despite differing in length"
        );
    }

    /// Drop ANSI escapes, so a test can measure what a terminal would show.
    fn strip(line: &str) -> String {
        let mut out = String::with_capacity(line.len());
        let mut chars = line.chars();
        while let Some(c) = chars.next() {
            if c != '\x1b' {
                out.push(c);
                continue;
            }
            // "\x1b[" then parameters then a final letter.
            for c in chars.by_ref() {
                if c.is_ascii_alphabetic() {
                    break;
                }
            }
        }
        out
    }
}
