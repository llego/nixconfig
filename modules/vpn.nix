{
  pkgs,
  username,
  ...
}: {
  # Mullvad VPN
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # This is required in order for Mullvad to work
  services.resolved.enable = true;
}
