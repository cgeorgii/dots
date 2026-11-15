//! Status line plugin: the session and branch, the tabs and the input mode
//! ([`render`]).
//!
//! The session name comes from zellij, so it shows as soon as the bar loads.
//! The branch is that of the focused pane's directory, from `branch_command`
//! run there whenever focus or the directory changes, and every few seconds
//! while the bar is visible; results are kept per directory, so returning to
//! one shows its branch at once.
//!
//! Configuration:
//! - `branch_command`: prints the branch of its working directory, or nothing;
//! - `badge_command`: run when the session block is clicked;
//! - `badge_pane`: the name of the floating pane `badge_command` opens; while
//!   it is open in the tab, clicking the session block closes it instead;
//! - `session_glyph`, `branch_glyph`: shown before the session and the branch.
//!
//! Commands are split on whitespace.
//!
//! Clicking a tab switches to it. The badge and tabs brighten under the
//! pointer, which needs zellij's `mouse_hover_effects` (on by default).

mod render;

#[cfg(not(target_family = "wasm"))]
fn main() {}

#[cfg(target_family = "wasm")]
use std::{
    collections::{BTreeMap, HashMap},
    path::PathBuf,
};
#[cfg(target_family = "wasm")]
use zellij_tile::prelude::*;

#[cfg(target_family = "wasm")]
register_plugin!(State);

#[cfg(target_family = "wasm")]
const REFRESH_SECONDS: f64 = 2.0;

#[cfg(target_family = "wasm")]
#[derive(Default)]
struct State {
    glyphs: render::Glyphs,
    branch_command: Vec<String>,
    badge_command: Vec<String>,
    badge_pane: Option<String>,
    mode: ModeInfo,
    tabs: Vec<TabInfo>,
    panes: PaneManifest,
    hidden: bool,
    focused: Option<PaneId>,
    cwd: Option<PathBuf>,
    /// Branch per directory; empty outside a repository.
    branches: HashMap<PathBuf, String>,
    /// The last render, for mapping clicks.
    bar: render::Bar,
    /// The target under the pointer.
    hover: Option<render::Target>,
}

#[cfg(target_family = "wasm")]
fn words(config: &BTreeMap<String, String>, key: &str) -> Vec<String> {
    config
        .get(key)
        .map(|s| s.split_whitespace().map(str::to_owned).collect())
        .unwrap_or_default()
}

#[cfg(target_family = "wasm")]
impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.branch_command = words(&configuration, "branch_command");
        self.badge_command = words(&configuration, "badge_command");
        self.badge_pane = configuration.get("badge_pane").cloned();
        let glyph = |key| configuration.get(key).cloned().unwrap_or_default();
        self.glyphs = render::Glyphs {
            session: glyph("session_glyph"),
            branch: glyph("branch_glyph"),
        };
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::RunCommands,
        ]);
        subscribe(&[
            EventType::ModeUpdate,
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::CwdChanged,
            EventType::RunCommandResult,
            EventType::Mouse,
            EventType::Visible,
            EventType::Timer,
            EventType::PermissionRequestResult,
        ]);
        set_timeout(REFRESH_SECONDS);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(_) => {
                set_selectable(false);
                false
            }
            Event::ModeUpdate(mode) => {
                self.mode = mode;
                true
            }
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
                self.follow_focus();
                true
            }
            Event::PaneUpdate(panes) => {
                self.panes = panes;
                self.follow_focus();
                true
            }
            Event::CwdChanged(pane, cwd, _) => {
                if Some(pane) == self.focused {
                    self.set_cwd(Some(cwd))
                } else {
                    false
                }
            }
            Event::RunCommandResult(exit, stdout, _, context) => {
                let Some(dir) = context.get("cwd").map(PathBuf::from) else {
                    return false;
                };
                let branch = match exit {
                    Some(0) => String::from_utf8_lossy(&stdout).trim().to_owned(),
                    _ => String::new(),
                };
                let changed = self.branches.get(&dir) != Some(&branch);
                self.branches.insert(dir.clone(), branch);
                changed && Some(&dir) == self.cwd.as_ref()
            }
            Event::Visible(visible) => {
                self.hidden = !visible;
                if visible {
                    self.query_branch();
                }
                false
            }
            Event::Timer(_) => {
                set_timeout(REFRESH_SECONDS);
                if !self.hidden {
                    self.query_branch();
                }
                false
            }
            // Leaving the bar reports a hover far past its last column
            Event::Mouse(Mouse::Hover(_, col)) => {
                let hover = self.bar.target_at(col);
                let changed = hover != self.hover;
                self.hover = hover;
                changed
            }
            Event::Mouse(Mouse::LeftClick(_, col)) => {
                match self.bar.target_at(col) {
                    Some(render::Target::Badge) => self.run_badge_command(),
                    Some(render::Target::Tab(position)) => switch_tab_to(position as u32 + 1),
                    None => {}
                }
                false
            }
            _ => false,
        }
    }

    fn render(&mut self, _rows: usize, cols: usize) {
        let tabs: Vec<render::Tab> = self
            .tabs
            .iter()
            .map(|t| render::Tab {
                position: t.position,
                name: t.name.clone(),
                active: t.active,
            })
            .collect();
        let mode = format!("{:?}", self.mode.mode);
        self.bar = render::render(&render::Input {
            glyphs: &self.glyphs,
            session: self.mode.session_name.as_deref().unwrap_or(""),
            branch: self
                .cwd
                .as_ref()
                .and_then(|d| self.branches.get(d))
                .map(String::as_str),
            tabs: &tabs,
            mode: &mode,
            cols,
            hover: self.hover,
        });
        print!("{}", self.bar.line);
    }
}

