//! The conversion map, and the right → left path lookup the read path runs on it.
//!
//! `dd-maps/equilibrium/3.39.0--4.1.1.xml` describes one IDS as it exists in two DD
//! versions, direction-neutrally: the versions are `left` (3.39.0) and `right` (4.1.1),
//! and each `<rule rel="…">` names a relationship rather than an action.
//!
//! This module reads it in the one direction the read path needs. A program built
//! against DD 4.1.1 asks for a **right** path; the data in the backend is DD 3.39.0, so
//! the shim has to answer "which **left** path holds this value". That is the *reverse*
//! path lookup carrying the *forward* data flow (3.39.0 → 4.1.1), so the fidelity that
//! matters throughout is `@forward` — reverse fidelity is never consulted here.
//!
//! Which rules matter follows from that. A rule with no right-hand path (`left_only`,
//! including the whole error-model rule set) is invisible on this path: a DD 4.1.1
//! program never asks for a path DD 4.1.1 does not have. Those rules are dropped at load
//! time rather than carried and skipped.
//!
//! Specificity, per `dd-maps/README.md`: rules may overlap textually and the most
//! specific — the one consuming the most path segments — wins. An explicit `right=`
//! beats a `right-glob=` of the same length, and a `right-suffix=` is least specific of
//! all, so `move-gap` and `drop-gap-identifier` resolve the way the map's comment says
//! they do.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex};

use crate::xml::{Event, Reader};

/// The map is compiled in rather than read at run time: no file to locate from a
/// process whose working directory is the caller's, no failure mode on a compute node,
/// and cargo already tracks `include_str!` inputs so editing a map rebuilds the shim.
/// `CMakeLists.txt` names the same files as DEPENDS so the CMake side agrees.
const MAP_XML: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../dd-maps/equilibrium/3.39.0--4.1.1.xml"
));

/// `<include href="../common/…"/>` targets, resolved by file name. The map's includes are
/// rule sets shared by every IDS, so there are few of them and they change rarely; an
/// href this table does not know is reported by `Map::load` rather than ignored.
const INCLUDES: &[(&str, &str)] = &[
    (
        "error-model-3to4.xml",
        include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../dd-maps/common/error-model-3to4.xml"
        )),
    ),
    (
        "naming-3to4.xml",
        include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../dd-maps/common/naming-3to4.xml"
        )),
    ),
];

// ===================================================================== vocabularies

/// `<fidelity forward=…>`, the map's notification channel: anything but `Exact` must be
/// reported, and `Unmappable` must be refused rather than guessed.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Fidelity {
    Exact,
    Approximate,
    Lossy,
    Unmappable,
}

impl Fidelity {
    fn parse(s: &str) -> Option<Fidelity> {
        match s {
            "exact" => Some(Fidelity::Exact),
            "approximate" => Some(Fidelity::Approximate),
            "lossy" => Some(Fidelity::Lossy),
            "unmappable" => Some(Fidelity::Unmappable),
            _ => None,
        }
    }
}

/// `<rule rel=…>`. `Identical` and `Redefined` never appear as a rule in this map (the
/// former is the `<default>`, the latter lives in `<transforms>`) but both are in the
/// XSD's vocabulary, so both are accepted.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Rel {
    Identical,
    Renamed,
    Moved,
    Merged,
    Split,
    Retyped,
    Redefined,
    LeftOnly,
    RightOnly,
}

impl Rel {
    fn parse(s: &str) -> Option<Rel> {
        match s {
            "identical" => Some(Rel::Identical),
            "renamed" => Some(Rel::Renamed),
            "moved" => Some(Rel::Moved),
            "merged" => Some(Rel::Merged),
            "split" => Some(Rel::Split),
            "retyped" => Some(Rel::Retyped),
            "redefined" => Some(Rel::Redefined),
            "left_only" => Some(Rel::LeftOnly),
            "right_only" => Some(Rel::RightOnly),
            _ => None,
        }
    }
}

/// What the report calls the outcome of one path. `Mapped` is the only one that is not
/// printed: it means the map promises the value survives unchanged, and 32 COCOS flips
/// plus every rename would otherwise bury the losses that matter.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Verdict {
    Mapped,
    Lossy,
    Absent,
    Refused,
}

impl Verdict {
    pub fn label(self) -> &'static str {
        match self {
            Verdict::Mapped => "MAPPED",
            Verdict::Lossy => "LOSSY",
            Verdict::Absent => "ABSENT",
            Verdict::Refused => "REFUSED",
        }
    }

    /// Exact conversions are counted, not printed.
    pub fn is_loss(self) -> bool {
        self != Verdict::Mapped
    }
}

// ===================================================================== matching

/// How a rule recognises a path on one side of the map.
#[derive(Debug)]
enum Matcher {
    /// `right="a/b"`, claiming descendants too when `subtree="yes"`.
    Path { path: String, subtree: bool },
    /// `right-glob="**/tail"`. The `**/` binds a prefix that the rule's left side reuses,
    /// so the glob matches whole segments only.
    Tail { tail: String, subtree: bool },
    /// `right-suffix="_error_upper"` — the final segment *ends with* this text, which is
    /// not a segment boundary and so is the least specific form there is.
    Suffix { suffix: String },
}

