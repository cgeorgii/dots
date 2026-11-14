//! Tabs named after their focused pane, like tmux's automatic-rename.
//!
//! A tab is renamed only while its name is one zellij made up (`Tab #N`) or one
//! this plugin set. Renaming it by hand stops that; clearing the name in
//! RenameTab mode brings it back.
//!
//! Names may end in a decoration that other tools own, such as an agent status
//! icon: a suffix between U+2063 and U+2064. It is left out when comparing
//! names and kept when renaming.

use std::collections::HashMap;

const DECORATION_OPEN: char = '\u{2063}';
const DECORATION_CLOSE: char = '\u{2064}';

/// Names kept per tab: renames are applied asynchronously, so a tab update can
/// still show one of the previous names this plugin set.
const REMEMBERED: usize = 4;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Tab {
    pub id: u64,
    pub name: String,
    /// Title of the focused tiled terminal pane, if there is one.
    pub focused_title: Option<String>,
}

#[derive(Debug, Default)]
pub struct Namer {
    max_len: usize,
    ours: HashMap<u64, Vec<String>>,
}

impl Namer {
    /// `max_len` is in characters; 0 keeps titles whole.
    pub fn new(max_len: usize) -> Self {
        Namer {
            max_len,
            ..Default::default()
        }
    }

    /// The renames to apply, as (tab id, new name).
    ///
    /// `settled` says a rename typed in RenameTab mode just ended; only then
    /// does an empty name mean "cleared". Elsewhere it is passed through on the
    /// way to a new name: `zellij action rename-tab` clears, then types.
    pub fn plan(&mut self, tabs: &[Tab], settled: bool) -> Vec<(u64, String)> {
        self.ours.retain(|id, _| tabs.iter().any(|t| t.id == *id));
        let mut renames = vec![];
        for tab in tabs {
            let (base, decoration) = split_decoration(&tab.name);
            let ours = self.ours.entry(tab.id).or_default();
            let cleared = base.is_empty() && settled;
            if !(cleared || is_default(base) || ours.iter().any(|n| n == base)) {
                continue;
            }
            let Some(title) = tab.focused_title.as_deref().map(str::trim) else {
                continue;
            };
            if title.is_empty() {
                continue;
            }
            let want = truncate(title, self.max_len);
            if want == base {
                // Settled: older names no longer come back in updates
                ours.retain(|n| *n == want);
                continue;
            }
            ours.push(want.clone());
            if ours.len() > REMEMBERED {
                ours.remove(0);
            }
            renames.push((tab.id, format!("{want}{decoration}")));
        }
        renames
    }
}

/// The name without its decoration, and the decoration with the space before it.
fn split_decoration(name: &str) -> (&str, &str) {
    if name.ends_with(DECORATION_CLOSE) {
        if let Some(open) = name.rfind(DECORATION_OPEN) {
            let start = if name[..open].ends_with(' ') {
                open - 1
            } else {
                open
            };
            return name.split_at(start);
        }
    }
    (name, "")
}

/// zellij's name for a tab created without one.
fn is_default(name: &str) -> bool {
    name.strip_prefix("Tab #")
        .is_some_and(|n| !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit()))
}

