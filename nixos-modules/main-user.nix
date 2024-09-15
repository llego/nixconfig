{ lib, config, pkgs, ... }:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable 
      = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "llego";
    };
    description = lib.mkOption {
      default = "Christian Sandberg";
    };
    
    extraGroups = lib.mkOption {
      default = [ "networkmanager" "wheel" ];
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      initialPassword = "12345";
		  description = cfg.description;
		  extraGroups = cfg.extraGroups;
      shell = pkgs.zsh;
    };
  };
}