/// A successful match, and everything the rewrite needs to rebuild the other side.
struct Hit {
    /// Path segments consumed. The most specific rule wins, so this is the rank.
    score: usize,
    /// True for an explicit `right=`, which outranks a glob that consumed as much.
    explicit: bool,
    /// What `**/` bound, for a glob.
    prefix: String,
    /// The descendant part below the claimed path, for a `subtree` match.
    remainder: String,
}

fn segments(path: &str) -> usize {
    path.split('/').filter(|s| !s.is_empty()).count()
}

impl Matcher {
    fn matches(&self, path: &str) -> Option<Hit> {
        match self {
            Matcher::Path {
                path: claimed,
                subtree,
            } => {
                if path == claimed {
                    return Some(Hit {
                        score: segments(claimed),
                        explicit: true,
                        prefix: String::new(),
                        remainder: String::new(),
                    });
                }
                if !subtree {
                    return None;
                }
                path.strip_prefix(claimed.as_str())
                    .and_then(|rest| rest.strip_prefix('/'))
                    .map(|remainder| Hit {
                        score: segments(claimed),
                        explicit: true,
                        prefix: String::new(),
                        remainder: remainder.to_string(),
                    })
            }
            Matcher::Tail { tail, subtree } => {
                let score = segments(tail);
                if path == tail {
                    return Some(Hit {
                        score,
                        explicit: false,
                        prefix: String::new(),
                        remainder: String::new(),
                    });
                }
                if let Some(prefix) = path
                    .strip_suffix(tail.as_str())
                    .and_then(|head| head.strip_suffix('/'))
                {
                    return Some(Hit {
                        score,
                        explicit: false,
                        prefix: prefix.to_string(),
                        remainder: String::new(),
                    });
                }
                if !subtree {
                    return None;
                }
                if let Some(remainder) = path
                    .strip_prefix(tail.as_str())
                    .and_then(|rest| rest.strip_prefix('/'))
                {
                    return Some(Hit {
                        score,
                        explicit: false,
                        prefix: String::new(),
                        remainder: remainder.to_string(),
                    });
                }
                let needle = format!("/{tail}/");
                let at = path.find(needle.as_str())?;
                Some(Hit {
                    score,
                    explicit: false,
                    prefix: path.get(..at)?.to_string(),
                    remainder: path.get(at + needle.len()..)?.to_string(),
                })
            }
            Matcher::Suffix { suffix } => {
                let last = path.rsplit('/').next()?;
                if last.ends_with(suffix.as_str()) {
                    Some(Hit {
                        score: 0,
                        explicit: false,
                        prefix: String::new(),
                        remainder: String::new(),
                    })
                } else {
                    None
                }
            }
        }
    }

    /// The declared path, for the report. A glob keeps its `**/`.
    fn shown(&self) -> String {
        match self {
            Matcher::Path { path, .. } => path.clone(),
            Matcher::Tail { tail, .. } => format!("**/{tail}"),
            Matcher::Suffix { suffix } => format!("*{suffix}"),
        }
    }
}

/// How to build the other side's path once a matcher has hit.
#[derive(Debug)]
enum Target {
    /// An explicit `left="a/b"`.
    Path(String),
    /// A `left-glob="**/tail"`; the prefix the glob bound goes in front of it.
    Tail(String),
    /// The same path as the right side — `retyped` and `redefined` do not move a value.
    Same,
}

impl Target {
    fn build(&self, hit: &Hit, right: &str) -> String {
        let base = match self {
            Target::Path(path) => path.clone(),
            Target::Tail(tail) if hit.prefix.is_empty() => tail.clone(),
            Target::Tail(tail) => format!("{}/{tail}", hit.prefix),
            Target::Same => return right.to_string(),
        };
        if hit.remainder.is_empty() {
            base
        } else {
            format!("{base}/{}", hit.remainder)
        }
    }

    fn shown(&self) -> String {
        match self {
            Target::Path(path) => path.clone(),
            Target::Tail(tail) => format!("**/{tail}"),
            Target::Same => "(same path)".to_string(),
        }
    }
}

// ===================================================================== rules

#[derive(Debug)]
struct Rule {
    id: String,
    rel: Rel,
    /// Right-hand matchers. More than one only for `split`, whose `<from right=…>`
    /// entries are two spellings of one left value.
    rights: Vec<Matcher>,
    /// Left-hand targets in precedence order. Empty for `right_only`.
    lefts: Vec<Target>,
    forward: Fidelity,
    /// `shape="int_1d:struct_array"` on a `retyped` rule: the container differs, which a
    /// path rewrite cannot express.
    shape: Option<String>,
    reason: String,
}

