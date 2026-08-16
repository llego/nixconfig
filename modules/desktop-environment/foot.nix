{...}: {
  programs.foot = {
    enable = true;
    theme = "rose-pine";
    settings = {
      main = {
        font = "Maple Mono NF Light:size=10";
        pad = "10x10";
        title = "foot";
        app-id = "foot";
      };
      bell = {
        urgent = false;
        notify = false;
      };
      scrollback = {
        lines = 250000;
        indicator-position = "relative";
        indicator-format = "percentage";
      };
      colors-dark = {
        alpha = "0.90";
      };
      cursor = {
        style = "block";
        blink = false;
      };
      mouse = {
        hide-when-typing = true;
      };
      csd = {
        preferred = "server";
        size = 26;
      };
      key-bindings = {
        scrollback-up-page = "Shift+Page_Up";
        scrollback-down-page = "Shift+Page_Down";
        scrollback-up-line = "Shift+Up";
        scrollback-down-line = "Shift+Down";
        clipboard-copy = "Control+Shift+c";
        clipboard-paste = "Control+Shift+v";
        primary-paste = "Shift+Insert";
        search-start = "Control+Shift+f";
        font-increase = "Control+plus Control+equal";
        font-decrease = "Control+minus";
        font-reset = "Control+0";
        spawn-terminal = "Control+Shift+n";
        show-urls-launch = "Control+Shift+o";
        quit = "Control+Shift+q";
      };
      search-bindings = {
        cancel = "Escape";
        commit = "Return";
        find-prev = "Control+Shift+n";
        find-next = "Control+n";
      };
      url-bindings = {
        cancel = "Escape Control+c";
        toggle-url-visible = "Control+Shift+u";
      };
    };
  };
}
