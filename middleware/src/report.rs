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
//! As everywhere in this crate, nothing here may panic: `eprintln!` would, if the write
//! failed, so every line goes out through `write!` with the result discarded, and a
//! poisoned lock silently drops the line rather than taking the process with it.

use std::collections::HashMap;
use std::io::Write;
use std::sync::Mutex;

use crate::map::Verdict;

struct Entry {
    verdict: Verdict,
    line: String,
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
    /// Reads the map could not express through the context they arrived on.
    unreachable: u64,
    /// Startup complaints, printed once each.
    notices: Vec<String>,
}

static LEDGER: Mutex<Option<Ledger>> = Mutex::new(None);

const TAG: &str = "[imas-mw]";

/// Print one line to stderr. Not `eprintln!`, which panics if the write fails.
fn emit(line: &str) {
    let mut err = std::io::stderr().lock();
    let _ = writeln!(err, "{TAG} {line}");
}

fn with_ledger<R>(f: impl FnOnce(&mut Ledger) -> R) -> Option<R> {
    let mut guard = LEDGER.lock().ok()?;
    Some(f(guard.get_or_insert_with(Ledger::default)))
}

/// A one-off message, printed immediately and repeated in the summary — the map banner
/// and anything the loader could not make sense of.
pub fn notice(line: &str) {
    emit(line);
    with_ledger(|ledger| ledger.notices.push(line.to_string()));
}

/// Count one converted read, printing the rule's line the first time it fires.
pub fn record(verdict: Verdict, key: &str, line: &str, flipped: bool) {
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
                        line: line.to_string(),
                        hits: 1,
                    },
                );
                verdict.is_loss()
            }
        }
    });
    if first == Some(true) {
        emit(&format!("{:<8} {line}", verdict.label()));
    }
}

/// Count a read the map answered but the context could not express. Printed once: it is a
/// gap in the map or in this shim, not a property of the data.
pub fn unreachable(right: &str, left: &str) {
    let first = with_ledger(|ledger| {
        ledger.unreachable += 1;
        ledger.unreachable == 1
    });
    if first == Some(true) {
        emit(&format!(
            "{:<8} {right} <- {left}: not reachable from the open context, read unchanged",
            "SKIPPED"
        ));
    }
}

/// The whole story, for a program to print when it is done reading.
pub fn summary() -> Vec<String> {
    let Some(lines) = with_ledger(|ledger| {
        let mut lines: Vec<String> = ledger.notices.clone();

        let count = |want: Verdict| -> (usize, u64) {
            ledger
                .entries
                .values()
                .filter(|entry| entry.verdict == want)
                .fold((0, 0), |(rules, hits), entry| (rules + 1, hits + entry.hits))
        };
        let (mapped_rules, mapped_hits) = count(Verdict::Mapped);
        let (lossy_rules, lossy_hits) = count(Verdict::Lossy);
        let (absent_rules, absent_hits) = count(Verdict::Absent);
        let (refused_rules, refused_hits) = count(Verdict::Refused);

        lines.push(format!("reads converted        : {}", ledger.converted));
        lines.push(format!(
            "exact                  : {mapped_rules} rules, {mapped_hits} reads"
        ));
        lines.push(format!("COCOS sign flips       : {}", ledger.flipped));
        lines.push(format!(
            "lossy                  : {lossy_rules} rules, {lossy_hits} reads"
        ));
        lines.push(format!(
            "no DD3 source          : {absent_rules} rules, {absent_hits} reads"
        ));
        lines.push(format!(
            "refused as unmappable  : {refused_rules} rules, {refused_hits} reads"
        ));
        if ledger.unreachable > 0 {
            lines.push(format!(
                "not reachable          : {} reads",
                ledger.unreachable
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
            group.sort_by(|a, b| a.line.cmp(&b.line));
            for entry in group {
                lines.push(format!(
                    "  {:<8} {} ({} reads)",
                    want.label(),
                    entry.line,
                    entry.hits
                ));
            }
        }
        lines
    }) else {
        return Vec::new();
    };
    lines
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
        emit("no DD conversion was active");
        return;
    }
    emit("---- DD conversion report ----");
    for line in lines {
        emit(&line);
    }
    emit("------------------------------");
}

/// `report::losses()` for Fortran.
#[no_mangle]
pub extern "C" fn imas_mw_conversion_losses() -> u64 {
    losses()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The ledger is process-global, so this is one test rather than several racing ones.
    #[test]
    fn the_ledger_counts_per_rule_and_totals_per_read() {
        record(Verdict::Lossy, "fold-p1d-j", "j_phi <- j_phi | j_tor", true);
        record(Verdict::Lossy, "fold-p1d-j", "j_phi <- j_phi | j_tor", true);
        record(Verdict::Absent, "new-contour-tree", "contour_tree", false);
        record(Verdict::Mapped, "rename-bpol-probe", "probe", false);
        unreachable("a/b", "c/d");

        let summary = summary();
        let has = |needle: &str| summary.iter().any(|line| line.contains(needle));

        assert!(has("reads converted        : 4"), "{summary:#?}");
        assert!(has("COCOS sign flips       : 2"), "{summary:#?}");
        assert!(has("lossy                  : 1 rules, 2 reads"), "{summary:#?}");
        assert!(has("no DD3 source          : 1 rules, 1 reads"), "{summary:#?}");
        assert!(has("exact                  : 1 rules, 1 reads"), "{summary:#?}");
        assert!(has("not reachable          : 1 reads"), "{summary:#?}");

        // 2 lossy + 1 absent + 1 unreachable; the exact rewrite is not a loss.
        assert_eq!(losses(), 4);

        // The detail block repeats every loss and no exact conversion.
        assert!(has("LOSSY    j_phi <- j_phi | j_tor (2 reads)"), "{summary:#?}");
        assert!(has("ABSENT   contour_tree (1 reads)"), "{summary:#?}");
        assert!(!has("MAPPED   probe"), "exact conversions are not listed");
    }
}