/// A `<redefine>`: same path, incomparable value. Keyed on the right path, so it never
/// competes with a structural rule for ownership.
#[derive(Debug)]
struct Redefine {
    matcher: Matcher,
    forward: Fidelity,
    reason: String,
}

// ===================================================================== the plan

/// The parts of a report line, kept apart rather than pre-joined so that `report.rs` can
/// colour each by its role. Composing the string here and picking it apart there would
/// mean parsing this module's own output format back out of it.
#[derive(Debug, Default)]
pub struct Note {
    /// The DD 4.1.1 path(s) the rule claims — what the program asked for.
    pub wanted: String,
    /// The DD 3.39.0 path(s) the value is read from. **Empty means there is no source** —
    /// the reader renders that, since "no source at all" and "this path here" are not the
    /// same kind of fact and should not look alike.
    pub source: String,
    /// Why the conversion is not exact.
    pub detail: String,
    /// The rule id, so a reader can find it in the map.
    pub rule: String,
}

impl Note {
    /// Uncoloured rendering, for a caller with no terminal in mind.
    pub fn plain(&self) -> String {
        format!(
            "{} <- {}: {} [{}]",
            self.wanted,
            self.source_or_nothing(),
            self.detail,
            self.rule
        )
    }

    /// The source paths, or the words that stand in for having none.
    pub fn source_or_nothing(&self) -> &str {
        if self.source.is_empty() {
            "(nothing)"
        } else {
            &self.source
        }
    }

    /// True when the map has no DD 3.39.0 path to offer at all.
    pub fn sourceless(&self) -> bool {
        self.source.is_empty()
    }
}

/// What the read path should do with one requested DD 4.1.1 path.
#[derive(Debug)]
pub struct Plan {
    /// DD 3.39.0 paths to try, in precedence order; the first one that comes back
    /// populated wins. **Empty means "read the path as given"** — which is what a
    /// right-only field does, and it lands on al-core's ordinary absent path rather than
    /// on a call this shim skipped. Never skipping the call is what keeps a caller's
    /// uninitialised scalar storage from being read back as garbage.
    pub sources: Vec<String>,
    /// Multiply the value by -1: COCOS 11 → 17. Only the IEEE-754 sign bit changes, so
    /// it is exactly invertible and needs no direction-specific handling.
    pub flip: bool,
    /// Overwrite the value with the DD invalid marker. The map calls this path
    /// unmappable, and handing back the DD3 number would be a silent wrong answer in
    /// units nothing converts.
    pub suppress: bool,
    pub verdict: Verdict,
    /// Dedup key for the report — the rule id, so a subtree rule claiming 37 paths says
    /// so once instead of 37 times.
    pub key: String,
    /// What to tell the reader, describing the *rule* rather than this instance.
    pub note: Note,
}

impl Plan {
    /// True when the plan asks for nothing at all, so the caller can skip it entirely.
    fn is_noop(&self) -> bool {
        self.sources.is_empty() && !self.flip && !self.suppress && !self.verdict.is_loss()
    }
}

// ===================================================================== the map

pub struct Map {
    pub ids: String,
    pub left_dd: String,
    pub right_dd: String,
    pub left_cocos: Option<i32>,
    pub right_cocos: Option<i32>,
    rules: Vec<Rule>,
    flips: HashSet<String>,
    redefines: Vec<Redefine>,
    /// Resolution is memoised on the requested path. A `get` walks the same ~1000 paths
    /// once per time slice, so after the first slice every lookup is a hash probe — the
    /// matcher scan never shows up next to the backend read it precedes.
    memo: Mutex<HashMap<String, Option<Arc<Plan>>>>,
    /// Anything the loader could not make sense of, reported once at startup instead of
    /// silently narrowing the map.
    pub complaints: Vec<String>,
}

impl Map {
    /// The compiled-in equilibrium map. Never fails: a map that will not parse yields one
    /// with no rules, which resolves everything to pass-through.
    pub fn load() -> Map {
        let mut map = Map {
            ids: String::new(),
            left_dd: String::new(),
            right_dd: String::new(),
            left_cocos: None,
            right_cocos: None,
            rules: Vec::new(),
            flips: HashSet::new(),
            redefines: Vec::new(),
            memo: Mutex::new(HashMap::new()),
            complaints: Vec::new(),
        };
        let mut includes = Vec::new();
        map.parse(MAP_XML, &mut includes);
        for href in includes {
            let name = href.rsplit('/').next().unwrap_or(href.as_str()).to_string();
            match INCLUDES.iter().find(|(file, _)| *file == name) {
                // A rule set is a bare <rule> list, so the same pass reads it; it cannot
                // itself carry <include>, and one nested would be reported below.
                Some((_, source)) => {
                    let mut nested = Vec::new();
                    map.parse(source, &mut nested);
                    for miss in nested {
                        map.complaints
                            .push(format!("nested include not resolved: {miss}"));
                    }
                }
                None => map
                    .complaints
                    .push(format!("include not compiled in: {href}")),
            }
        }
        if map.rules.is_empty() {
            map.complaints
                .push("no rules claim a right-hand path; every read passes through".into());
        }
        map
    }

