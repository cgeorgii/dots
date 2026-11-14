//! The focused pane's place in its stack, read from a tab's layout dump.
//!
//! zellij doesn't tell plugins the order of a stack, but its layout dump lists
//! a stack's panes in order inside a `pane stacked=true` node and marks the
//! focused one with `focus=true`. The dump puts one node per line, so this
//! reads it by lines rather than parsing KDL.

/// Where the focused tiled pane sits in its stack, 0 being the top; 0 when it
/// isn't stacked. `None` when the dump has no focused tiled pane.
pub fn focused_place(dump: &str) -> Option<usize> {
    // The nodes enclosing the current line, and how many panes each has
    // seen as direct children so far
    let mut open: Vec<(&str, usize)> = vec![];
    let mut in_tab = false;
    for line in dump.lines().map(str::trim) {
        if line == "}" {
            open.pop();
            if in_tab && !open.iter().any(|(node, _)| is_node(node, "tab")) {
                // only the first tab's panes count
                return None;
            }
            continue;
        }
        if is_node(line, "tab") {
            in_tab = true;
        }
        let floating = open.iter().any(|(node, _)| is_node(node, "floating_panes"));
        if in_tab && !floating && is_node(line, "pane") {
            let parent = open.last_mut();
            let index = parent.as_ref().map_or(0, |(_, seen)| *seen);
            if let Some((_, seen)) = parent {
                *seen += 1;
            }
            if has_property(line, "focus=true") {
                let stacked = open
                    .last()
                    .is_some_and(|(node, _)| has_property(node, "stacked=true"));
                return Some(if stacked { index } else { 0 });
            }
        }
        if line.ends_with('{') {
            open.push((line, 0));
        }
    }
    None
}

fn is_node(line: &str, name: &str) -> bool {
    line.split_whitespace().next() == Some(name)
}

fn has_property(line: &str, property: &str) -> bool {
    line.split_whitespace()
        .any(|word| word.trim_end_matches('{') == property)
}

#[cfg(test)]
mod tests {
    use super::*;

    // The dump of a session, trimmed to what matters
    const STACKED: &str = r#"layout {
    cwd "/home/user"
    tab name="Tab #1" focus=true hide_floating_panes=true {
        pane split_direction="vertical" {
            pane size="50%" {
                pane size="50%"
                pane size="50%" stacked=true {
                    pane
                    pane command="sleep" focus=true expanded=true {
                        args "1000"
                        start_suspended true
                    }
                    pane
                }
            }
            pane size="50%"
        }
        floating_panes {
            pane focus=true
        }
    }
    new_tab_template {
        pane stacked=true {
            pane focus=true
        }
    }
}"#;

    #[test]
    fn finds_the_place_in_the_stack() {
        assert_eq!(focused_place(STACKED), Some(1));
    }

    #[test]
    fn unstacked_panes_are_at_zero() {
        let dump = r#"layout {
    tab focus=true {
        pane stacked=true {
            pane
            pane expanded=true
        }
        pane focus=true
    }
}"#;
        assert_eq!(focused_place(dump), Some(0));
    }

    #[test]
    fn floating_and_template_panes_are_ignored() {
        let dump = STACKED.replace(r#"command="sleep" focus=true"#, r#"command="sleep""#);
        assert_eq!(focused_place(&dump), None);
    }

    #[test]
    fn values_containing_the_property_dont_match() {
        assert!(!has_property(r#"pane name="focus=true""#, "focus=true"));
        assert!(has_property("pane focus=true {", "focus=true"));
    }
}