fn truncate(s: &str, max: usize) -> String {
    if max == 0 || s.chars().count() <= max {
        return s.to_string();
    }
    let mut out: String = s.chars().take(max.saturating_sub(1)).collect();
    out.push('…');
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tab(id: u64, name: &str, title: Option<&str>) -> Tab {
        Tab {
            id,
            name: name.into(),
            focused_title: title.map(Into::into),
        }
    }

    #[test]
    fn names_default_tabs() {
        let mut n = Namer::new(0);
        let tabs = [
            tab(1, "Tab #1", Some("~/dots")),
            tab(2, "Tab #2", Some("nvim")),
        ];
        assert_eq!(
            n.plan(&tabs, false),
            vec![(1, "~/dots".into()), (2, "nvim".into())]
        );
    }

    #[test]
    fn follows_the_focused_pane() {
        let mut n = Namer::new(0);
        n.plan(&[tab(1, "Tab #1", Some("~/dots"))], false);
        assert_eq!(
            n.plan(&[tab(1, "~/dots", Some("nvim"))], false),
            vec![(1, "nvim".into())]
        );
    }

    #[test]
    fn leaves_names_set_by_hand() {
        let mut n = Namer::new(0);
        n.plan(&[tab(1, "Tab #1", Some("~/dots"))], false);
        assert!(n.plan(&[tab(1, "work", Some("nvim"))], false).is_empty());
        // and tabs created with a name, which were never ours
        assert!(n
            .plan(&[tab(2, "wm-feature", Some("nvim"))], false)
            .is_empty());
    }

    #[test]
    fn clearing_the_name_resumes_naming() {
        let mut n = Namer::new(0);
        assert!(n.plan(&[tab(1, "work", Some("nvim"))], false).is_empty());
        assert_eq!(
            n.plan(&[tab(1, "", Some("nvim"))], true),
            vec![(1, "nvim".into())]
        );
    }

    #[test]
    fn passing_through_empty_is_not_clearing() {
        // `rename-tab mine` on a named tab reports "" twice, then "mine"
        let mut n = Namer::new(0);
        n.plan(&[tab(1, "Tab #1", Some("nvim"))], false);
        assert!(n.plan(&[tab(1, "", Some("nvim"))], false).is_empty());
        assert!(n.plan(&[tab(1, "", Some("nvim"))], false).is_empty());
        assert!(n.plan(&[tab(1, "mine", Some("nvim"))], false).is_empty());
    }

    #[test]
    fn stale_updates_are_not_mistaken_for_manual_names() {
        let mut n = Namer::new(0);
        n.plan(&[tab(1, "Tab #1", Some("a"))], false);
        n.plan(&[tab(1, "Tab #1", Some("b"))], false); // the rename to "a" hasn't landed
        assert_eq!(
            n.plan(&[tab(1, "a", Some("b"))], false),
            vec![(1, "b".into())]
        );
    }

    #[test]
    fn nothing_to_do_once_settled() {
        let mut n = Namer::new(0);
        n.plan(&[tab(1, "Tab #1", Some("nvim"))], false);
        assert!(n.plan(&[tab(1, "nvim", Some("nvim"))], false).is_empty());
    }

    #[test]
    fn keeps_decorations() {
        let mut n = Namer::new(0);
        let name = "Tab #1 \u{2063}🤖\u{2064}";
        assert_eq!(
            n.plan(&[tab(1, name, Some("claude"))], false),
            vec![(1, "claude \u{2063}🤖\u{2064}".into())]
        );
        // a decoration added to a name we set doesn't make it manual
        let name = "claude \u{2063}✅\u{2064}";
        assert_eq!(
            n.plan(&[tab(1, name, Some("~/dots"))], false),
            vec![(1, "~/dots \u{2063}✅\u{2064}".into())]
        );
    }

    #[test]
    fn skips_tabs_without_a_terminal_title() {
        let mut n = Namer::new(0);
        assert!(n
            .plan(
                &[tab(1, "Tab #1", None), tab(2, "Tab #2", Some("  "))],
                false
            )
            .is_empty());
    }

    #[test]
    fn truncates_long_titles() {
        let mut n = Namer::new(5);
        assert_eq!(
            n.plan(&[tab(1, "Tab #1", Some("abcdefgh"))], false),
            vec![(1, "abcd…".into())]
        );
        assert_eq!(
            n.plan(&[tab(2, "Tab #2", Some("abcde"))], false),
            vec![(2, "abcde".into())]
        );
    }

    #[test]
    fn default_names() {
        assert!(is_default("Tab #12"));
        assert!(!is_default("Tab #"));
        assert!(!is_default("Tab #1 x"));
    }
}
