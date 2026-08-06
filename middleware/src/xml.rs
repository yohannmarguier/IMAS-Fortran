//! A minimal XML reader, sufficient for `dd-maps/`.
//!
//! The crate deliberately has no dependencies (`cargo build --locked --offline` on a
//! compute node with no outbound network), and the maps are a handful of small
//! documents whose grammar is pinned by `dd-maps/schema/ids-map.xsd`. So instead of
//! pulling in an XML crate, this emits start/end tags with decoded attributes and
//! skips everything else — comments, the prolog, doctypes and text nodes.
//!
//! What it deliberately does not do: namespaces, CDATA, entity definitions, text
//! content. The maps use none of them, and `<note>` bodies are the only text in the
//! files — the reporting side uses `@reason` attributes instead, so losing text costs
//! nothing.
//!
//! Like the rest of the crate it may not panic: every slice comes from `find` or
//! `strip_prefix` (already at a char boundary), and every fallible step ends the scan
//! rather than unwrapping. A malformed document therefore yields a short event stream,
//! which the map loader reports as an unusable map and falls back to pass-through.

/// A start tag (`empty` distinguishes `<a/>` from `<a>`) or an end tag.
#[derive(Debug, PartialEq, Eq)]
pub enum Event<'a> {
    Start {
        name: &'a str,
        attrs: Vec<(&'a str, String)>,
        empty: bool,
    },
    End {
        name: &'a str,
    },
}

impl<'a> Event<'a> {
    /// The value of `name`, or `None`. Attribute names are matched verbatim, so
    /// `left-glob` is asked for as `"left-glob"`.
    pub fn attr(&self, want: &str) -> Option<&str> {
        match self {
            Event::Start { attrs, .. } => attrs
                .iter()
                .find(|(name, _)| *name == want)
                .map(|(_, value)| value.as_str()),
            Event::End { .. } => None,
        }
    }
}

/// Pull-style scanner over a whole document.
pub struct Reader<'a> {
    rest: &'a str,
}

impl<'a> Reader<'a> {
    pub fn new(source: &'a str) -> Self {
        Reader { rest: source }
    }
}

impl<'a> Iterator for Reader<'a> {
    type Item = Event<'a>;

    fn next(&mut self) -> Option<Event<'a>> {
        loop {
            let lt = self.rest.find('<')?;
            let after = self.rest.get(lt + 1..)?;

            // <!-- comment -->. Checked before the generic <! branch: a comment body may
            // contain `>` (the maps' headers are full of `3.39.0 <-> 4.1.1`), so stopping
            // at the first `>` would resume the scan inside prose.
            if let Some(body) = after.strip_prefix("!--") {
                let end = body.find("-->")?;
                self.rest = body.get(end + 3..)?;
                continue;
            }
            // <?xml ... ?>
            if let Some(body) = after.strip_prefix('?') {
                let end = body.find("?>")?;
                self.rest = body.get(end + 2..)?;
                continue;
            }
            // <!DOCTYPE ...>
            if let Some(body) = after.strip_prefix('!') {
                let end = body.find('>')?;
                self.rest = body.get(end + 1..)?;
                continue;
            }
            // </name>
            if let Some(body) = after.strip_prefix('/') {
                let end = body.find('>')?;
                let name = body.get(..end)?.trim();
                self.rest = body.get(end + 1..)?;
                return Some(Event::End { name });
            }

            let end = tag_end(after)?;
            let inner = after.get(..end)?;
            self.rest = after.get(end + 1..)?;

            let (inner, empty) = match inner.strip_suffix('/') {
                Some(head) => (head, true),
                None => (inner, false),
            };
            let name_end = inner.find(char::is_whitespace).unwrap_or(inner.len());
            let name = inner.get(..name_end)?;
            if name.is_empty() {
                continue;
            }
            let attrs = attributes(inner.get(name_end..)?);
            return Some(Event::Start { name, attrs, empty });
        }
    }
}

/// Offset of the `>` closing a start tag, skipping any that sit inside an attribute
/// value. Scanning for a bare `>` would be enough for today's maps, but an attribute is
/// free to contain one and the failure would be a silently truncated rule set.
fn tag_end(s: &str) -> Option<usize> {
    let mut quote: Option<char> = None;
    for (i, c) in s.char_indices() {
        match quote {
            Some(q) if c == q => quote = None,
            Some(_) => {}
            None if c == '"' || c == '\'' => quote = Some(c),
            None if c == '>' => return Some(i),
            None => {}
        }
    }
    None
}

