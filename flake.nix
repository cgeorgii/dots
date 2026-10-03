{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-claude.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-for-signal.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-spotify.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-discord.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-element-desktop.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-firefox.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-keepassxc.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-logseq.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-mullvad.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-niri.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    workmux.url = "github:raine/workmux";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-taskbar = {
      url = "github:cgeorgii/niri-taskbar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    schemes.url = "github:tinted-theming/schemes";
    schemes.flake = false;
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
