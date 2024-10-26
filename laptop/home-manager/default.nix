{
  inputs,
  username,
  hostname,
  git-email,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit username;
      inherit hostname;
      inherit git-email;
    };
  };
}
