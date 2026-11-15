//! The status line, styled after tmux-gruvbox: a session and branch block,
//! powerline tabs, and the input mode on the right.
//!
//! Colours are ANSI names so the bar follows the terminal palette (and thus the
//! tinty scheme of the day); in base16 palettes black is the background and
//! white the foreground.

use std::ops::Range;
use unicode_width::UnicodeWidthStr;

const RIGHT_ARROW: &str = "\u{e0b0}";
const LEFT_ARROW: &str = "\u{e0b2}";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Color {
    Black,
    Red,
    Green,
    Blue,
    Magenta,
    White,
    BrightBlack,
    /// The shared accent and its bright form: 256-colour slots 22 and 23,
    /// which tinty-render fills in the kitty palette [ref:shared-accent].
    Accent,
    BrightAccent,
}

impl Color {
    fn fg(self) -> &'static str {
        match self {
            Color::Black => "30",
            Color::Red => "31",
            Color::Green => "32",
            Color::Blue => "34",
            Color::Magenta => "35",
            Color::White => "37",
            Color::BrightBlack => "90",
            Color::Accent => "38;5;22",
            Color::BrightAccent => "38;5;23",
        }
    }

    fn bg(self) -> &'static str {
        match self {
            Color::Black => "40",
            Color::Red => "41",
            Color::Green => "42",
            Color::Blue => "44",
            Color::Magenta => "45",
            Color::White => "47",
            Color::BrightBlack => "100",
            Color::Accent => "48;5;22",
            Color::BrightAccent => "48;5;23",
        }
    }
}

/// What a click on a cell does.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Target {
    Badge,
    /// The tab at this position.
    Tab(usize),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Tab {
    pub position: usize,
    pub name: String,
    pub active: bool,
}

/// Shown before the session and the branch; empty for none.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Glyphs {
    pub session: String,
    pub branch: String,
}

pub struct Input<'a> {
    pub glyphs: &'a Glyphs,
    pub session: &'a str,
    pub branch: Option<&'a str>,
    pub tabs: &'a [Tab],
    /// The input mode, as zellij's `Debug` prints it (`Normal`, `RenameTab`).
    pub mode: &'a str,
    pub cols: usize,
    /// The target under the pointer, drawn brighter.
    pub hover: Option<Target>,
}

#[derive(Debug, Default, PartialEq, Eq)]
pub struct Bar {
    /// The line, with SGR escapes.
    pub line: String,
    /// Clickable column ranges.
    pub targets: Vec<(Range<usize>, Target)>,
}

impl Bar {
    pub fn target_at(&self, col: usize) -> Option<Target> {
        self.targets
            .iter()
            .find(|(range, _)| range.contains(&col))
            .map(|(_, t)| *t)
    }
}

struct Cell {
    text: String,
    fg: Color,
    bg: Color,
    bold: bool,
    target: Option<Target>,
}

fn cell(text: impl Into<String>, fg: Color, bg: Color) -> Cell {
    Cell {
        text: text.into(),
        fg,
        bg,
        bold: false,
        target: None,
    }
}

impl Cell {
    fn bold(mut self) -> Self {
        self.bold = true;
        self
    }

    fn on(mut self, target: Target) -> Self {
        self.target = Some(target);
        self
    }
}

/// (background, foreground) of the mode block.
fn mode_colors(mode: &str) -> (Color, Color) {
    match mode {
        // The resting mode wears the accent, as the badge does
        "Normal" => (Color::Accent, Color::Black),
        "Locked" => (Color::BrightBlack, Color::White),
        "Tmux" => (Color::Red, Color::Black),
        "Scroll" | "EnterSearch" | "Search" => (Color::Blue, Color::Black),
        "RenameTab" => (Color::Magenta, Color::Black),
        _ => (Color::Green, Color::Black),
    }
}

