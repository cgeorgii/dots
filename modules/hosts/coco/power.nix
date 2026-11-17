# CPU power and thermal handling for the X1 Carbon Gen 9 (i7-1165G7).
#
# When the chassis runs hot, the firmware switches the CPU to cTDP down
# (12 W, 1.2 GHz base) and holds it there for minutes. Lap mode, which seems
# to be set off by movement, does the same. Everything here keeps sustained
# power low enough to stay out of that mode, and keeps it bearable when it
# happens anyway.
{
  flake.modules.nixos.coco-power = {
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "powersave";
    };

    services.tlp.settings = {
      # Turbo stays on but is capped at the 2.8 GHz base clock: bursts to
      # 4.7 GHz drive the package into TCC throttling, stalling every core for
      # up to ~130 ms at a time. Turning turbo off instead pins the clock to
      # the base, which the firmware's hot mode (cTDP down) drops to 1.2 GHz.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_SCALING_MAX_FREQ_ON_AC = 2800000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 2800000;
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };

    # Sustained package power above ~15 W heats the chassis until the firmware
    # switches to cTDP down (12 W, 1.2 GHz base) for minutes after it cools.
    # Holding PL1 at 15 W keeps bursts at full clock while sustained load
    # settles below that point. The firmware rewrites PL1 on mode changes, so
    # this reapplies it, and only ever lowers it, leaving the firmware's
    # stricter limits alone.
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
      # The package obeys the lower of two PL1 copies: the MMIO one, which the
      # firmware rewrites, and the MSR one, which it leaves alone. A short
      # averaging window keeps bursts above PL1 to seconds instead of ~28 s.
      script = ''
        limit=15000000
        window=8000000
        for rapl in /sys/class/powercap/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio:0; do
          pl1=$rapl/constraint_0_power_limit_uw
          [[ -w $pl1 ]] || continue
          if (( $(<"$pl1") > limit )); then
            echo "$limit" >"$pl1"
          fi
          if (( $(<"$rapl/constraint_0_time_window_us") > window )); then
            echo "$window" >"$rapl/constraint_0_time_window_us"
          fi
        done
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
  };
}