#[cfg(target_family = "wasm")]
impl State {
    /// The focused terminal pane of the active tab, preferring a floating one
    /// while floating panes are shown.
    fn focused_pane(&self) -> Option<PaneId> {
        let tab = self.tabs.iter().find(|t| t.active)?;
        let panes = self.panes.panes.get(&tab.position)?;
        let focused = |floating: bool| {
            panes
                .iter()
                .find(|p| p.is_focused && !p.is_plugin && p.is_floating == floating)
        };
        tab.are_floating_panes_visible
            .then(|| focused(true))
            .flatten()
            .or_else(|| focused(false))
            .map(|p| PaneId::Terminal(p.id))
    }

    fn follow_focus(&mut self) {
        let pane = self.focused_pane();
        if pane == self.focused {
            return;
        }
        self.focused = pane;
        let cwd = pane.and_then(|p| get_pane_cwd(p).ok());
        self.set_cwd(cwd);
    }

    /// Whether the bar needs redrawing.
    fn set_cwd(&mut self, cwd: Option<PathBuf>) -> bool {
        if cwd == self.cwd {
            return false;
        }
        self.cwd = cwd;
        self.query_branch();
        true
    }

    fn query_branch(&self) {
        let (Some(cwd), false) = (&self.cwd, self.branch_command.is_empty()) else {
            return;
        };
        let cmd: Vec<&str> = self.branch_command.iter().map(String::as_str).collect();
        let context = BTreeMap::from([("cwd".to_owned(), cwd.to_string_lossy().into_owned())]);
        run_command_with_env_variables_and_cwd(&cmd, BTreeMap::new(), cwd.clone(), context);
    }

    /// A floating terminal pane named `badge_pane` in the active tab.
    fn badge_pane(&self) -> Option<u32> {
        let name = self.badge_pane.as_deref()?;
        let tab = self.tabs.iter().find(|t| t.active)?;
        self.panes
            .panes
            .get(&tab.position)?
            .iter()
            .find(|p| p.is_floating && !p.is_plugin && p.title == name)
            .map(|p| p.id)
    }

    /// Closes the badge's pane if it is open, else runs `badge_command`.
    fn run_badge_command(&self) {
        if let Some(id) = self.badge_pane() {
            close_terminal_pane(id);
            return;
        }
        if self.badge_command.is_empty() {
            return;
        }
        let cmd: Vec<&str> = self.badge_command.iter().map(String::as_str).collect();
        run_command(&cmd, BTreeMap::new());
    }
}
