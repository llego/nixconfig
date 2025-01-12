{
  inputs,
  username,
  git-email,
  hostname,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

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
      ./zsh
    ];
  };
}
