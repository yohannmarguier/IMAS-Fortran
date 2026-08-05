"""Generate static HTML documentation for one specific IMAS Data Dictionary version.

Usage:
    python generate_dd_html.py [VERSION] [-o OUTDIR] [IDS_NAME ...]

Examples:
    python generate_dd_html.py 3.39.0
    python generate_dd_html.py 3.39.0 -o /tmp/dd339 equilibrium pulse_schedule

Reads the DD definitions bundled with IMAS-Python (imas.dd_zip.get_dd_xml), so it
works offline for every version IMAS-Python ships (3.22.0 ... 4.1.1) and needs no
DD build toolchain. Output is a set of self-contained HTML files: an index listing
every IDS, and one page per IDS showing the complete nested structure.
"""

import argparse
import html
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from imas.dd_zip import dd_xml_versions, get_dd_xml

# --- Presentation helpers ---------------------------------------------------

COORD_KEYS = [f"coordinate{i}" for i in range(1, 7)]

CSS = """
:root {
  --bg: #ffffff; --fg: #1f2328; --muted: #656d76; --line: #d8dee4;
  --accent: #3f51b5; --code-bg: #f6f8fa; --struct: #0a5d3a; --aos: #8a4b00;
  --dyn: #0550ae; --obs: #b02a37; --hover: #f6f8fa;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #14171c; --fg: #e6edf3; --muted: #9198a1; --line: #30363d;
    --accent: #8ea3ff; --code-bg: #1c2128; --struct: #56d4a0; --aos: #e3a15d;
    --dyn: #79b8ff; --obs: #ff7b72; --hover: #1c2128;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0; background: var(--bg); color: var(--fg); line-height: 1.5;
  font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
}
.wrap { max-width: 1200px; margin: 0 auto; padding: 24px 20px 96px; }
header { border-bottom: 1px solid var(--line); margin-bottom: 20px; padding-bottom: 14px; }
h1 { font-size: 24px; margin: 0 0 6px; }
h1 code { font-size: 22px; }
.sub { color: var(--muted); font-size: 13px; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
code, .path, .type { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
.toolbar {
  display: flex; gap: 10px; flex-wrap: wrap; align-items: center;
  margin: 0 0 16px; position: sticky; top: 0; background: var(--bg);
  padding: 10px 0; border-bottom: 1px solid var(--line); z-index: 5;
}
input[type=search] {
  flex: 1 1 260px; min-width: 200px; padding: 7px 10px; font-size: 14px;
  color: var(--fg); background: var(--code-bg);
  border: 1px solid var(--line); border-radius: 6px;
}
button {
  padding: 7px 12px; font-size: 13px; cursor: pointer; color: var(--fg);
  background: var(--code-bg); border: 1px solid var(--line); border-radius: 6px;
}
button:hover { background: var(--hover); }
.count { color: var(--muted); font-size: 13px; white-space: nowrap; }

/* tree */
ul.tree, ul.tree ul { list-style: none; margin: 0; padding: 0; }
ul.tree ul { margin-left: 18px; border-left: 1px solid var(--line); padding-left: 10px; }
li { margin: 1px 0; }
.node { padding: 3px 6px; border-radius: 5px; }
.node:hover { background: var(--hover); }
details > summary { cursor: pointer; list-style: none; }
details > summary::-webkit-details-marker { display: none; }
details > summary::before { content: "\\25B8"; color: var(--muted); margin-right: 6px; font-size: 11px; }
details[open] > summary::before { content: "\\25BE"; }
.leaf::before { content: "\\2022"; color: var(--muted); margin-right: 7px; font-size: 12px; }
.path { font-weight: 600; }
.path.struct { color: var(--struct); }
.path.aos { color: var(--aos); }
.type {
  font-size: 12px; color: var(--muted); background: var(--code-bg);
  border: 1px solid var(--line); border-radius: 4px; padding: 0 5px; margin-left: 7px;
}
.units { font-size: 12px; color: var(--fg); margin-left: 6px; opacity: .85; }
.tag { font-size: 11px; margin-left: 6px; padding: 0 5px; border-radius: 4px; border: 1px solid var(--line); }
.tag.dynamic { color: var(--dyn); }
.tag.obsolescent, .tag.alpha { color: var(--obs); }
.doc { color: var(--muted); font-size: 13px; margin: 2px 0 4px 22px; max-width: 90ch; white-space: pre-wrap; }
.meta { font-size: 12px; color: var(--muted); margin: 0 0 4px 22px; }
.meta b { font-weight: 600; color: var(--fg); opacity: .8; }
.nbc { color: var(--obs); }
.hidden { display: none !important; }
body.hide-err li[data-err] { display: none; }
label.toggle { font-size: 13px; color: var(--muted); display: flex; align-items: center; gap: 5px; cursor: pointer; }

/* index table */
table { border-collapse: collapse; width: 100%; font-size: 14px; }
th, td { text-align: left; padding: 7px 10px; border-bottom: 1px solid var(--line); vertical-align: top; }
th { font-size: 12px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
tbody tr:hover { background: var(--hover); }
td.num { text-align: right; font-variant-numeric: tabular-nums; color: var(--muted); }
.overflow { overflow-x: auto; }
.legend { font-size: 12px; color: var(--muted); margin-top: 8px; }
.legend span { margin-right: 14px; }
"""