    /// What to do with `right`, a DD 4.1.1 path relative to the IDS root. `None` means
    /// "forward it untouched", which is the answer for the ~399 identical paths and so is
    /// the case worth keeping allocation-free.
    pub fn resolve(&self, right: &str) -> Option<Arc<Plan>> {
        if let Ok(memo) = self.memo.lock() {
            if let Some(hit) = memo.get(right) {
                return hit.clone();
            }
        }
        let plan = self.resolve_uncached(right).map(Arc::new);
        if let Ok(mut memo) = self.memo.lock() {
            memo.insert(right.to_string(), plan.clone());
        }
        plan
    }

    fn resolve_uncached(&self, right: &str) -> Option<Plan> {
        let flip = self.flips.contains(right);

        // A value the map calls incomparable wins over any structural rule: there is no
        // factor that converts it, so the only honest answer is no answer.
        if let Some(redefine) = self
            .redefines
            .iter()
            .find(|r| r.forward == Fidelity::Unmappable && r.matcher.matches(right).is_some())
        {
            return Some(Plan {
                sources: Vec::new(),
                flip: false,
                suppress: true,
                verdict: Verdict::Refused,
                key: format!("redefine:{}", redefine.matcher.shown()),
                note: Note {
                    wanted: redefine.matcher.shown(),
                    source: String::new(),
                    detail: format!(
                        "value redefined, {}",
                        reason_or(&redefine.reason, "no factor converts it")
                    ),
                    rule: "transforms/redefine".to_string(),
                },
            });
        }

        let best = self.best_rule(right);
        let (rule, hit) = match best {
            Some(found) => found,
            None => {
                // Unclaimed: <default rel="identical"/>. Only a COCOS flip is left.
                return flip.then(|| Plan {
                    sources: Vec::new(),
                    flip: true,
                    suppress: false,
                    verdict: Verdict::Mapped,
                    key: "cocos".to_string(),
                    // Never printed: an exact conversion is counted, not reported.
                    note: Note::default(),
                });
            }
        };

        let sources: Vec<String> = rule
            .lefts
            .iter()
            .map(|target| target.build(&hit, right))
            .collect();

        // `retyped` with a container change is the one structural relationship a path
        // rewrite cannot express: DD3's flat INT_1D and DD4's array of identifier
        // structures hold the same integers behind different shapes.
        let reshaped = rule.rel == Rel::Retyped && rule.shape.is_some();

        let verdict = if rule.rel == Rel::RightOnly || reshaped {
            Verdict::Absent
        } else if rule.forward == Fidelity::Unmappable {
            Verdict::Refused
        } else if rule.forward == Fidelity::Exact {
            Verdict::Mapped
        } else {
            Verdict::Lossy
        };

        let plan = Plan {
            sources: match verdict {
                // Nothing on the left to read, or nothing readable: fall back to the DD4
                // path so al-core still takes its absent branch and initialises the
                // caller's buffer the way it always has.
                Verdict::Absent | Verdict::Refused => Vec::new(),
                _ => sources,
            },
            flip,
            suppress: verdict == Verdict::Refused,
            verdict,
            key: rule.id.clone(),
            note: rule.note(verdict),
        };
        (!plan.is_noop()).then_some(plan)
    }

    /// The most specific rule claiming `right`: most segments consumed, explicit before
    /// glob, and first in document order on a genuine tie (`validate.py` calls a real tie
    /// an error, so this only decides between forms of the same specificity).
    fn best_rule(&self, right: &str) -> Option<(&Rule, Hit)> {
        let mut best: Option<(&Rule, Hit)> = None;
        for rule in &self.rules {
            for matcher in &rule.rights {
                let Some(hit) = matcher.matches(right) else {
                    continue;
                };
                let better = match &best {
                    None => true,
                    Some((_, current)) => {
                        (hit.score, hit.explicit) > (current.score, current.explicit)
                    }
                };
                if better {
                    best = Some((rule, hit));
                }
            }
        }
        best
    }

    /// One line naming the map's two sides, for the report header.
    pub fn banner(&self) -> String {
        let cocos = |c: Option<i32>| match c {
            Some(n) => format!(" (COCOS {n})"),
            None => String::new(),
        };
        format!(
            "{}: reading DD {}{} data as DD {}{}",
            self.ids,
            self.left_dd,
            cocos(self.left_cocos),
            self.right_dd,
            cocos(self.right_cocos),
        )
    }

    pub fn rule_count(&self) -> usize {
        self.rules.len()
    }

    pub fn flip_count(&self) -> usize {
        self.flips.len()
    }
}

