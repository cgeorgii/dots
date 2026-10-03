{ self, inputs, ... }:

{
  perSystem =
    { system, ... }:
    let
      firefox-pkgs = import inputs.nixpkgs-for-firefox { inherit system; };
    in
    {
      # DoH runs over 443, which restrictive networks cannot blanket-block the way
      # they block DoT on 853, and Firefox suspends it behind captive portals until
      # the login completes. Unlocked so it can be turned off in the UI.
      packages.firefox = firefox-pkgs.firefox.override {
        extraPolicies = {
          DNSOverHTTPS = {
            Enabled = true;
            ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
            Locked = false;
          };
        };
      };
    };

  flake.modules.nixos.firefox =
    { pkgs, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.firefox ];
    };

  flake.modules.homeManager.firefox = {
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
    };
  };
}
