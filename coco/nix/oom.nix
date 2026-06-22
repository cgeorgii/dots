{ ... }:

{
  # Userspace early-OOM killer.
  #
  # This machine has a large (34 GiB) swap partition. When memory fills up the
  # kernel thrashes that swap for a long time before its own OOM killer fires,
  # which presents as a total freeze. earlyoom watches available RAM and kills
  # the heaviest process early, before the thrash begins. Every kill is logged
  # to the journal (`journalctl -u earlyoom`) and raised as a desktop
  # notification.
  services.earlyoom = {
    enable = true;

    # SIGTERM once available RAM drops below 10%, SIGKILL below 5%.
    freeMemThreshold = 10;
    freeMemKillThreshold = 5;

    # earlyoom only acts when BOTH the memory AND swap thresholds are crossed.
    # With low swappiness the swap partition stays mostly empty, so free swap
    # sits near 100% and would never cross a normal threshold, neutering the
    # killer. Pinning both swap thresholds to 100% makes the swap condition
    # always true, so the decision is driven purely by available RAM.
    freeSwapThreshold = 100;
    freeSwapKillThreshold = 100;

    # Notify the desktop session when something gets killed.
    enableNotifications = true;

    # Periodic memory report to the journal (heartbeat for diagnosis).
    reportInterval = 3600;

    # Spare core session components from being picked as the victim.
    extraArgs = [
      "--avoid"
      "^(systemd|Xorg|niri|swaylock|pipewire|wireplumber|swaync|greetd)$"
    ];
  };

  # Prefer reclaiming page cache over swapping. This keeps the big swap
  # partition mostly idle, reducing the thrash that causes the freeze.
  boot.kernel.sysctl."vm.swappiness" = 10;
}
