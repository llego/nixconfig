{ pkgs, ... }:
{
  xdg.desktopEntries = {
    ssh-docker = {
      name = "docker.home";
      genericName = "ssh into llego@docker.home";
      exec = "kitty -- ssh llego@docker.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-truenas = {
      name = "truenas.home";
      genericName = "ssh into admin@truenas.home";
      exec = "kitty -- ssh admin@truenas.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-christiansandberg = {
      name = "christiansandberg.fi";
      exec = "kitty -- ssh llego@christiansandberg.fi";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi3 = {
      name = "rpi3.home";
      exec = "kitty -- ssh pi@rpi3.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi4 = {
      name = "rpi4.home";
      exec = "kitty -- ssh pi@rpi4.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpizero = {
      name = "rpizero.home";
      exec = "kitty -- ssh pi@rpizero.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  };
  
}
