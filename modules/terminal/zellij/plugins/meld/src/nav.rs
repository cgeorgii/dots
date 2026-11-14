//! Pane navigation that leaves a zoomed pane, like tmux's select-pane.
//!
//! zellij keeps fullscreen on when focus moves: the neighbour is zoomed in
//! place of the current pane. Here moving focus first unzooms the tab.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Dir {
    Left,
    Down,
    Up,
    Right,
}

impl Dir {
    pub fn parse(s: &str) -> Option<Dir> {
        match s.trim().to_ascii_lowercase().as_str() {
            "left" | "h" => Some(Dir::Left),
            "down" | "j" => Some(Dir::Down),
            "up" | "k" => Some(Dir::Up),
            "right" | "l" => Some(Dir::Right),
            _ => None,
        }
    }
}

/// What the active tab looks like when a move is requested.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct TabState {
    pub fullscreen: bool,
    pub floating_visible: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Step {
    Unzoom,
    Move(Dir),
}

/// The commands that move focus in `dir`. Floating panes sit above the zoomed
/// pane and move among themselves, so the zoom only goes when the tiled layer
/// is the one navigated.
pub fn steps(tab: TabState, dir: Dir) -> Vec<Step> {
    if tab.fullscreen && !tab.floating_visible {
        vec![Step::Unzoom, Step::Move(dir)]
    } else {
        vec![Step::Move(dir)]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_names_and_vim_keys() {
        assert_eq!(Dir::parse("left"), Some(Dir::Left));
        assert_eq!(Dir::parse(" Right\n"), Some(Dir::Right));
        assert_eq!(Dir::parse("j"), Some(Dir::Down));
        assert_eq!(Dir::parse("sideways"), None);
    }

    #[test]
    fn plain_move_when_not_zoomed() {
        assert_eq!(
            steps(TabState::default(), Dir::Up),
            vec![Step::Move(Dir::Up)]
        );
    }

    #[test]
    fn unzooms_before_moving() {
        let tab = TabState {
            fullscreen: true,
            floating_visible: false,
        };
        assert_eq!(
            steps(tab, Dir::Left),
            vec![Step::Unzoom, Step::Move(Dir::Left)]
        );
    }

    #[test]
    fn floating_panes_keep_the_zoom() {
        let tab = TabState {
            fullscreen: true,
            floating_visible: true,
        };
        assert_eq!(steps(tab, Dir::Left), vec![Step::Move(Dir::Left)]);
    }
}
