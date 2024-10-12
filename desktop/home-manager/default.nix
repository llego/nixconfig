{ inputs, username, host, git-email, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit username;
      inherit inputs;
      inherit host;
      inherit git-email;
    };
    users.llego.imports = [ ./user ];
  };
}
