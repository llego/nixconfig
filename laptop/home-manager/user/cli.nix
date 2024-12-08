{
  inputs,
  pkgs,
  username,
  git-email,
  ...
}: {
  # Packages
  home.packages = with pkgs; [
    (writeShellScriptBin "bandcamp-collection" (builtins.readFile ../../../assets/bandcamp-collection/bandcamp-collection.sh))
    inputs.bandsnatch.packages."${pkgs.system}".default
    tidal-dl
    atool
    btop
    yle-dl
    svtplay-dl
    tidal-dl
    neofetch
    bat
    lsd
    nitch
    fastfetch
    wlr-randr
    wdisplays
    mediainfo
  ];

  # vim
  programs.vim = {
    enable = true;
    extraConfig = ''
      set clipboard+=unnamedplus
      set tabstop=2
      set expandtab
      set shiftwidth=2 smarttab
      set autoindent
      set cursorcolumn
      set cursorline
    '';
  };

  # git
  programs.git = {
    enable = true;
    userEmail = "${git-email}";
    userName = "${username}";
  };

  # tidal-dl configuration
  home.file.tidal-dl-conf = {
    enable = true;
    source = ../../../assets/.tidal-dl.json;
    target = ".tidal-dl.json";
  };

  # lf file manager
  xdg.configFile."lf/icons".source = ../../../assets/icons;
  programs.lf = {
    enable = true;
    commands = {
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
          printf "Directory Name: "
          read DIR
          mkdir $DIR
        }}
      '';
    };

    keybindings = {
      o = "";
      c = "mkdir";
      "." = "set hidden!";
      "<enter>" = "open";
    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };

    extraConfig = let
      previewer = pkgs.writeShellScriptBin "pv.sh" ''
        file=$1
        w=$2
        h=$3
        x=$4
        y=$5

        if [[ "$( ${pkgs.file}/bin/file -Lb --mime-type "$file")" =~ ^image ]]; then
            ${pkgs.kitty}/bin/kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
            exit 1
        fi

        ${pkgs.pistol}/bin/pistol "$file"
      '';
      cleaner = pkgs.writeShellScriptBin "clean.sh" ''
        ${pkgs.kitty}/bin/kitty +kitten icat --clear --stdin no --silent --transfer-mode file < /dev/null > /dev/tty
      '';
    in ''
      set cleaner ${cleaner}/bin/clean.sh
      set previewer ${previewer}/bin/pv.sh
    '';
  };
}
