{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l = "${pkgs.lsd}/bin/lsd";
      ll = "${pkgs.lsd}/bin/lsd -al";
      tree = "${pkgs.lsd}/bin/lsd --tree";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreSpace = true;
      ignoreDups = true;
      share = true;
      append = true;
    };

    initExtra = ''
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

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    #useTheme = "tokyonight_storm";
    #useTheme = "pure";
    #useTheme = "bubbles";
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ../../assets/ohmyposh-bubbles2.json));
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
