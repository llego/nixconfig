{
  inputs,
  username,
  git-email,
  hostname,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit username;
      inherit git-email;
      inherit hostname;
    };
    # Minimum home-manager user config
    users.${username}.imports = [
      ./cli.nix
      ./desktop-apps.nix
      ./desktopEntries.nix
      ./gtk.nix
      ./zsh.nix
    ];
  };
}