FILTER_JS = """
const q = document.getElementById('q');
const errBox = document.getElementById('err');
const counter = document.getElementById('count');
const items = Array.from(document.querySelectorAll('li[data-search]'));
const dataNodes = items.filter(li => !li.dataset.err);

function setCount(shown, total) {
  counter.textContent = (shown === total)
    ? total + ' nodes' : shown + ' of ' + total + ' nodes';
}

function filter() {
  const term = q.value.trim().toLowerCase();
  const pool = errBox.checked ? items : dataNodes;
  if (!term) {
    items.forEach(li => li.classList.remove('hidden'));
    document.querySelectorAll('details').forEach(d => d.open = false);
    setCount(pool.length, pool.length);
    return;
  }
  let shown = 0;
  // Hide everything, then reveal matches plus their ancestors.
  items.forEach(li => li.classList.add('hidden'));
  for (const li of pool) {
    if (li.dataset.search.indexOf(term) === -1) continue;
    shown++;
    li.classList.remove('hidden');
    let p = li.parentElement;
    while (p && p !== document.body) {
      if (p.tagName === 'LI') p.classList.remove('hidden');
      if (p.tagName === 'DETAILS') p.open = true;
      p = p.parentElement;
    }
    // Keep descendants of a match visible too.
    li.querySelectorAll('li').forEach(c => c.classList.remove('hidden'));
  }
  setCount(shown, pool.length);
}

// Error nodes (_error_upper / _error_lower / _error_index) are hidden by default.
document.body.classList.add('hide-err');
errBox.addEventListener('change', () => {
  document.body.classList.toggle('hide-err', !errBox.checked);
  filter();
});
q.addEventListener('input', filter);
document.getElementById('expand').onclick = () =>
  document.querySelectorAll('details').forEach(d => d.open = true);
document.getElementById('collapse').onclick = () =>
  document.querySelectorAll('details').forEach(d => d.open = false);
filter();
// Open the tree down to a deep-linked anchor.
if (location.hash) {
  const el = document.querySelector(decodeURIComponent(location.hash));
  if (el) {
    let p = el.parentElement;
    while (p && p !== document.body) { if (p.tagName === 'DETAILS') p.open = true; p = p.parentElement; }
    el.scrollIntoView();
  }
}
"""

INDEX_JS = """
const q = document.getElementById('q');
const rows = Array.from(document.querySelectorAll('tbody tr'));
const counter = document.getElementById('count');
function filter() {
  const term = q.value.trim().toLowerCase();
  let shown = 0;
  rows.forEach(tr => {
    const hit = !term || tr.dataset.search.indexOf(term) !== -1;
    tr.classList.toggle('hidden', !hit);
    if (hit) shown++;
  });
  counter.textContent = shown === rows.length ? rows.length + ' IDSs' : shown + ' of ' + rows.length + ' IDSs';
}
q.addEventListener('input', filter);
filter();
"""


def esc(text):
    return html.escape(text or "", quote=True)


