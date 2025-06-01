{
  inputs,
  username,
  hostname,
  ...
}: {
  imports = [];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit username;
      inherit hostname;
    };

    # Minimum home-manager user config
    users.${username}.imports = [
      ./cli.nix
      ./zsh
    ];
  };
}
