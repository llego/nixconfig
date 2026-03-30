{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    usbutils
    stow
    atool
    btop
    bat
    lsd
    ncdu
    jq
    wget
    curl
    helix # text editor
    yazi # file manager
    lazygit # git
    oh-my-posh
    fzf
  ];

  environment.sessionVariables = {
    EDITOR = "hx"; # Set default text editor
    # Store oh-my-posh cache in /tmp to prevent stale cache accumulation
    OMP_CACHE_DIR = "/tmp";
  };

  # oh-my-posh config
  environment.etc."oh-my-posh/config.json".text = builtins.readFile ./oh-my-posh-config.json;

  # Zsh configuration
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    enableGlobalCompInit = true;

    # Shell aliases
    shellAliases = {
      l = "lsd";
      ll = "lsd -al";
      ltree = "lsd -a --tree";
      yz = "yazi";
    };

    # History settings
    histSize = 10000;
    histFile = "$HOME/.local/share/zsh/history";

    # Runs for interactive shells
    interactiveShellInit = ''
      # Ensure history directory exists
      mkdir -p "''${HISTFILE:h}"

      # History options
      setopt APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
      setopt HIST_FCNTL_LOCK
      unsetopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
      unsetopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

      # fzf integration
      if [[ $options[zle] = on ]]; then
        source <(fzf --zsh)
      fi

      # oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config /etc/oh-my-posh/config.json)"

      # Key bindings
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
}