impl Rule {
    fn note(&self, verdict: Verdict) -> Note {
        Note {
            wanted: join(self.rights.iter().map(Matcher::shown)),
            source: if self.lefts.is_empty() {
                String::new()
            } else {
                join(self.lefts.iter().map(Target::shown))
            },
            detail: match (self.rel, verdict) {
                (Rel::RightOnly, _) => "no DD3 source".to_string(),
                (Rel::Retyped, Verdict::Absent) => format!(
                    "container shape {} cannot be rewritten as a path",
                    self.shape.as_deref().unwrap_or("changed")
                ),
                // Most fold rules carry no @reason, and a column of "see the map" says
                // nothing. What makes a merge lossy is derivable from the rule itself — how
                // many DD 3 spellings land on the one DD 4 path — so say that instead.
                _ => reason_or(&self.reason, &self.why()),
            },
            rule: self.id.clone(),
        }
    }

    /// What the `rel` alone says about the cost, for a rule whose `@reason` is absent.
    fn why(&self) -> String {
        match self.rel {
            Rel::Merged => format!(
                "{} DD3 spellings collapse to one DD4 path",
                self.lefts.len()
            ),
            Rel::Split => "one DD3 value feeds every DD4 spelling".to_string(),
            Rel::Moved => "relocated to a different parent".to_string(),
            Rel::Renamed => "renamed".to_string(),
            Rel::Retyped => "same path, different type".to_string(),
            _ => "see the map".to_string(),
        }
    }
}

fn join(parts: impl Iterator<Item = String>) -> String {
    parts.collect::<Vec<_>>().join(" | ")
}

fn reason_or(reason: &str, fallback: &str) -> String {
    if reason.is_empty() {
        fallback.to_string()
    } else {
        reason.to_string()
    }
}

// ===================================================================== parsing

/// A `<rule>` or `<redefine>` under construction: attributes arrive on the start tag,
/// `<from>` and `<fidelity>` as children.
struct Partial {
    id: String,
    rel: Option<Rel>,
    right: Option<Matcher>,
    left: Option<Target>,
    /// `(precedence, path)` from `<from left=…>` / `<from right=…>`.
    from_left: Vec<(u32, String)>,
    from_right: Vec<(u32, String)>,
    subtree: bool,
    shape: Option<String>,
    reason: String,
    forward: Option<Fidelity>,
    fidelity_reason: String,
}

impl Map {
    fn parse(&mut self, source: &str, includes: &mut Vec<String>) {
        let mut rule: Option<Partial> = None;
        let mut redefine: Option<Partial> = None;

        for event in Reader::new(source) {
            match &event {
                Event::Start { name, empty, .. } => match *name {
                    "ids-map" => {
                        if let Some(ids) = event.attr("ids") {
                            self.ids = ids.to_string();
                        }
                    }
                    "side" => self.read_side(&event),
                    "include" => {
                        if let Some(href) = event.attr("href") {
                            includes.push(href.to_string());
                        }
                    }
                    "flip" => {
                        if let Some(path) = event.attr("path") {
                            self.flips.insert(path.to_string());
                        }
                    }
                    "scale" => self.complaints.push(
                        "<scale> is not implemented on the read path; the value passes through"
                            .into(),
                    ),
                    "rule" | "redefine" => {
                        let partial = Partial::start(&event);
                        if *empty {
                            self.finish(name, partial);
                        } else if *name == "rule" {
                            rule = Some(partial);
                        } else {
                            redefine = Some(partial);
                        }
                    }
                    "from" => {
                        if let Some(open) = rule.as_mut() {
                            open.read_from(&event);
                        }
                    }
                    "fidelity" => {
                        let open = rule.as_mut().or(redefine.as_mut());
                        if let Some(open) = open {
                            open.read_fidelity(&event);
                        }
                    }
                    _ => {}
                },
                Event::End { name } => match *name {
                    "rule" => {
                        if let Some(open) = rule.take() {
                            self.finish("rule", open);
                        }
                    }
                    "redefine" => {
                        if let Some(open) = redefine.take() {
                            self.finish("redefine", open);
                        }
                    }
                    _ => {}
                },
            }
        }
    }

    fn read_side(&mut self, event: &Event) {
        let dd = event.attr("dd").unwrap_or_default().to_string();
        let cocos = event.attr("cocos").and_then(|c| c.trim().parse::<i32>().ok());
        match event.attr("id") {
            Some("left") => {
                self.left_dd = dd;
                self.left_cocos = cocos;
            }
            Some("right") => {
                self.right_dd = dd;
                self.right_cocos = cocos;
            }
            _ => self.complaints.push("<side> without a usable id".into()),
        }
    }

    fn finish(&mut self, element: &str, partial: Partial) {
        if element == "redefine" {
            match partial.into_redefine() {
                Some(redefine) => self.redefines.push(redefine),
                None => self
                    .complaints
                    .push("<redefine> without a path or glob, dropped".into()),
            }
            return;
        }
        match partial.into_rule() {
            Ok(Some(rule)) => self.rules.push(rule),
            // A rule with nothing on the right cannot be reached from this direction.
            Ok(None) => {}
            Err(why) => self.complaints.push(why),
        }
    }
}