/// `text`, preceded by `glyph` unless that is empty.
fn labelled(glyph: &str, text: &str) -> String {
    if glyph.is_empty() {
        text.to_owned()
    } else {
        format!("{glyph} {text}")
    }
}

fn left(input: &Input) -> Vec<Cell> {
    let session = labelled(&input.glyphs.session, input.session);
    let badge = match input.branch {
        Some(b) if !b.is_empty() => {
            format!(" {session} {} ", labelled(&input.glyphs.branch, b))
        }
        _ => format!(" {session} "),
    };
    let hovered = |t| input.hover == Some(t);
    let badge_bg = if hovered(Target::Badge) {
        Color::BrightAccent
    } else {
        Color::Accent
    };
    let mut cells = vec![
        cell(badge, Color::Black, badge_bg).bold().on(Target::Badge),
        cell(RIGHT_ARROW, badge_bg, Color::Black).on(Target::Badge),
    ];
    let renaming = input.mode == "RenameTab";
    for tab in input.tabs {
        let target = Target::Tab(tab.position);
        let (bg, fg) = match (tab.active, renaming) {
            (true, true) => (Color::Magenta, Color::Black),
            (true, false) => (Color::White, Color::Black),
            (false, _) if hovered(target) => (Color::Accent, Color::White),
            (false, _) => (Color::BrightBlack, Color::White),
        };
        let label = cell(format!(" {} {} ", tab.position + 1, tab.name), fg, bg);
        cells.extend([
            cell(RIGHT_ARROW, Color::Black, bg).on(target),
            if tab.active { label.bold() } else { label }.on(target),
            cell(RIGHT_ARROW, bg, Color::Black).on(target),
        ]);
    }
    cells
}

fn right(input: &Input) -> Vec<Cell> {
    let (bg, fg) = mode_colors(input.mode);
    vec![
        cell(LEFT_ARROW, bg, Color::Black),
        cell(format!(" {} ", input.mode), fg, bg).bold(),
    ]
}

fn width(cells: &[Cell]) -> usize {
    cells.iter().map(|c| c.text.width()).sum()
}

/// Drops whole characters from the end until `cells` fit in `max` columns.
fn truncate(cells: &mut Vec<Cell>, max: usize) {
    while width(cells) > max {
        let Some(last) = cells.last_mut() else { return };
        last.text.pop();
        if last.text.is_empty() {
            cells.pop();
        }
    }
}

pub fn render(input: &Input) -> Bar {
    let mut left = left(input);
    let mut right = right(input);
    // The mode yields to the tabs, and the tabs to the width
    if width(&left) + width(&right) > input.cols {
        right.clear();
    }
    truncate(&mut left, input.cols);
    let gap = input.cols - width(&left) - width(&right);

    let mut bar = Bar::default();
    let mut col = 0;
    let fill = cell(" ".repeat(gap), Color::Black, Color::Black);
    for c in left.iter().chain([&fill]).chain(&right) {
        let w = c.text.width();
        if let Some(t) = c.target {
            match bar.targets.last_mut() {
                Some((range, last)) if *last == t && range.end == col => range.end += w,
                _ => bar.targets.push((col..col + w, t)),
            }
        }
        col += w;
        let bold = if c.bold { "1;" } else { "" };
        bar.line += &format!("\x1b[0;{bold}{};{}m{}", c.fg.fg(), c.bg.bg(), c.text);
    }
    bar.line += "\x1b[0m";
    bar
}

#[cfg(test)]
mod tests {
    use super::*;

    static NO_GLYPHS: Glyphs = Glyphs {
        session: String::new(),
        branch: String::new(),
    };

    fn tabs() -> Vec<Tab> {
        vec![
            Tab {
                position: 0,
                name: "claude".into(),
                active: false,
            },
            Tab {
                position: 1,
                name: "~/dots".into(),
                active: true,
            },
        ]
    }

