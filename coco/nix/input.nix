{ ... }:

{
  # If changing any of the keyboard settings for xkb, make sure to run:
  # $ gsettings reset org.gnome.desktop.input-sources xkb-options
  # $ gsettings reset org.gnome.desktop.input-sources sources
  # # sudo nixos-rebuild switch
  # $ reboot
  services.xserver = {
    exportConfiguration = true;
    xkb = {
      layout = "us, us(intl)";
      options = "grp:alts_toggle, caps:escape, lv3:ralt_switch";
    };
  };
}
