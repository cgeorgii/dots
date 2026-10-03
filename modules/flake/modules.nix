{ inputs, ... }:

{
  # flake.modules.<class>.<name>: features publish nixos and homeManager
  # modules under a shared name, and hosts compose them.
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];
}