    fn input<'a>(tabs: &'a [Tab], cols: usize) -> Input<'a> {
        Input {
            glyphs: &NO_GLYPHS,
            session: "dots",
            branch: Some("main"),
            tabs,
            mode: "Normal",
            cols,
            hover: None,
        }
    }

    fn plain(line: &str) -> String {
        let mut out = String::new();
        let mut chars = line.chars();
        while let Some(c) = chars.next() {
            if c == '\x1b' {
                chars.by_ref().take_while(|c| *c != 'm').for_each(drop);
            } else {
                out.push(c);
            }
        }
        out
    }

    #[test]
    fn fills_the_width() {
        let tabs = tabs();
        let bar = render(&input(&tabs, 80));
        let text = plain(&bar.line);
        assert_eq!(text.width(), 80);
        assert!(text.starts_with(" dots main "));
        assert!(text.ends_with(" Normal "));
    }

    #[test]
    fn whole_badge_is_clickable() {
        let tabs = tabs();
        let bar = render(&input(&tabs, 80));
        // " dots main " and its arrow
        for col in 0..12 {
            assert_eq!(bar.target_at(col), Some(Target::Badge), "col {col}");
        }
        assert_eq!(bar.target_at(12), Some(Target::Tab(0)));
    }

    #[test]
    fn badge_with_glyphs() {
        let tabs = tabs();
        let glyphs = Glyphs {
            session: "P".into(),
            branch: "B".into(),
        };
        let bar = render(&Input {
            glyphs: &glyphs,
            ..input(&tabs, 80)
        });
        assert!(plain(&bar.line).starts_with(" P dots B main \u{e0b0}"));
        let bar = render(&Input {
            glyphs: &glyphs,
            branch: None,
            ..input(&tabs, 80)
        });
        assert!(plain(&bar.line).starts_with(" P dots \u{e0b0}"));
    }

    #[test]
    fn hover_brightens_its_target() {
        let tabs = tabs();
        let plain_bar = render(&input(&tabs, 80));
        let badge = render(&Input {
            hover: Some(Target::Badge),
            ..input(&tabs, 80)
        });
        let tab = render(&Input {
            hover: Some(Target::Tab(0)),
            ..input(&tabs, 80)
        });
        let active = render(&Input {
            hover: Some(Target::Tab(1)),
            ..input(&tabs, 80)
        });
        assert!(badge.line.starts_with("\x1b[0;1;30;48;5;23m"));
        assert!(tab.line.contains("37;48;5;22m 1 claude "));
        assert_eq!(active.line, plain_bar.line);
        assert_eq!(plain(&badge.line), plain(&plain_bar.line));
    }

    #[test]
    fn badge_without_branch() {
        let tabs = tabs();
        let bar = render(&Input {
            branch: None,
            ..input(&tabs, 80)
        });
        assert!(plain(&bar.line).starts_with(" dots \u{e0b0}"));
        assert_eq!(bar.target_at(0), Some(Target::Badge));
    }

    #[test]
    fn tabs_map_to_their_positions() {
        let tabs = tabs();
        let bar = render(&input(&tabs, 80));
        let text = plain(&bar.line);
        let col = |s: &str| text[..text.find(s).unwrap()].width();
        assert_eq!(bar.target_at(col("claude")), Some(Target::Tab(0)));
        assert_eq!(bar.target_at(col("~/dots")), Some(Target::Tab(1)));
        assert_eq!(bar.target_at(col("Normal")), None);
    }

    #[test]
    fn narrow_drops_the_mode_then_truncates() {
        let tabs = tabs();
        let bar = render(&input(&tabs, 20));
        let text = plain(&bar.line);
        assert_eq!(text.width(), 20);
        assert!(!text.contains("Normal"));
    }

    #[test]
    fn wide_names_count_their_columns() {
        let tabs = vec![Tab {
            position: 0,
            name: "日本".into(),
            active: true,
        }];
        let bar = render(&input(&tabs, 40));
        assert_eq!(plain(&bar.line).width(), 40);
    }
}