/// `name="value"` pairs from the body of a start tag, values entity-decoded. Stops at
/// the first thing that is not a pair, which for a schema-valid document is the end.
fn attributes(mut s: &str) -> Vec<(&str, String)> {
    let mut attrs = Vec::new();
    loop {
        let eq = match s.find('=') {
            Some(i) => i,
            None => return attrs,
        };
        // The last whitespace-separated token before `=` is the name, so a stray token
        // shifts nothing.
        let name = match s.get(..eq).and_then(|head| head.split_whitespace().next_back()) {
            Some(name) => name,
            None => return attrs,
        };
        let open = match s.get(eq + 1..) {
            Some(rest) => rest.trim_start(),
            None => return attrs,
        };
        let quote = match open.chars().next() {
            Some(q @ ('"' | '\'')) => q,
            _ => return attrs,
        };
        let body = match open.get(quote.len_utf8()..) {
            Some(body) => body,
            None => return attrs,
        };
        let close = match body.find(quote) {
            Some(i) => i,
            None => return attrs,
        };
        match body.get(..close) {
            Some(value) => attrs.push((name, decode(value))),
            None => return attrs,
        }
        s = match body.get(close + quote.len_utf8()..) {
            Some(rest) => rest,
            None => return attrs,
        };
    }
}

/// The five predefined entities. `&amp;` is expanded last so `&amp;lt;` stays `&lt;`.
fn decode(value: &str) -> String {
    if !value.contains('&') {
        return value.to_string();
    }
    value
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
        .replace("&amp;", "&")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn names(src: &str) -> Vec<String> {
        Reader::new(src)
            .map(|e| match e {
                Event::Start { name, empty, .. } => {
                    format!("{name}{}", if empty { "/" } else { "" })
                }
                Event::End { name } => format!("/{name}"),
            })
            .collect()
    }

    #[test]
    fn skips_prolog_comments_and_text() {
        let src = r#"<?xml version="1.0"?>
            <!-- a comment with < and > and even a --> marker ends it -->
            <root><a/>text<b>more</b></root>"#;
        assert_eq!(
            names(src),
            vec!["root", "a/", "b", "/b", "/root"],
            "text nodes are dropped and the prolog and comment are skipped"
        );
    }

    #[test]
    fn reads_attributes_of_both_quote_styles() {
        let events: Vec<_> = Reader::new(r#"<rule id='fold-p1d-j' rel="merged" subtree="yes"/>"#)
            .collect();
        let rule = events.first().expect("one event");
        assert_eq!(rule.attr("id"), Some("fold-p1d-j"));
        assert_eq!(rule.attr("rel"), Some("merged"));
        assert_eq!(rule.attr("subtree"), Some("yes"));
        assert_eq!(rule.attr("left"), None);
    }

    #[test]
    fn an_attribute_may_contain_the_tag_terminator() {
        // The reason strings in dd-maps/ describe DD3 -> DD4 moves, so this is not
        // hypothetical: a naive scan for `>` truncates the rule and loses `rel`.
        let events: Vec<_> =
            Reader::new(r#"<rule reason="m -> m^-2 (a > b)" rel="redefined"/>"#).collect();
        let rule = events.first().expect("one event");
        assert_eq!(rule.attr("reason"), Some("m -> m^-2 (a > b)"));
        assert_eq!(rule.attr("rel"), Some("redefined"));
    }

    #[test]
    fn decodes_the_predefined_entities() {
        let events: Vec<_> = Reader::new(r#"<n v="a&lt;b &amp;&amp; c&gt;d &quot;q&quot;"/>"#)
            .collect();
        assert_eq!(
            events.first().and_then(|e| e.attr("v")),
            Some(r#"a<b && c>d "q""#)
        );
    }

    #[test]
    fn malformed_input_ends_the_scan_instead_of_panicking() {
        assert_eq!(names("<a><b"), vec!["a"]);
        assert_eq!(names("<!-- unterminated"), Vec::<String>::new());
        assert_eq!(names("no markup at all"), Vec::<String>::new());
        // A non-ASCII attribute value must not be sliced off a char boundary.
        assert_eq!(names("<a v=\"é\"/><b/>"), vec!["a/", "b/"]);
    }
}
