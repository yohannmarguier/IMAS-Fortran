#!/usr/bin/env python3
"""Validate an IMAS DD conversion map.

Three checks, in order:

1. Grammar     -- XSD validation via xmllint (vocabularies, uniqueness).
2. Coverage    -- every path in both inventories is claimed by exactly one
                  rule, in both directions. This is what proves the map is
                  complete and non-overlapping.
3. Consistency -- the declared <coverage> verdicts match what the rules imply.

Stdlib only, plus xmllint if present. Run with --write-coverage to refresh the
generated <coverage> elements in place.

    python3 dd-maps/validate.py dd-maps/equilibrium/3.39.0--4.1.1.xml
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# Ordered worst-last, so max() gives the worst verdict in a set.
FIDELITY_ORDER = ["exact", "approximate", "lossy", "unmappable"]


def worst(values):
    """Worst (highest-index) fidelity in an iterable; 'exact' when empty."""
    seen = [v for v in values if v in FIDELITY_ORDER]
    if not seen:
        return "exact"
    return max(seen, key=FIDELITY_ORDER.index)


class Rule:
    """One structural relationship, with its expansion against an inventory."""

    def __init__(self, elem: ET.Element, origin: str):
        self.elem = elem
        self.origin = origin
        self.id = elem.get("id") or "<unnamed>"
        self.rel = elem.get("rel")
        self.left = elem.get("left")
        self.right = elem.get("right")
        self.left_glob = elem.get("left-glob")
        self.right_glob = elem.get("right-glob")
        self.left_suffix = elem.get("left-suffix")
        self.right_suffix = elem.get("right-suffix")
        self.subtree = elem.get("subtree") == "yes"
        self.decision = elem.get("decision") == "yes"
        self.note = (elem.findtext("note") or "").strip()

        fid = elem.find("fidelity")
        self.forward = fid.get("forward") if fid is not None else None
        self.reverse = fid.get("reverse") if fid is not None else None

        # <from left=.../> for merged, <from right=.../> for split
        self.from_left = [f.get("left") for f in elem.findall("from") if f.get("left")]
        self.from_right = [f.get("right") for f in elem.findall("from") if f.get("right")]

    # -- matching ---------------------------------------------------------

    def _match(self, path, explicit, glob, suffix, extra):
        """Return the length of the matched prefix, or None if no match.

        Longer match == more specific, which is how precedence is resolved.
        """
        candidates = list(extra)
        if explicit:
            candidates.append(explicit)

        for cand in candidates:
            if path == cand:
                return len(cand)
            if self.subtree and path.startswith(cand + "/"):
                return len(cand)

        if glob and glob.startswith("**/"):
            tail = glob[3:]
            # `**/j_tor` matches any path whose trailing segments are `j_tor`
            if path == tail or path.endswith("/" + tail):
                return len(path)
            if self.subtree:
                idx = path.find("/" + tail + "/")
                if idx != -1:
                    return idx + 1 + len(tail)
                if path.startswith(tail + "/"):
                    return len(tail)

        if suffix:
            last = path.rsplit("/", 1)[-1]
            if last.endswith(suffix):
                return len(path)

        return None

    def match_left(self, path):
        return self._match(path, self.left, self.left_glob, self.left_suffix,
                           self.from_left)

    def match_right(self, path):
        return self._match(path, self.right, self.right_glob, self.right_suffix,
                           self.from_right)

    # -- target resolution ------------------------------------------------

    def _anchor(self, path, explicit, glob, extra):
        """Split `path` into (matched_anchor, remainder) for this rule.

        The anchor is the part the rule names; the remainder is everything
        below it. Reattaching the remainder to the other side is how one rule
        converts a whole family of paths.
        """
        for cand in list(extra) + ([explicit] if explicit else []):
            if path == cand:
                return cand, ""
            if self.subtree and path.startswith(cand + "/"):
                return cand, path[len(cand):]
        if glob and glob.startswith("**/"):
            tail = glob[3:]
            if path == tail:
                return "", ""
            if path.endswith("/" + tail):
                return path[:-len(tail) - 1], ""
            if self.subtree:
                needle = "/" + tail + "/"
                idx = path.find(needle)
                if idx != -1:
                    return path[:idx], path[idx + 1 + len(tail):]
                if path.startswith(tail + "/"):
                    return "", path[len(tail):]
        return None, None

    def targets(self, path, direction):
        """Where `path` goes in the other version. Returns a list, because
        `split` produces several. Empty list means the value is dropped."""
        if direction == "forward":
            anchor, rest = self._anchor(path, self.left, self.left_glob,
                                        self.from_left)
            named, named_glob, alts = self.right, self.right_glob, self.from_right
        else:
            anchor, rest = self._anchor(path, self.right, self.right_glob,
                                        self.from_right)
            named, named_glob, alts = self.left, self.left_glob, self.from_left

        if anchor is None:                       # suffix rules only
            return [path] if self.rel == "identical" else []

        drop = ("left_only" if direction == "forward" else "right_only")
        if self.rel == drop:
            return []

        def build(target_anchor):
            if named_glob and named_glob.startswith("**/"):
                tail = named_glob[3:]
                return (anchor + "/" + tail if anchor else tail) + rest
            return (target_anchor or "") + rest

        if self.rel == "split" and direction == "forward":
            return [build(a) for a in alts]
        if self.rel == "split" and direction == "reverse":
            return [build(named)]
        if self.rel == "merged" and direction == "reverse":
            # only the highest-precedence source is written back
            return [build(alts[0] if alts else named)]
        return [build(named)]


def load_rules(map_path: Path):
    """Parse the map plus every <include>, returning (root, tree, rules)."""
    tree = ET.parse(map_path)
    root = tree.getroot()
    rules = []

    for inc in root.findall("include"):
        href = inc.get("href")
        inc_path = (map_path.parent / href).resolve()
        if not inc_path.exists():
            print(f"ERROR: include not found: {href}", file=sys.stderr)
            sys.exit(2)
        inc_root = ET.parse(inc_path).getroot()
        for r in inc_root.findall("rule"):
            rules.append(Rule(r, href))

    rules_elem = root.find("rules")
    if rules_elem is not None:
        for r in rules_elem.findall("rule"):
            rules.append(Rule(r, map_path.name))

    return root, tree, rules


def read_inventory(map_path: Path, root: ET.Element, side_id: str):
    side = next(s for s in root.findall("side") if s.get("id") == side_id)
    rel = side.get("inventory")
    if not rel:
        return side, []
    inv = (map_path.parent / rel).resolve()
    paths = [ln.strip() for ln in inv.read_text().splitlines() if ln.strip()]
    return side, paths


def claim(paths, rules, which):
    """Assign each path to its most specific matching rule.

    Returns (claims, ambiguous) where claims maps path -> rule (or None if
    unclaimed) and ambiguous lists paths matched equally well by >1 rule.
    """
    claims = {}
    ambiguous = []
    for path in paths:
        best_len, best_rules = None, []
        for rule in rules:
            n = rule.match_left(path) if which == "left" else rule.match_right(path)
            if n is None:
                continue
            if best_len is None or n > best_len:
                best_len, best_rules = n, [rule]
            elif n == best_len:
                best_rules.append(rule)
        if not best_rules:
            claims[path] = None
        elif len(best_rules) > 1:
            claims[path] = best_rules[0]
            ambiguous.append((path, [r.id for r in best_rules]))
        else:
            claims[path] = best_rules[0]
    return claims, ambiguous


def run_xmllint(map_path: Path, schema: Path) -> bool:
    if not shutil.which("xmllint"):
        print("  xmllint not found - skipping grammar check")
        return True
    proc = subprocess.run(
        ["xmllint", "--noout", "--schema", str(schema), str(map_path)],
        capture_output=True, text=True,
    )
    if proc.returncode == 0:
        print("  grammar OK")
        return True
    print(proc.stderr.strip())
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("map", type=Path)
    ap.add_argument("--write-coverage", action="store_true",
                    help="rewrite the generated <coverage> elements in place")
    ap.add_argument("--list-rules", action="store_true",
                    help="list every rule with the number of paths it claims, "
                         "and explain each version-exclusive path by its rel")
    ap.add_argument("--explain", metavar="PATH",
                    help="show the full engine lookup for one IDS-relative "
                         "path: matching rule, target path(s), transform and "
                         "fidelity, in both directions")
    ap.add_argument("--expand", metavar="RULE_ID",
                    help="show every path a single rule converts, with the "
                         "target it produces")
    args = ap.parse_args()

    map_path = args.map.resolve()
    schema = map_path.parent.parent / "schema" / "ids-map.xsd"

    print(f"== {map_path.name}")
    ok = True

    # 1. grammar -------------------------------------------------------
    print("-- grammar")
    if not run_xmllint(map_path, schema):
        ok = False

    root, tree, rules = load_rules(map_path)
    left_side, left_paths = read_inventory(map_path, root, "left")
    right_side, right_paths = read_inventory(map_path, root, "right")
    left_set, right_set = set(left_paths), set(right_paths)

    print(f"-- inventories: left {left_side.get('dd')} = {len(left_paths)} paths, "
          f"right {right_side.get('dd')} = {len(right_paths)} paths")
    print(f"   in both: {len(left_set & right_set)}  "
          f"left-only: {len(left_set - right_set)}  "
          f"right-only: {len(right_set - left_set)}")
    n_inc = sum(1 for r in rules if r.origin != map_path.name)
    print(f"-- rules: {len(rules)} ({len(rules) - n_inc} in this file, "
          f"{n_inc} pulled in by <include>)")
    by_rel = {}
    for r in rules:
        by_rel.setdefault(r.rel, []).append(r)
    # Rule count, NOT path count: subtree="yes" expands one rule into a family,
    # so these numbers are deliberately far smaller than the path totals below.
    for rel in sorted(by_rel, key=lambda k: -len(by_rel[k])):
        own = sum(1 for r in by_rel[rel] if r.origin == map_path.name)
        extra = "" if own == len(by_rel[rel]) else f" ({own} here + {len(by_rel[rel]) - own} included)"
        print(f"   {len(by_rel[rel]):3d} {rel} rules{extra}")

    # 2. coverage ------------------------------------------------------
    print("-- coverage")
    lclaims, lamb = claim(left_paths, rules, "left")
    rclaims, ramb = claim(right_paths, rules, "right")

    default = root.find("default")
    default_rel = default.get("rel") if default is not None else None

    # Unclaimed is only acceptable when the path exists on both sides and a
    # <default> covers it.
    unclaimed_left = [p for p, r in lclaims.items() if r is None]
    unclaimed_right = [p for p, r in rclaims.items() if r is None]

    bad_left = [p for p in unclaimed_left if p not in right_set]
    bad_right = [p for p in unclaimed_right if p not in left_set]

    defaulted_left = [p for p in unclaimed_left if p in right_set]
    defaulted_right = [p for p in unclaimed_right if p in left_set]

    if default_rel is None and (defaulted_left or defaulted_right):
        print(f"  ERROR: no <default> but {len(defaulted_left)} left / "
              f"{len(defaulted_right)} right paths are unclaimed")
        ok = False
    else:
        print(f"  claimed by rules: left {len(left_paths) - len(unclaimed_left)}, "
              f"right {len(right_paths) - len(unclaimed_right)}")
        print(f"  fell through to <default rel=\"{default_rel}\">: "
              f"left {len(defaulted_left)}, right {len(defaulted_right)}")

    if bad_left:
        ok = False
        print(f"  ERROR: {len(bad_left)} left-only path(s) with no rule "
              f"(engine would silently drop them):")
        for p in sorted(bad_left)[:25]:
            print(f"    {p}")
        if len(bad_left) > 25:
            print(f"    ... and {len(bad_left) - 25} more")

    if bad_right:
        ok = False
        print(f"  ERROR: {len(bad_right)} right-only path(s) with no rule "
              f"(engine would not know they are new):")
        for p in sorted(bad_right)[:25]:
            print(f"    {p}")
        if len(bad_right) > 25:
            print(f"    ... and {len(bad_right) - 25} more")

    for label, amb in (("left", lamb), ("right", ramb)):
        if amb:
            ok = False
            print(f"  ERROR: {len(amb)} {label} path(s) matched equally by "
                  f"multiple rules - precedence is undefined:")
            for p, ids in amb[:15]:
                print(f"    {p}  <- {', '.join(ids)}")

    flip_set = {f.get("path") for f in root.findall("transforms/cocos/flip")}
    redefine_set = {rd.get("path") or rd.get("glob")
                    for rd in root.findall("transforms/redefine")}

    def explain(path, direction):
        """One engine lookup, printed. Mirrors what a conversion engine does."""
        claims = lclaims if direction == "forward" else rclaims
        inv = left_set if direction == "forward" else right_set
        side = (left_side, right_side) if direction == "forward" \
            else (right_side, left_side)
        print(f"  {direction}: {side[0].get('dd')} -> {side[1].get('dd')}")
        if path not in inv:
            print(f"    path not in the {side[0].get('dd')} inventory")
            return
        rule = claims.get(path)
        if rule is None:
            print(f"    rule      <default rel=\"{default_rel}\">")
            print(f"    target    {path}")
            fid = "exact"
        else:
            anchor, rest = rule._anchor(
                path, rule.left if direction == "forward" else rule.right,
                rule.left_glob if direction == "forward" else rule.right_glob,
                rule.from_left if direction == "forward" else rule.from_right)
            print(f"    rule      [{rule.id}] rel=\"{rule.rel}\""
                  + (" subtree" if rule.subtree else ""))
            if anchor is not None and rest:
                print(f"    anchor    {anchor or '(glob prefix)'}"
                      f"   + remainder {rest}")
            tgts = rule.targets(path, direction)
            if not tgts:
                print(f"    target    (none - value is dropped)")
            for t in tgts:
                print(f"    target    {t}")
            fid = rule.forward if direction == "forward" else rule.reverse
        tgts = [path] if rule is None else rule.targets(path, direction)
        for t in tgts:
            key = t if direction == "forward" else path
            if key in flip_set:
                print(f"    transform x -1  (COCOS 11->17, on {key})")
            if key in redefine_set:
                print(f"    transform REDEFINED units, no factor exists")
                fid = "unmappable"
        verdict = {"exact": "copy it",
                   "approximate": "copy, warn about precision",
                   "lossy": "convert, but warn - data is discarded",
                   "unmappable": "REFUSE - engine must report and skip"}
        print(f"    fidelity  {fid}  -> {verdict.get(fid, '?')}")

    if args.explain:
        print(f"-- lookup for {args.explain}")
        explain(args.explain, "forward")
        explain(args.explain, "reverse")

    if args.expand:
        target_rule = next((r for r in rules if r.id == args.expand), None)
        if target_rule is None:
            print(f"-- no rule with id \"{args.expand}\"")
        else:
            claimed = [p for p, rr in lclaims.items() if rr is target_rule]
            print(f"-- rule [{target_rule.id}] rel=\"{target_rule.rel}\""
                  f"{' subtree' if target_rule.subtree else ''} converts "
                  f"{len(claimed)} left path(s):")
            for p in sorted(claimed):
                tg = target_rule.targets(p, "forward")
                arrow = " -> ".join(tg) if tg else "(dropped)"
                print(f"    {p}\n      -> {arrow}")

    if args.list_rules:
        print("-- each rule, and how many INVENTORY PATHS it claims "
              "(L=left, R=right)")
        for rel in sorted(by_rel, key=lambda k: -len(by_rel[k])):
            npl = sum(1 for p, rr in lclaims.items() if rr and rr.rel == rel)
            npr = sum(1 for p, rr in rclaims.items() if rr and rr.rel == rel)
            print(f"  rel=\"{rel}\": {len(by_rel[rel])} rules "
                  f"-> {npl} left paths, {npr} right paths")
            for r in by_rel[rel]:
                nl = sum(1 for p, rr in lclaims.items() if rr is r)
                nr = sum(1 for p, rr in rclaims.items() if rr is r)
                target = (r.left or r.right or r.left_glob or r.right_glob
                          or r.left_suffix or r.right_suffix or "?")
                origin = "" if r.origin == map_path.name else f"  [{r.origin}]"
                print(f"    L{nl:4d} R{nr:4d}  {r.id:38s} {target}{origin}")

        # "present in only one version" is NOT the same as left_only/right_only:
        # renames, moves and merges also produce version-exclusive paths.
        for label, excl, claims in (
                ("only in " + left_side.get("dd"), left_set - right_set, lclaims),
                ("only in " + right_side.get("dd"), right_set - left_set, rclaims)):
            agg = {}
            for p in excl:
                rel = claims[p].rel if claims[p] else "(default)"
                agg[rel] = agg.get(rel, 0) + 1
            print(f"-- {len(excl)} paths {label}, by the rel that explains them")
            for rel, n in sorted(agg.items(), key=lambda kv: -kv[1]):
                print(f"    {n:4d}  {rel}")

    # transforms must target paths that exist on the right
    print("-- transforms")
    flips = [f.get("path") for f in root.findall("transforms/cocos/flip")]
    stray = [p for p in flips if p not in right_set]
    print(f"  cocos flips: {len(flips)}")
    if stray:
        ok = False
        print(f"  ERROR: {len(stray)} flip(s) target a path absent from the "
              f"right inventory:")
        for p in stray:
            print(f"    {p}")
    dupes = {p for p in flips if flips.count(p) > 1}
    if dupes:
        ok = False
        print(f"  ERROR: duplicated flip path(s) - sign would be applied twice: "
              f"{', '.join(sorted(dupes))}")

    redefs = root.findall("transforms/redefine")
    print(f"  redefinitions: {len(redefs)}")

    # 3. coverage verdicts --------------------------------------------
    print("-- declared coverage vs computed")
    per_scope_fwd, per_scope_rev = {}, {}

    # A path is a structure if some other path extends it. Only structures are
    # worth a coverage verdict; a leaf's verdict is just its own rule.
    structures = set()
    for p in left_paths + right_paths:
        parts = p.split("/")
        for i in range(1, len(parts)):
            structures.add("/".join(parts[:i]))

    def scopes_of(path):
        """Report at depth 1 and depth 2, so `time_slice` does not collapse
        500 paths into a single verdict. An engine can then convert
        profiles_1d cleanly while refusing only boundary."""
        parts = path.split("/")
        out = [parts[0]]
        if len(parts) > 2 or (len(parts) == 2 and path in structures):
            depth2 = "/".join(parts[:2])
            if depth2 in structures:
                out.append(depth2)
        return out

    def record(path, fwd, rev):
        for scope in scopes_of(path):
            per_scope_fwd.setdefault(scope, []).append(fwd)
            per_scope_rev.setdefault(scope, []).append(rev)

    for p, r in lclaims.items():
        record(p, r.forward if r else "exact", r.reverse if r else "exact")
    for p, r in rclaims.items():
        record(p, r.forward if r else "exact", r.reverse if r else "exact")
    for rd in redefs:
        target = rd.get("path") or rd.get("glob") or ""
        fid = rd.find("fidelity")
        if target and fid is not None:
            record(target, fid.get("forward"), fid.get("reverse"))

    computed = {s: (worst(per_scope_fwd[s]), worst(per_scope_rev[s]))
                for s in per_scope_fwd}
    # `/` is the whole-IDS rollup: the worst verdict anywhere in the map.
    computed["/"] = (worst([f for v in per_scope_fwd.values() for f in v]),
                     worst([r for v in per_scope_rev.values() for r in v]))

    declared = {c.get("scope"): (c.get("forward"), c.get("reverse"))
                for c in root.findall("coverage")}

    for scope in sorted(computed, key=lambda s: (s != "/", s)):
        cf, cr = computed[scope]
        if scope in declared:
            df, dr = declared[scope]
            flag = "" if (df, dr) == (cf, cr) else \
                   f"   <-- MISMATCH, declared {df}/{dr}"
            if flag and not args.write_coverage:
                ok = False
            print(f"  {scope:28s} forward={cf:11s} reverse={cr:11s}{flag}")
        else:
            print(f"  {scope:28s} forward={cf:11s} reverse={cr:11s}"
                  f"   <-- not declared")

    for scope in declared:
        if scope not in computed:
            ok = False
            print(f"  ERROR: <coverage scope=\"{scope}\"> matches no path")

    if args.write_coverage:
        # Rewritten textually, not via ElementTree: ET drops comments and
        # reflows the document, which would destroy the hand-authored notes
        # that are most of this file's value.
        lines = map_path.read_text().splitlines(keepends=True)
        first = next((i for i, ln in enumerate(lines)
                      if ln.lstrip().startswith("<coverage")), None)
        if first is None:
            print("  ERROR: no existing <coverage> line to anchor the rewrite; "
                  "add one placeholder and rerun")
            return 1
        last = first
        while last < len(lines) and lines[last].lstrip().startswith("<coverage"):
            last += 1
        indent = lines[first][:len(lines[first]) - len(lines[first].lstrip())]
        block = [
            f'{indent}<coverage scope="{s}" forward="{computed[s][0]}"'
            f' reverse="{computed[s][1]}"/>\n'
            for s in sorted(computed, key=lambda s: (s != "/", s))
        ]
        map_path.write_text("".join(lines[:first] + block + lines[last:]))
        print(f"  wrote {len(block)} <coverage> element(s) to {map_path.name} "
              f"(comments preserved)")

    # decisions --------------------------------------------------------
    decisions = [r for r in rules if r.decision]
    if decisions:
        print(f"-- {len(decisions)} rule(s) need a physicist's review")
        for r in decisions:
            print(f"  [{r.id}] {r.rel}: {r.left or r.right}")
            if r.note:
                for line in re.sub(r"\s+", " ", r.note).strip().split(". "):
                    if line.strip():
                        print(f"      {line.strip().rstrip('.')}.")

    print("== PASS" if ok else "== FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
