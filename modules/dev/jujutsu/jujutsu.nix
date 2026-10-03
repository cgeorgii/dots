{
  flake.modules.homeManager.jujutsu =
    { pkgs, link-dotfile, ... }:
    {
      home.packages = with pkgs; [
        jjui
        jujutsu
      ];

      xdg.configFile = {
        "jjui/config.toml".source = link-dotfile ./config.toml;
        "jjui/themes".source = link-dotfile ./themes;
      };
    };
}
