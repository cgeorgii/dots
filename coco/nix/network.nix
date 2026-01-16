{ ... }:

{
  networking.hostName = "coco"; # The codependent computer

  # Enable networking
  networking.networkmanager.enable = true;

  networking.extraHosts = ''
    127.0.0.1       zeus-bucket.localhost
    127.0.0.1       dev.zeuslogics.com
  '';

  # Firewall - block all ports by default
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  # DNS Configuration (router already uses 1.1.1.1)
  networking.nameservers = [
    "1.1.1.1#one.one.one.one"
    "1.0.0.1#one.one.one.one"
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];
    dnsovertls = "true";
  };

  # Network performance optimizations for congested ISP connections
  # Based on network diagnostics showing high latency and packet loss

  # TCP BBR congestion control for better performance on congested networks
  # BBR (Bottleneck Bandwidth and Round-trip propagation time) is a modern
  # congestion control algorithm that maintains higher throughput and lower
  # latency on networks with bufferbloat and congestion.
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    # Enable BBR congestion control
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq"; # Fair Queue required for BBR
  };

  # Prefer IPv4 over IPv6 in getaddrinfo() - affects DNS resolution order
  # This helps avoid congested IPv6 routes while keeping IPv6 functional
  # Based on diagnostics showing IPv6 path has higher latency/packet loss
  environment.etc."gai.conf".text = ''
    # Prefer IPv4 over IPv6
    precedence ::ffff:0:0/96  100
  '';
}
