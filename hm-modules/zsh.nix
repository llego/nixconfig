{config, pkgs, ...}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l="lsd";
      ll = "lsd -al";
      tree = "lsd --tree";
      fastfetch = "fastfetch -c paleofetch.jsonc";
      nixosswitch-default = "sudo nixos-rebuild switch --flake ~/nixconfig#default";
      hmswitch-default = "home-manager switch --flake ~/nixconfig#default";
      nixosswitch-jail = "sudo nixos-rebuild switch --flake ~/nixconfig#jail";
      hmswitch-jail = "home-manager switch --flake ~/nixconfig#jail";
      collect-garbage = "nix-collect-garbage -d";
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
