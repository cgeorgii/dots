{ config, pkgs, ... }:

{
  imports =
    [ ./users/cgeorgii.nix
      ./common.nix
    ];
}
