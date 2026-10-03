{
  flake.modules.homeManager.starship =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.starship ];

      programs.starship = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          character = {
            format = "$symbol ";
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
            vicmd_symbol = "[❮](bold red)";
          };

          battery.disabled = true;
          package.disabled = true;
          gcloud.disabled = true;

          git_branch = {
            format = "[$symbol$branch(:$remote_branch)]($style) ";
          };

          nix_shell = {
            format = "[$symbol$name]($style) ";
            impure_msg = "";
            symbol = "❄️ ";
          };

          # Language/environment modules - all use consistent format
          haskell.format = "[λ $version]($style) ";
        };
      };
    };
}
