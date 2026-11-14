//! Background zellij plugin: tabs are named after their focused pane
//! ([`tabs`]).
//!
//! Configuration: `max_length` (characters, default 24, 0 for no limit).

mod tabs;

#[cfg(not(target_family = "wasm"))]
fn main() {}

#[cfg(target_family = "wasm")]
use zellij_tile::prelude::*;

#[cfg(target_family = "wasm")]
register_plugin!(State);

#[cfg(target_family = "wasm")]
#[derive(Default)]
struct State {
    namer: tabs::Namer,
    mode: InputMode,
    tabs: Vec<TabInfo>,
    panes: PaneManifest,
}

#[cfg(target_family = "wasm")]
impl ZellijPlugin for State {
    fn load(&mut self, configuration: std::collections::BTreeMap<String, String>) {
        let max_len = configuration
            .get("max_length")
            .and_then(|v| v.parse().ok())
            .unwrap_or(24);
        self.namer = tabs::Namer::new(max_len);
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        subscribe(&[
            EventType::ModeUpdate,
            EventType::TabUpdate,
            EventType::PaneUpdate,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        let mut settled = false;
        match event {
            Event::ModeUpdate(info) => {
                settled = self.mode == InputMode::RenameTab && info.mode != InputMode::RenameTab;
                self.mode = info.mode;
            }
            Event::TabUpdate(tabs) => self.tabs = tabs,
            Event::PaneUpdate(panes) => self.panes = panes,
            _ => {}
        }
        self.rename(settled);
        false
    }
}

#[cfg(target_family = "wasm")]
impl State {
    /// `settled`: a rename typed in RenameTab mode just ended.
    fn rename(&mut self, settled: bool) {
        // Mid-rename the name is the user's half-typed input
        if self.mode == InputMode::RenameTab {
            return;
        }
        let tabs: Vec<tabs::Tab> = self
            .tabs
            .iter()
            .map(|t| tabs::Tab {
                id: t.tab_id as u64,
                name: t.name.clone(),
                focused_title: self.panes.panes.get(&t.position).and_then(|panes| {
                    panes
                        .iter()
                        .find(|p| {
                            p.is_focused && !p.is_floating && !p.is_plugin && !p.is_suppressed
                        })
                        .map(|p| p.title.clone())
                }),
            })
            .collect();
        for (id, name) in self.namer.plan(&tabs, settled) {
            rename_tab_with_id(id, name);
        }
    }
}
