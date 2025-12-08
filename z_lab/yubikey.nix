{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubioath-flutter
    pcsclite
    ccid
  ];
  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];
}
