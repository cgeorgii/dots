//! Background zellij plugin for moving around and rearranging panes. Pipe
//! messages take a payload of `left`, `down`, `up` or `right`:
//!
//! - `nav` moves focus and leaves a zoomed pane ([`nav`]);
//! - `move` stacks the focused pane with its neighbour, or moves it through
//!   its stack ([`moves`], [`layout`]).

mod layout;
mod moves;
mod nav;

#[cfg(not(target_family = "wasm"))]
fn main() {}

#[cfg(target_family = "wasm")]
use std::collections::HashMap;
#[cfg(target_family = "wasm")]
use zellij_tile::prelude::*;

#[cfg(target_family = "wasm")]
register_plugin!(State);

#[cfg(target_family = "wasm")]
#[derive(Default)]
struct State {
    tabs: Vec<TabInfo>,
    panes: PaneManifest,
    /// When each pane last had focus, counted in pane updates
    focused_at: HashMap<moves::Id, u64>,
    clock: u64,
}

#[cfg(target_family = "wasm")]
impl ZellijPlugin for State {
    fn load(&mut self, _configuration: std::collections::BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::ReadCliPipes,
        ]);
        subscribe(&[EventType::TabUpdate, EventType::PaneUpdate]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::TabUpdate(tabs) => self.tabs = tabs,
            Event::PaneUpdate(panes) => {
                self.panes = panes;
                if let Some(id) = self.focused_tiled_pane() {
                    self.clock += 1;
                    self.focused_at.insert(id, self.clock);
                }
            }
            _ => {}
        }
        false
    }

    fn pipe(&mut self, message: PipeMessage) -> bool {
        if let PipeSource::Cli(id) = &message.source {
            unblock_cli_pipe_input(id);
        }
        let dir = message.payload.as_deref().and_then(nav::Dir::parse);
        match (message.name.as_str(), dir) {
            ("nav", Some(dir)) => self.navigate(dir),
            ("move", Some(dir)) => self.move_pane(dir),
            _ => {}
        }
        false
    }
}

#[cfg(target_family = "wasm")]
fn direction(dir: nav::Dir) -> Direction {
    match dir {
        nav::Dir::Left => Direction::Left,
        nav::Dir::Down => Direction::Down,
        nav::Dir::Up => Direction::Up,
        nav::Dir::Right => Direction::Right,
    }
}

#[cfg(target_family = "wasm")]
fn pane_id(id: moves::Id) -> PaneId {
    match id {
        moves::Id::Terminal(i) => PaneId::Terminal(i),
        moves::Id::Plugin(i) => PaneId::Plugin(i),
    }
}

#[cfg(target_family = "wasm")]
fn id_of(pane: &PaneInfo) -> moves::Id {
    if pane.is_plugin {
        moves::Id::Plugin(pane.id)
    } else {
        moves::Id::Terminal(pane.id)
    }
}

#[cfg(target_family = "wasm")]
impl State {
    fn active_tab(&self) -> Option<&TabInfo> {
        self.tabs.iter().find(|t| t.active)
    }

    /// The selectable tiled panes of the active tab
    fn tiled_panes(&self) -> impl Iterator<Item = &PaneInfo> {
        self.active_tab()
            .and_then(|t| self.panes.panes.get(&t.position))
            .into_iter()
            .flatten()
            .filter(|p| p.is_selectable && !p.is_floating && !p.is_suppressed)
    }

    fn focused_tiled_pane(&self) -> Option<moves::Id> {
        self.tiled_panes().find(|p| p.is_focused).map(id_of)
    }

    fn navigate(&self, dir: nav::Dir) {
        let tab = self
            .active_tab()
            .map(|t| nav::TabState {
                fullscreen: t.is_fullscreen_active,
                floating_visible: t.are_floating_panes_visible,
            })
            .unwrap_or_default();
        for step in nav::steps(tab, dir) {
            match step {
                nav::Step::Unzoom => toggle_focus_fullscreen(),
                nav::Step::Move(d) => move_focus(direction(d)),
            }
        }
    }

    /// Only tiled panes move, and not while one is zoomed: the geometry is
    /// then the zoom's, not the layout's.
    fn move_pane(&self, dir: nav::Dir) {
        let Some(tab) = self.active_tab() else { return };
        if tab.is_fullscreen_active || tab.are_floating_panes_visible {
            return;
        }
        let Some(focused) = self.focused_tiled_pane() else {
            return;
        };
        let place = dump_session_layout_for_tab(tab.position)
            .ok()
            .and_then(|(dump, _)| layout::focused_place(&dump))
            .unwrap_or(0);
        // A stack's hidden panes are suppressed, with its visible pane's
        // geometry
        let rect = |p: &PaneInfo| (p.pane_x, p.pane_y, p.pane_columns, p.pane_rows);
        let hidden: Vec<_> = self
            .panes
            .panes
            .get(&tab.position)
            .into_iter()
            .flatten()
            .filter(|p| p.is_suppressed && !p.is_floating)
            .map(rect)
            .collect();
        let panes: Vec<moves::Pane> = self
            .tiled_panes()
            .map(|p| {
                let id = id_of(p);
                moves::Pane {
                    id,
                    x: p.pane_x,
                    y: p.pane_y,
                    cols: p.pane_columns,
                    rows: p.pane_rows,
                    stacked: 1 + hidden.iter().filter(|h| **h == rect(p)).count(),
                    focused_at: self.focused_at.get(&id).copied().unwrap_or(0),
                }
            })
            .collect();
        for step in moves::plan(&panes, focused, place, dir) {
            match step {
                moves::Step::Stack { target, pane } => {
                    stack_panes(vec![pane_id(target), pane_id(pane)])
                }
                moves::Step::Shift { pane, dir } => {
                    move_pane_with_pane_id_in_direction(pane_id(pane), direction(dir))
                }
            }
        }
    }
}
