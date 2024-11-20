{...}: {
  xdg.desktopEntries = {
    ssh-docker = {
      name = "docker.home";
      genericName = "ssh into llego@docker.home";
      exec = "alacritty -e ssh llego@docker.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-truenas = {
      name = "truenas.home";
      genericName = "ssh into admin@truenas.home";
      exec = "alacritty -e ssh admin@truenas.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-christiansandberg = {
      name = "christiansandberg.fi";
      exec = "alacritty -e ssh llego@christiansandberg.fi";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpi3 = {
      name = "rpi3.home";
      exec = "alacritty -e ssh pi@rpi3.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpi4 = {
      name = "rpi4.home";
      exec = "alacritty -e ssh pi@rpi4.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpizero = {
      name = "rpizero.home";
      exec = "alacritty -e ssh llego@rpizero.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  };
}
