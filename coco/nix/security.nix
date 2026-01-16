{ ... }:

{
  security.pam.services.swaylock = { };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
