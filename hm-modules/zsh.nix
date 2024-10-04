{config, pkgs, ...}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l="${pkgs.lsd}/bin/lsd";
      ll = "${pkgs.lsd}/bin/lsd -al";
      tree = "${pkgs.lsd}/bin/lsd --tree";
      fastfetch = "${pkgs.fastfetch}/bin/fastfetch -c paleofetch.jsonc";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreSpace = true;
      ignoreDups = true;
      share = true;              
    };

    initExtra = '' 
      source ~/.p10k.zsh
      ${pkgs.nitch}/bin/nitch
      [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
      bindkey -e
      bindkey "''${key[Up]}" up-line-or-search
      bindkey '^[[1;5C' emacs-forward-word
      bindkey '^[[1;5D' emacs-backward-word
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^[w' kill-region
      bindkey '^[[3~'  delete-char
      '';

    plugins = [
       {
         name = "powerlevel10k";                                                           
         src = pkgs.zsh-powerlevel10k;                                                     
         file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
       } 
    ];
  };
}