impl Partial {
    fn start(event: &Event) -> Partial {
        let subtree = event.attr("subtree") == Some("yes");
        let matcher = |explicit: Option<&str>, glob: Option<&str>, suffix: Option<&str>| {
            if let Some(path) = explicit {
                return Some(Matcher::Path {
                    path: path.to_string(),
                    subtree,
                });
            }
            if let Some(glob) = glob {
                return Some(Matcher::Tail {
                    tail: glob.trim_start_matches("**/").to_string(),
                    subtree,
                });
            }
            suffix.map(|suffix| Matcher::Suffix {
                suffix: suffix.to_string(),
            })
        };
        let target = |explicit: Option<&str>, glob: Option<&str>| {
            if let Some(path) = explicit {
                return Some(Target::Path(path.to_string()));
            }
            glob.map(|glob| Target::Tail(glob.trim_start_matches("**/").to_string()))
        };

        Partial {
            id: event.attr("id").unwrap_or_default().to_string(),
            rel: event.attr("rel").and_then(Rel::parse),
            // <redefine> spells its matcher `path`/`glob` rather than `right`/`right-glob`.
            right: matcher(
                event.attr("right").or_else(|| event.attr("path")),
                event.attr("right-glob").or_else(|| event.attr("glob")),
                event.attr("right-suffix"),
            ),
            left: target(event.attr("left"), event.attr("left-glob")),
            from_left: Vec::new(),
            from_right: Vec::new(),
            subtree,
            shape: event.attr("shape").map(str::to_string),
            reason: event.attr("reason").unwrap_or_default().to_string(),
            forward: None,
            fidelity_reason: String::new(),
        }
    }

    fn read_from(&mut self, event: &Event) {
        // Absent precedence sorts last; the XSD makes it a positive integer when present.
        let precedence = event
            .attr("precedence")
            .and_then(|p| p.trim().parse::<u32>().ok())
            .unwrap_or(u32::MAX);
        if let Some(left) = event.attr("left") {
            self.from_left.push((precedence, left.to_string()));
        }
        if let Some(right) = event.attr("right") {
            self.from_right.push((precedence, right.to_string()));
        }
    }

    fn read_fidelity(&mut self, event: &Event) {
        self.forward = event.attr("forward").and_then(Fidelity::parse);
        if let Some(reason) = event.attr("reason") {
            self.fidelity_reason = reason.to_string();
        }
    }

    fn describe(&self) -> String {
        if self.id.is_empty() {
            "<rule> with no id".to_string()
        } else {
            format!("rule {}", self.id)
        }
    }

    /// `Ok(None)` for a rule this direction cannot reach — one with no right-hand path.
    fn into_rule(self) -> Result<Option<Rule>, String> {
        let described = self.describe();
        let Partial {
            id,
            rel,
            right,
            left,
            mut from_left,
            mut from_right,
            subtree,
            shape,
            reason,
            forward,
            fidelity_reason,
        } = self;

        let Some(rel) = rel else {
            return Err(format!("{described}: unknown rel, dropped"));
        };
        if rel == Rel::LeftOnly {
            return Ok(None);
        }

        from_left.sort_by_key(|(precedence, _)| *precedence);
        from_right.sort_by_key(|(precedence, _)| *precedence);

        // `split` is the one rel with several right-hand paths: two DD4 spellings fed
        // from one DD3 value, so reading either reads the same left path.
        let rights: Vec<Matcher> = if rel == Rel::Split {
            from_right
                .into_iter()
                .map(|(_, path)| Matcher::Path { path, subtree })
                .collect()
        } else {
            right.into_iter().collect()
        };
        if rights.is_empty() {
            return Err(format!(
                "{described}: rel={rel:?} with nothing on the right, dropped"
            ));
        }

        // `merged` is the one rel with several left-hand paths, in precedence order.
        let lefts: Vec<Target> = match rel {
            Rel::Merged => from_left.into_iter().map(|(_, p)| Target::Path(p)).collect(),
            Rel::RightOnly => Vec::new(),
            _ => match left {
                Some(target) => vec![target],
                // `retyped` and `redefined` name the same path on both sides; so does a
                // rule that spells only the right side out.
                None => vec![Target::Same],
            },
        };
        if lefts.is_empty() && rel != Rel::RightOnly {
            return Err(format!(
                "{described}: rel={rel:?} with nothing on the left, dropped"
            ));
        }

        Ok(Some(Rule {
            id,
            rel,
            rights,
            lefts,
            // A missing <fidelity> is schema-invalid. Assuming Exact would promise more
            // than the map states, so assume the conversion costs something.
            forward: forward.unwrap_or(Fidelity::Lossy),
            shape,
            reason: if fidelity_reason.is_empty() {
                reason
            } else {
                fidelity_reason
            },
        }))
    }

