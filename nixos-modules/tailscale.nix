{config, lib, pkgs, ...}:
{
  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=llego" ];
  };
}
