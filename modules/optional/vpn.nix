{
  pkgs,
  username,
  ...
}: {
  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=${username}"];
  };

  # Mullvad VPN
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # This is required in order for Mullvad to work
  services.resolved.enable = true;
}
