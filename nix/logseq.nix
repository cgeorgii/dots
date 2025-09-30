{ pkgs, ... }:

{
  # Add logseq to system packages
  environment.systemPackages = with pkgs; [
    logseq
  ];

  # Allow unfree license for logseq
  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "logseq"
    ];
  };
}