def page(title, body, script):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
{body}
</div>
<script>{script}</script>
</body>
</html>
"""


# --- Tree rendering --------------------------------------------------------


def coordinates_of(field):
    """Return a list of 'coordinate1: 1...N' strings for a field."""
    out = []
    for key in COORD_KEYS:
        value = field.get(key)
        same_as = field.get(f"{key}_same_as")
        if value:
            out.append(f"{key[-1]}: {value}")
        elif same_as:
            out.append(f"{key[-1]}: same as {same_as}")
    return out


ERROR_SUFFIXES = ("_error_upper", "_error_lower", "_error_index")


def render_field(field, ids_name, counter):
    """Render one <li> for a field, recursing into child fields.

    Within an IDS, the ``path`` attribute is the full path from the IDS root
    ('time_slice/profiles_1d/psi') and ``path_doc`` is the same path with index
    notation ('time_slice(itime)/profiles_1d/psi(:)'). The tree shows only the
    last segment of ``path_doc``; the full path goes in the anchor and tooltip.
    """
    name = field.get("name", "")
    full_path = field.get("path", name)
    path_doc = field.get("path_doc") or full_path
    display = path_doc.rsplit("/", 1)[-1]
    anchor = f"{ids_name}-" + full_path.replace("/", "-")
    is_error_node = name.endswith(ERROR_SUFFIXES)
    data_type = field.get("data_type", "")
    is_struct = data_type == "structure"
    is_aos = data_type == "struct_array"
    children = field.findall("field")
    counter[0] += 1
    if not is_error_node:
        counter[1] += 1

    css_path = "path struct" if is_struct else ("path aos" if is_aos else "path")
    type_label = data_type
    if is_aos and field.get("maxoccur"):
        type_label = f"{data_type} [maxoccur {field.get('maxoccur')}]"

    head = [f'<span class="{css_path}" title="{esc(path_doc)}">{esc(display)}</span>']
    head.append(f'<span class="type">{esc(type_label)}</span>')
    units = field.get("units")
    if units:
        head.append(f'<span class="units">[{esc(units)}]</span>')
    node_type = field.get("type")
    if node_type:
        head.append(f'<span class="tag {esc(node_type)}">{esc(node_type)}</span>')
    lifecycle = field.get("lifecycle_status")
    if lifecycle and lifecycle != "active":
        since = field.get("lifecycle_version", "")
        label = f"{lifecycle} {since}".strip()
        head.append(f'<span class="tag {esc(lifecycle)}">{esc(label)}</span>')
    head_html = "".join(head)

    doc = field.get("documentation", "")
    body = [f'<div class="doc">{esc(doc)}</div>'] if doc else []

    meta = []
    coords = coordinates_of(field)
    if coords:
        meta.append(f"<b>coordinates</b> {esc('; '.join(coords))}")
    if field.get("structure_reference"):
        meta.append(f"<b>structure</b> {esc(field.get('structure_reference'))}")
    if field.get("timebasepath"):
        meta.append(f"<b>time base</b> {esc(field.get('timebasepath'))}")
    if field.get("doc_identifier"):
        meta.append(f"<b>identifier</b> {esc(field.get('doc_identifier'))}")
    if field.get("introduced_after_version"):
        meta.append(f"<b>introduced after</b> {esc(field.get('introduced_after_version'))}")
    if field.get("cocos_label_transformation"):
        meta.append(f"<b>COCOS</b> {esc(field.get('cocos_label_transformation'))}")
    if meta:
        body.append(f'<div class="meta">{" &middot; ".join(meta)}</div>')

    nbc = []
    if field.get("change_nbc_version"):
        nbc.append(f"<b>NBC change in {esc(field.get('change_nbc_version'))}</b>")
    if field.get("change_nbc_previous_name"):
        nbc.append(f"was {esc(field.get('change_nbc_previous_name'))}")
    if field.get("change_nbc_previous_type"):
        nbc.append(f"previous type {esc(field.get('change_nbc_previous_type'))}")
    if field.get("change_nbc_description"):
        nbc.append(esc(field.get("change_nbc_description")))
    if nbc:
        body.append(f'<div class="meta nbc">{" &middot; ".join(nbc)}</div>')

    body_html = "".join(body)
    # Everything searchable for this node: full path, docs, type, units.
    search = " ".join(
        [f"{ids_name}/{full_path}", display, data_type, units or "", doc]
    ).lower()
    li_attrs = f'data-search="{esc(search)}"' + (' data-err="1"' if is_error_node else "")

    if children:
        inner = "".join(render_field(c, ids_name, counter) for c in children)
        return (
            f"<li {li_attrs}>"
            f'<details><summary class="node" id="{esc(anchor)}">{head_html}</summary>'
            f"{body_html}<ul>{inner}</ul></details></li>"
        )
    return (
        f"<li {li_attrs}>"
        f'<div class="node leaf" id="{esc(anchor)}">{head_html}</div>'
        f"{body_html}</li>"
    )


def render_ids_page(ids, version):
    name = ids.get("name")
    counter = [0, 0]  # [all nodes, non-error nodes]
    tree = "".join(render_field(f, name, counter) for f in ids.findall("field"))
    lifecycle = ids.get("lifecycle_status", "")
    url = ids.get("url")

    header = [
        f"<header><h1><code>{esc(name)}</code></h1>",
        f'<div class="sub">Data Dictionary {esc(version)} &middot; '
        f"{counter[1]} nodes ({counter[0]} incl. error nodes) &middot; "
        f'maxoccur {esc(ids.get("maxoccur", ""))} &middot; '
        f'lifecycle {esc(lifecycle)} (since {esc(ids.get("lifecycle_version", ""))})'
        f' &middot; <a href="index.html">all IDSs</a></div>',
        f'<p class="doc" style="margin-left:0">{esc(ids.get("documentation", ""))}</p>',
    ]
    if url:
        header.append(f'<p class="sub"><a href="{esc(url)}">{esc(url)}</a></p>')
    header.append("</header>")

    toolbar = (
        '<div class="toolbar">'
        f'<input type="search" id="q" placeholder="Filter {esc(name)} by path, type or documentation…">'
        '<button id="expand">Expand all</button>'
        '<button id="collapse">Collapse all</button>'
        '<label class="toggle"><input type="checkbox" id="err"> error nodes</label>'
        '<span class="count" id="count"></span>'
        "</div>"
        '<div class="legend">'
        '<span><b class="path struct">structure</b></span>'
        '<span><b class="path aos">array of structures</b></span>'
        "<span>[units]</span><span>dynamic / static / constant</span>"
        "</div>"
    )
    body = f'{"".join(header)}{toolbar}<ul class="tree">{tree}</ul>'
    return page(f"{name} — IMAS DD {version}", body, FILTER_JS), counter[1]


def render_index(entries, version, total_nodes):
    rows = []
    for name, doc, lifecycle, maxoccur, count in entries:
        search = f"{name} {doc}".lower()
        rows.append(
            f'<tr data-search="{esc(search)}">'
            f'<td><a href="{esc(name)}.html"><code>{esc(name)}</code></a></td>'
            f'<td class="num">{count}</td>'
            f'<td class="num">{esc(maxoccur)}</td>'
            f"<td>{esc(lifecycle)}</td>"
            f"<td>{esc(doc)}</td></tr>"
        )
    body = f"""<header>
