//! Moving the focused pane into the pane or stack beside it, like laying off a
//! card onto a meld.
//!
//! Up and down move the pane one place through its stack, and at the stack's
//! edge stack it with the neighbour in that direction, entering on the side it
//! came from. Left and right always leave the column and join the neighbour at
//! the bottom of its stack. With no neighbour nothing happens: zellij has no
//! way to break a pane out of a stack on a chosen side.
//!
//! This assumes zellij's default `stacked_pane_list`, where a stack is one
//! visible pane with the others hidden behind it: every stack is then a single
//! rectangle of the layout.

use crate::nav::Dir;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Id {
    Terminal(u32),
    Plugin(u32),
}

/// The visible pane of a stack, or a pane that isn't stacked, in the active
/// tab's tiled layout.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Pane {
    pub id: Id,
    pub x: usize,
    pub y: usize,
    pub cols: usize,
    pub rows: usize,
    /// How many panes are in its stack, itself included.
    pub stacked: usize,
    /// When the pane last had focus, higher being more recent; breaks ties
    /// between neighbours the way zellij's own focus moves do.
    pub focused_at: u64,
}

impl Pane {
    fn right(&self) -> usize {
        self.x + self.cols
    }
    fn bottom(&self) -> usize {
        self.y + self.rows
    }
    fn overlaps_horizontally(&self, other: &Pane) -> bool {
        self.x < other.right() && other.x < self.right()
    }
    fn overlaps_vertically(&self, other: &Pane) -> bool {
        self.y < other.bottom() && other.y < self.bottom()
    }
    fn is_beside(&self, other: &Pane, dir: Dir) -> bool {
        match dir {
            Dir::Up => self.bottom() == other.y && self.overlaps_horizontally(other),
            Dir::Down => self.y == other.bottom() && self.overlaps_horizontally(other),
            Dir::Left => self.right() == other.x && self.overlaps_vertically(other),
            Dir::Right => self.x == other.right() && self.overlaps_vertically(other),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Step {
    /// Stack `pane` with `target`, or into the stack `target` is in. zellij
    /// puts it at the bottom, shown and focused.
    Stack { target: Id, pane: Id },
    /// Swap `pane` with its neighbour in its stack, `Up` or `Down`.
    Shift { pane: Id, dir: Dir },
}

/// The pane or stack beside `of` in `dir`: of several, the one focused most
/// recently, as zellij's own focus moves choose. A stack being one rectangle,
/// this steps over the rest of the stack `of` is in.
pub fn neighbour(panes: &[Pane], of: Id, dir: Dir) -> Option<&Pane> {
    let pane = panes.iter().find(|p| p.id == of)?;
    panes
        .iter()
        .filter(|p| p.id != pane.id && p.is_beside(pane, dir))
        .max_by_key(|p| p.focused_at)
}

/// The commands that move the focused pane in `dir`, given its place in its
/// stack (0 at the top).
pub fn plan(panes: &[Pane], focused: Id, place: usize, dir: Dir) -> Vec<Step> {
    let Some(pane) = panes.iter().find(|p| p.id == focused) else {
        return vec![];
    };
    let within = match dir {
        Dir::Up => place > 0,
        Dir::Down => place + 1 < pane.stacked,
        Dir::Left | Dir::Right => false,
    };
    if within {
        return vec![Step::Shift { pane: pane.id, dir }];
    }

    let Some(target) = neighbour(panes, pane.id, dir) else {
        return vec![];
    };
    // Coming from above, the pane climbs from the bottom to the top
    let climb = if dir == Dir::Down { target.stacked } else { 0 };
    let mut steps = vec![Step::Stack {
        target: target.id,
        pane: pane.id,
    }];
    steps.extend((0..climb).map(|_| Step::Shift {
        pane: pane.id,
        dir: Dir::Up,
    }));
    steps
}

#[cfg(test)]
mod tests {
    use super::*;

    fn t(id: u32, x: usize, y: usize, cols: usize, rows: usize, stacked: usize) -> Pane {
        Pane {
            id: Id::Terminal(id),
            x,
            y,
            cols,
            rows,
            stacked,
            focused_at: 0,
        }
    }

    fn stack(target: u32, pane: u32) -> Step {
        Step::Stack {
            target: Id::Terminal(target),
            pane: Id::Terminal(pane),
        }
    }

    fn shift(pane: u32, dir: Dir) -> Step {
        Step::Shift {
            pane: Id::Terminal(pane),
            dir,
        }
    }

    fn focus(id: u32) -> Id {
        Id::Terminal(id)
    }

    // 0 above 1, both full width
    fn split() -> Vec<Pane> {
        vec![t(0, 0, 0, 120, 20, 1), t(1, 0, 20, 120, 20, 1)]
    }

    #[test]
    fn up_stacks_with_the_pane_above() {
        assert_eq!(plan(&split(), focus(1), 0, Dir::Up), vec![stack(0, 1)]);
    }

    #[test]
    fn down_stacks_with_the_pane_below_and_climbs_to_the_top() {
        assert_eq!(
            plan(&split(), focus(0), 0, Dir::Down),
            vec![stack(1, 0), shift(0, Dir::Up)]
        );
    }

    #[test]
    fn down_into_a_stack_climbs_past_all_of_it() {
        let panes = vec![t(0, 0, 0, 120, 20, 1), t(1, 0, 20, 120, 20, 3)];
        assert_eq!(
            plan(&panes, focus(0), 0, Dir::Down),
            vec![
                stack(1, 0),
                shift(0, Dir::Up),
                shift(0, Dir::Up),
                shift(0, Dir::Up)
            ]
        );
    }

    #[test]
    fn inside_a_stack_moves_swap() {
        let panes = vec![t(0, 0, 0, 120, 40, 3)];
        assert_eq!(plan(&panes, focus(0), 1, Dir::Up), vec![shift(0, Dir::Up)]);
        assert_eq!(
            plan(&panes, focus(0), 1, Dir::Down),
            vec![shift(0, Dir::Down)]
        );
    }

    #[test]
    fn the_edge_of_a_stack_joins_the_neighbour() {
        let panes = vec![t(0, 0, 0, 120, 20, 1), t(1, 0, 20, 120, 20, 2)];
        assert_eq!(plan(&panes, focus(1), 0, Dir::Up), vec![stack(0, 1)]);
    }

    #[test]
    fn nothing_beyond_the_edge_does_nothing() {
        let panes = vec![t(0, 0, 0, 120, 40, 2)];
        assert_eq!(plan(&panes, focus(0), 0, Dir::Up), vec![]);
        assert_eq!(plan(&panes, focus(0), 1, Dir::Down), vec![]);
        assert_eq!(plan(&panes, focus(0), 0, Dir::Left), vec![]);
    }

    #[test]
    fn sideways_joins_at_the_bottom() {
        let panes = vec![t(0, 0, 0, 60, 40, 3), t(1, 60, 0, 60, 40, 2)];
        assert_eq!(plan(&panes, focus(1), 1, Dir::Left), vec![stack(0, 1)]);
        assert_eq!(plan(&panes, focus(0), 0, Dir::Right), vec![stack(1, 0)]);
    }

    #[test]
    fn neighbours_must_touch_and_overlap() {
        // 0 top left, 1 top right, 2 bottom right
        let panes = vec![
            t(0, 0, 0, 60, 40, 1),
            t(1, 60, 0, 60, 20, 1),
            t(2, 60, 20, 60, 20, 1),
        ];
        assert_eq!(plan(&panes, focus(2), 0, Dir::Up), vec![stack(1, 2)]);
        assert_eq!(plan(&panes, focus(1), 0, Dir::Right), vec![]);
    }

    #[test]
    fn the_neighbour_of_a_stack_is_past_its_edge() {
        // A stack of three between 0 and 2
        let panes = vec![
            t(0, 0, 0, 120, 10, 1),
            t(1, 0, 10, 120, 20, 3),
            t(2, 0, 30, 120, 10, 1),
        ];
        let id = |p: Option<&Pane>| p.map(|p| p.id);
        assert_eq!(id(neighbour(&panes, focus(1), Dir::Down)), Some(focus(2)));
        assert_eq!(id(neighbour(&panes, focus(1), Dir::Up)), Some(focus(0)));
        assert_eq!(id(neighbour(&panes, focus(0), Dir::Up)), None);
    }

    #[test]
    fn the_most_recently_focused_neighbour_wins() {
        let mut panes = vec![
            t(0, 0, 0, 60, 20, 1),
            t(1, 60, 0, 60, 20, 1),
            t(2, 0, 20, 120, 20, 1),
        ];
        panes[1].focused_at = 5;
        assert_eq!(plan(&panes, focus(2), 0, Dir::Up), vec![stack(1, 2)]);
        panes[0].focused_at = 6;
        assert_eq!(plan(&panes, focus(2), 0, Dir::Up), vec![stack(0, 2)]);
    }
}
