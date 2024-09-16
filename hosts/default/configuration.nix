# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../nixos-modules/main-user.nix
      ../../nixos-modules/networking.nix
      ../../nixos-modules/systempackages.nix
      ../../nixos-modules/tailscale.nix
      ../../nixos-modules/mullvad.nix
      ../../nixos-modules/docker.nix
      ../../nixos-modules/sand.berg-certificates.nix
      ../../nixos-modules/intel-hw-acceleration.nix
      ../../nixos-modules/internationalization.nix
      ../../nixos-modules/xserver.nix
    ];
    
  # Nix Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Import main-user llego
  main-user.enable = true;
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  system.stateVersion = "24.05";

}