    fn into_redefine(self) -> Option<Redefine> {
        let reason = if self.fidelity_reason.is_empty() {
            self.reason
        } else {
            self.fidelity_reason
        };
        Some(Redefine {
            matcher: self.right?,
            forward: self.forward.unwrap_or(Fidelity::Unmappable),
            reason,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn map() -> Map {
        Map::load()
    }

    #[test]
    fn the_compiled_in_map_loads_clean() {
        let map = map();
        assert_eq!(map.complaints, Vec::<String>::new());
        assert_eq!(map.ids, "equilibrium");
        assert_eq!(map.left_dd, "3.39.0");
        assert_eq!(map.right_dd, "4.1.1");
        assert_eq!(map.left_cocos, Some(11));
        assert_eq!(map.right_cocos, Some(17));
        assert_eq!(map.flip_count(), 32, "the map declares 32 COCOS sign flips");
        // 53 rules in total per dd-maps/README.md, of which the 26 left_only ones cannot
        // be reached from the right and are dropped at load.
        assert_eq!(map.rule_count(), 27);
    }

    /// The ~399 paths identical in both versions must cost nothing: no plan, no
    /// allocation, no rewrite.
    #[test]
    fn an_identical_path_resolves_to_nothing() {
        let map = map();
        assert!(map.resolve("time_slice/profiles_1d/pressure").is_none());
        assert!(map.resolve("vacuum_toroidal_field/r0").is_none());
        assert!(map.resolve("ids_properties/comment").is_none());
        // A DD3-only path is not something a DD4 program asks for, but if it did, the
        // left_only rules are gone and it falls through untouched.
        assert!(map.resolve("time_slice/boundary_separatrix/elongation").is_none());
    }

    #[test]
    fn a_rename_rewrites_the_path_exactly() {
        let plan = map()
            .resolve("time_slice/global_quantities/beta_tor_norm")
            .expect("beta_tor_norm is renamed");
        assert_eq!(
            plan.sources,
            vec!["time_slice/global_quantities/beta_normal"]
        );
        assert_eq!(plan.verdict, Verdict::Mapped);
        assert!(!plan.flip && !plan.suppress);
    }

    #[test]
    fn a_move_carries_its_subtree() {
        let plan = map()
            .resolve("time_slice/boundary/closest_wall_point/r")
            .expect("closest_wall_point moved out of boundary_separatrix");
        assert_eq!(
            plan.sources,
            vec!["time_slice/boundary_separatrix/closest_wall_point/r"]
        );
        assert_eq!(plan.verdict, Verdict::Mapped);
    }

    /// `move-gap` and `drop-gap-identifier` overlap by design, and the map's comment says
    /// the more specific one wins. `drop-gap-identifier` is left_only so it never reaches
    /// this direction — what is being pinned is that the surviving rule still moves the
    /// rest of the subtree.
    #[test]
    fn a_lossy_move_reports_the_part_that_is_dropped() {
        let plan = map()
            .resolve("time_slice/boundary/gap/value")
            .expect("gap moved out of boundary_separatrix");
        assert_eq!(
            plan.sources,
            vec!["time_slice/boundary_separatrix/gap/value"]
        );
        assert_eq!(plan.verdict, Verdict::Lossy);
        assert!(plan.note.plain().contains("move-gap"));
        assert!(plan.note.plain().contains("identifier"), "line was: {}", plan.note.plain());
    }

    /// The heart of the 3.39.0 → 4.1.1 step: DD3 ships both spellings, so the read tries
    /// the modern one first and falls back to the obsolescent alias.
    #[test]
    fn a_merge_offers_its_sources_in_precedence_order() {
        let map = map();

        let plan = map
            .resolve("time_slice/profiles_1d/j_phi")
            .expect("j_phi is a merge target");
        assert_eq!(
            plan.sources,
            vec![
                "time_slice/profiles_1d/j_phi",
                "time_slice/profiles_1d/j_tor"
            ]
        );
        assert_eq!(plan.verdict, Verdict::Lossy);
        assert!(plan.flip, "profiles_1d/j_phi also takes the COCOS flip");

        // Three-way, oldest last.
        let plan = map
            .resolve("time_slice/profiles_2d/b_field_phi")
            .expect("b_field_phi folds three DD3 spellings");
        assert_eq!(
            plan.sources,
            vec![
                "time_slice/profiles_2d/b_field_phi",
                "time_slice/profiles_2d/b_field_tor",
                "time_slice/profiles_2d/b_tor"
            ]
        );

        // A merge with subtree="yes" carries the descendant along each source.
        let plan = map
            .resolve("time_slice/constraints/j_phi/measured")
            .expect("constraints/j_phi is a subtree merge");
        assert_eq!(
            plan.sources,
            vec![
                "time_slice/constraints/j_phi/measured",
                "time_slice/constraints/j_tor/measured"
            ]
        );
    }

    /// Both DD4 spellings of the flux at the magnetic axis read the one DD3 path, and
    /// both take the sign flip.
    #[test]
    fn a_split_feeds_both_right_paths_from_one_left_path() {
        let map = map();
        for right in [
            "time_slice/global_quantities/psi_axis",
            "time_slice/global_quantities/psi_magnetic_axis",
        ] {
            let plan = map.resolve(right).expect("both are split targets");
            assert_eq!(
                plan.sources,
                vec!["time_slice/global_quantities/psi_axis"],
                "{right}"
            );
            assert!(plan.flip, "{right} takes the COCOS flip");
            assert_eq!(plan.verdict, Verdict::Mapped);
        }
    }

    #[test]
    fn a_right_only_path_has_no_source_and_is_reported() {
        let plan = map()
            .resolve("time_slice/contour_tree/critical_point/r")
            .expect("contour_tree is new in DD4");
        assert!(plan.sources.is_empty(), "nothing on the left to read");
        assert!(!plan.suppress, "absent is al-core's own answer, not ours");
        assert_eq!(plan.verdict, Verdict::Absent);
        assert!(plan.note.plain().contains("new-contour-tree"));
    }

    /// m → m⁻² is a dimensional redefinition: chi-squared is now normalised by the
    /// measurement variance, and no factor inverts that. Returning the DD3 number would
    /// be a silent wrong answer, so the value is suppressed.
    #[test]
    fn a_redefined_value_is_refused_rather_than_guessed() {
        let map = map();
        for right in [
            "time_slice/constraints/strike_point/chi_squared_r",
            "time_slice/constraints/x_point/chi_squared_z",
        ] {
            let plan = map.resolve(right).expect("chi_squared is redefined");
            assert_eq!(plan.verdict, Verdict::Refused, "{right}");
            assert!(plan.suppress, "{right}");
            assert!(plan.sources.is_empty(), "{right}");
            assert!(plan.note.plain().contains("variance"), "line was: {}", plan.note.plain());
        }
        // Its siblings are ordinary paths and must not be caught by the same rule.
        assert!(map
            .resolve("time_slice/constraints/strike_point/position_measured/r")
            .is_none());
    }

    /// `**/bpol_probe` binds its prefix on both sides, so the rename works wherever the
    /// structure appears — and it is the AoS whose absence made a DD4 program reading a
    /// DD3 entry walk off the end of an unallocated array.
    #[test]
    fn a_glob_rename_binds_the_same_prefix_on_both_sides() {
        let map = map();

        let plan = map
            .resolve("time_slice/constraints/b_field_pol_probe")
            .expect("bpol_probe was renamed");
        assert_eq!(plan.sources, vec!["time_slice/constraints/bpol_probe"]);
        assert_eq!(plan.verdict, Verdict::Mapped);

        // subtree="yes", so descendants come along.
        let plan = map
            .resolve("time_slice/constraints/b_field_pol_probe/measured")
            .expect("the subtree comes along");
        assert_eq!(
            plan.sources,
            vec!["time_slice/constraints/bpol_probe/measured"]
        );
    }

    /// DD3 stored a flat INT_1D of coordinate-type codes; DD4 stores an array of
    /// identifier structures. The integers are the same, but no path rewrite turns one
    /// container into the other, so the read reports it rather than pretending.
    #[test]
    fn a_container_reshape_is_reported_not_rewritten() {
        let plan = map()
            .resolve("grids_ggd/grid/space/coordinates_type")
            .expect("coordinates_type is retyped");
        assert_eq!(plan.verdict, Verdict::Absent);
        assert!(plan.sources.is_empty());
        assert!(plan.note.plain().contains("int_1d:struct_array"), "{}", plan.note.plain());
    }

    /// A path that only appears in <transforms> gets a plan carrying nothing but the
    /// flip, and is not reported as a loss — the sign change is exactly invertible.
    #[test]
    fn a_cocos_flip_alone_is_an_exact_conversion() {
        let plan = map()
            .resolve("time_slice/global_quantities/ip")
            .expect("ip takes the sign flip");
        assert!(plan.flip);
        assert!(plan.sources.is_empty(), "the path itself is unchanged");
        assert_eq!(plan.verdict, Verdict::Mapped);
        assert!(!plan.verdict.is_loss());
    }

    #[test]
    fn resolution_is_memoised_and_stable() {
        let map = map();
        let first = map.resolve("time_slice/profiles_1d/j_phi").expect("a plan");
        let second = map.resolve("time_slice/profiles_1d/j_phi").expect("a plan");
        assert!(
            Arc::ptr_eq(&first, &second),
            "the second lookup should hand back the memoised plan"
        );
        assert!(map.resolve("time_slice/profiles_1d/pressure").is_none());
        assert!(map.resolve("time_slice/profiles_1d/pressure").is_none());
    }

    #[test]
    fn a_glob_matches_whole_segments_only() {
        let matcher = Matcher::Tail {
            tail: "bpol_probe".to_string(),
            subtree: true,
        };
        assert!(matcher.matches("constraints/bpol_probe").is_some());
        assert!(matcher.matches("constraints/bpol_probe/measured").is_some());
        assert!(matcher.matches("bpol_probe").is_some());
        assert!(
            matcher.matches("constraints/xbpol_probe").is_none(),
            "a mid-segment match would rename an unrelated field"
        );
        assert!(matcher.matches("constraints/bpol_probes").is_none());
    }
}
