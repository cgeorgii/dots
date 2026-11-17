{ self, inputs, ... }:

{
  flake.modules.nixos.coco = {
    imports = [
      ./_hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ (with self.modules.nixos; [
      nix
      base
      cgeorgii
      locale
      network
      work
      security
      git
      sops
      input
      peripherals
      fonts
      audio
      oom
      zsh
      tmux
      neovim
      niri
      files
      firefox
      mullvad
    ]);

    home-manager.users.cgeorgii.imports = with self.modules.homeManager; [
      dotfiles
      cgeorgii
      input
      security
      sops
      zsh
      starship
      cli
      btop
      kitty
      tmux
      zellij
      neovim
      git
      jujutsu
      claude
      niri
      noctalia
      theme
      files
      firefox
      chat
      spotify
      desktop-apps
    ];

    networking.hostName = "coco"; # The codependent computer

    # Bootloader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."luks-d80ba783-00e7-4805-b96f-bb0205ee56aa".device =
      "/dev/disk/by-uuid/d80ba783-00e7-4805-b96f-bb0205ee56aa";

    # Run `captive-browser` from the terminal
    programs.captive-browser = {
      enable = true;

      # Replace "wlan0" with your actual wireless interface name
      # To find out the interface name, run `ip a`
      interface = "wlp0s20f3";

      # # Browser to use for the captive portal
      # browser = lib.getExe pkgs.firefox;
    };

    # Steam stuff
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "powersave";
    };

    services.tlp.settings = {
      # Turbo bursts at the firmware's 64 W PL2 drive the package into TCC
      # throttling, stalling every core for up to ~130 ms at a time
      CPU_BOOST_ON_AC = 0;
      CPU_BOOST_ON_BAT = 0;
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };

    # Sustained package power above ~15 W heats the chassis until the firmware
    # enters lap mode (dytc_lapmode), capping every core at 1.2 GHz and PL1 at
    # 12-15 W for minutes after it cools. Holding PL1 at 15 W keeps bursts at
    # full clock while sustained load settles below that point. The firmware
    # rewrites PL1 on mode changes, so this reapplies it, and only ever lowers
    # it, leaving the firmware's stricter limits alone.
    systemd.services.cap-pl1 = {
      description = "Hold the long-term CPU power limit (PL1) at 15 W";
      wantedBy = [
        "multi-user.target"
        "post-resume.target"
      ];
      after = [ "post-resume.target" ];
      serviceConfig = {
        Type = "oneshot";
        # Runs every 30 s; keep its start/stop lines out of the journal
        LogLevelMax = "warning";
      };
      script = ''
        pl1=/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
        limit=15000000
        [[ -w $pl1 ]] || exit 0
        if (( $(<"$pl1") > limit )); then
          echo "$limit" >"$pl1"
        fi
      '';
    };
    systemd.timers.cap-pl1 = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
        AccuracySec = "5s";
      };
    };

    # The EC-backed acpitz zone sporadically reports 128 °C (0x80, a failed
    # read) and the kernel powers off on it. The CPU still self-throttles via
    # TCC and has its own hardware THERMTRIP.
    boot.kernelParams = [ "thermal.crt=-1" ];

    # Don't suspend when lid is closed (using external monitors)
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