<h1>IMAS Data Dictionary <code>{esc(version)}</code></h1>
<div class="sub">{len(entries)} IDSs &middot; {total_nodes} documented nodes (error nodes excluded) &middot;
generated from the DD definitions bundled with IMAS-Python</div>
</header>
<div class="toolbar">
<input type="search" id="q" placeholder="Filter IDSs by name or description…">
<span class="count" id="count"></span>
</div>
<div class="overflow"><table>
<thead><tr><th>IDS</th><th class="num">Nodes</th><th class="num">Maxoccur</th>
<th>Lifecycle</th><th>Description</th></tr></thead>
<tbody>{"".join(rows)}</tbody>
</table></div>
"""
    return page(f"IMAS Data Dictionary {version}", body, INDEX_JS)


# --- Main -----------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", nargs="?", default="3.39.0", help="DD version")
    parser.add_argument("ids", nargs="*", help="IDS names (default: all)")
    parser.add_argument("-o", "--outdir", help="output directory")
    args = parser.parse_args()

    available = dd_xml_versions()
    if args.version not in available:
        sys.exit(f"DD {args.version} not bundled. Available: {', '.join(available)}")

    outdir = Path(args.outdir or f"dd-{args.version}-html")
    outdir.mkdir(parents=True, exist_ok=True)

    root = ET.fromstring(get_dd_xml(args.version))
    wanted = set(args.ids)
    entries = []
    total = 0
    for ids in root.findall("IDS"):
        name = ids.get("name")
        if wanted and name not in wanted:
            continue
        html_text, count = render_ids_page(ids, args.version)
        (outdir / f"{name}.html").write_text(html_text, encoding="utf-8")
        entries.append(
            (
                name,
                ids.get("documentation", ""),
                ids.get("lifecycle_status", ""),
                ids.get("maxoccur", ""),
                count,
            )
        )
        total += count

    entries.sort(key=lambda e: e[0])
    (outdir / "index.html").write_text(
        render_index(entries, args.version, total), encoding="utf-8"
    )
    print(f"DD {args.version}: {len(entries)} IDSs, {total} nodes")
    print(f"Wrote {outdir.resolve()}/index.html")


if __name__ == "__main__":
    main()
