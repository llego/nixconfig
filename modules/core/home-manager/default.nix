{
  inputs,
  username,
  hostname,
  pkgs,
  config,
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
      inherit hostname;
    };

    users.${username} = {
      xdg.enable = true;

      # Git
      programs.git = {
        enable = true;
        settings = {
          user.email = "github.login@cri.su";
          user.name = "${username}";
          init.defaultBranch = "main";
        };
      };

      /*
      # Zsh
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          l = "${pkgs.lsd}/bin/lsd";
          ll = "${pkgs.lsd}/bin/lsd -al";
          tree = "${pkgs.lsd}/bin/lsd -a --tree";
        };

        history = {
          size = 10000;
          path = "${config.home-manager.users.${username}.xdg.dataHome}/zsh/history";
          ignoreSpace = true;
          ignoreDups = true;
          share = true;
          append = true;
        };

        initContent = ''
          ${pkgs.nitch}/bin/nitch
          bindkey -e
          bindkey "''${key[Up]}" up-line-or-search
          bindkey '^[[1;5C' emacs-forward-word
          bindkey '^[[1;5D' emacs-backward-word
          bindkey '^p' history-search-backward
          bindkey '^n' history-search-forward
          bindkey '^[w' kill-region
          bindkey '^[[3~' delete-char
        '';
      };

      # Oh My Posh for Zsh
      programs.oh-my-posh = {
        enable = true;
        enableZshIntegration = true;
        #useTheme = "tokyonight_storm";
        #useTheme = "pure";
        #useTheme = "bubbles";
        settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./ohmyposh-bubbles2.json));
      };

      # Fuzzy search for Zsh
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      */
    };
  };
}
