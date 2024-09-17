{config, pkgs, ...}:
{
  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=llego" ];
  };
}
