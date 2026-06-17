{
  config,
  inputs,
  ...
}: let
  net = config.networkVars;
in {
  imports = ["${inputs.hetzner_ddns}/release/NixOS/nixos_module.nix"];

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      # Allow crisuflix (via Tailscale) to reach Redis for traefik-kop
      extraCommands = ''
        iptables -w -I nixos-fw -p tcp -s ${net.hosts.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -w -D nixos-fw -p tcp -s ${net.hosts.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  services.hetzner_ddns = {
    enable = true;
    zones = [
      {
        domain = "cri.su";
        records = [{name = "@";}];
      }
      {
        domain = "christiansandberg.fi";
        records = [{name = "@";}];
      }
      {
        domain = "sandbergs.fi";
        records = [{name = "@";}];
      }
      {
        domain = "crisusandberg.fi";
        records = [{name = "@";}];
      }
      {
        domain = "csandberg.fi";
        records = [{name = "@";}];
      }
    ];
    protections = true; # enables protection settings in the systemd service. might cause permission problems with reading the api_key_file
    api_key_file = "/run/credentials/hetzner_ddns.service/hetzner-dns-token";
  };

  systemd.services.hetzner_ddns.serviceConfig.LoadCredential = "hetzner-dns-token:${config.age.secrets.hetzner-dns-token.path}";
}
