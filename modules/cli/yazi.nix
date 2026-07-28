{pkgs, ...}: let
  initLua = pkgs.writeText "yazi-init.lua" ''
    require("git"):setup {
      order = 1400,
    }

    require("zfs"):setup()

    Status:children_add(function()
      local h = cx.active.current.hovered
      if not h or ya.target_family() ~= "unix" then
        return ""
      end

      return ui.Line {
        ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
        ":",
        ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
        " ",
      }
    end, 500, Status.RIGHT)
  '';

  zfsYazi = pkgs.writeTextDir "main.lua" ''
    --- @since 26.5.6

    local ZFS_SIGN = "ZFS"

    local function unescape_mount_path(path)
      return path:gsub("\\([0-7][0-7][0-7])", function(oct)
        return string.char(tonumber(oct, 8))
      end)
    end

    local function zfs_mounts()
      local mounts = {}
      local file = io.open("/proc/self/mountinfo", "r")
      if not file then
        return mounts
      end

      for line in file:lines() do
        local before, after = line:match("^(.-) %- (.*)$")
        if before and after then
          local mountpoint = before:match("^%S+ %S+ %S+ %S+ (%S+)")
          local fstype, source = after:match("^(%S+) (%S+)")
          if mountpoint and fstype == "zfs" then
            mounts[unescape_mount_path(mountpoint)] = unescape_mount_path(source or "")
          end
        end
      end

      file:close()
      return mounts
    end

    local add = ya.sync(function(state, items)
      state.datasets = state.datasets or {}
      for path, dataset in pairs(items) do
        if dataset == false then
          state.datasets[path] = nil
        else
          state.datasets[path] = dataset
        end
      end
      ui.render()
    end)

    local function setup(state, opts)
      state.datasets = {}
      opts = opts or {}
      opts.order = opts.order or 1500

      Linemode:children_add(function(self)
        if not self._file.in_current then
          return ""
        end

        local dataset = state.datasets[tostring(self._file.url)]
        if not dataset then
          return ""
        end

        local sign = opts.show_name and dataset or ZFS_SIGN
        if self._file.is_hovered then
          return ui.Line { " ", sign }
        else
          return ui.Line { " ", ui.Span(sign):fg("cyan") }
        end
      end, opts.order)
    end

    local function fetch(_, job)
      local mounts = zfs_mounts()
      local items = {}

      for _, file in ipairs(job.files) do
        local path = tostring(file.url)
        items[path] = file.cha.is_dir and mounts[path] or false
      end

      add(items)
      return true
    end

    return { setup = setup, fetch = fetch }
  '';

  eldritchFlavor = pkgs.writeTextDir "flavor.toml" ''
    #:schema = "https://yazi-rs.github.io/schemas/theme.json"

    [mgr]
    cwd = { fg = "#04d1f9" }
    find_keyword = { fg = "#f1fc79", bold = true, italic = true, underline = true }
    find_position = { fg = "#f265b5", bg = "reset", bold = true, italic = true }
    symlink_target = { italic = true }
    marker_copied = { fg = "#37f499", bg = "#37f499" }
    marker_cut = { fg = "#f16c75", bg = "#f16c75" }
    marker_marked = { fg = "#a48cf2", bg = "#a48cf2" }
    marker_selected = { fg = "#f7c67f", bg = "#f7c67f" }
    count_copied = { fg = "#212337", bg = "#37f499" }
    count_cut = { fg = "#212337", bg = "#f16c75" }
    count_selected = { fg = "#212337", bg = "#f7c67f" }
    border_symbol = "│"
    border_style = { fg = "#a48cf2" }


    [tabs]
    active = { fg = "#212337", bg = "#04d1f9", bold = true }
    inactive = { fg = "#04d1f9", bg = "#292e42" }
    sep_inner = { open = "", close = "" }
    sep_outer = { open = "", close = "" }


    [mode]
    normal_main = { fg = "#212337", bg = "#04d1f9", bold = true }
    normal_alt = { fg = "#04d1f9", bg = "#292e42" }
    select_main = { fg = "#212337", bg = "#a48cf2", bold = true }
    select_alt = { fg = "#a48cf2", bg = "#292e42" }
    unset_main = { fg = "#212337", bg = "#f16c75", bold = true }
    unset_alt = { fg = "#f16c75", bg = "#292e42" }


    [indicator]
    parent = { reversed = true, fg = "#04d1f9" }
    current = { reversed = true, fg = "#04d1f9" }
    preview = { underline = true, fg = "#04d1f9" }
    padding = { open = "█", close = "█" }


    [status]
    overall = {}
    sep_left = { open = "", close = "" }
    sep_right = { open = "", close = "" }
    perm_sep = { fg = "#ABB4DA" }
    perm_type = { fg = "#04d1f9" }
    perm_read = { fg = "#f1fc79" }
    perm_write = { fg = "#f16c75" }
    perm_exec = { fg = "#37f499" }
    progress_label = { fg = "#ebfafa", bold = true }
    progress_normal = { fg = "#a48cf2", bg = "#292e42" }
    progress_error = { fg = "#292e42", bg = "#f16c75" }


    [which]
    cols = 3
    mask = { bg = "#171928" }
    cand = { fg = "#04d1f9", bold = true }
    rest = { fg = "#7081d0" }
    desc = { fg = "#7081d0", italic = true }
    separator = "  "
    separator_style = { fg = "#7081d0" }


    [confirm]
    border = { fg = "#04d1f9", bold = true }
    title = { fg = "#04d1f9" }
    body = { fg = "#7081d0" }
    list = { fg = "#ebfafa" }
    btn_yes = { fg = "#ebfafa", bg = "#292e42", bold = true }
    btn_no = { fg = "#ABB4DA" }
    btn_labels = ["  [Y]es  ", "  (N)o  "]


    [spot]
    border = { fg = "#04d1f9", bold = true }
    title = { fg = "#04d1f9" }
    tbl_col = { fg = "#7081d0" }
    tbl_cell = { fg = "#04d1f9", bg = "#292e42", bold = true }


    [notify]
    title_info = { fg = "#37f499" }
    title_warn = { fg = "#f7c67f" }
    title_error = { fg = "#f16c75" }
    icon_info = ""
    icon_warn = ""
    icon_error = ""


    [pick]
    border = { fg = "#04d1f9", bold = true }
    active = { fg = "#04d1f9", bold = true }
    inactive = { fg = "#7081d0" }


    [input]
    border = { fg = "#04d1f9", bold = true }
    title = { fg = "#04d1f9" }
    value = { fg = "#ebfafa" }
    selected = { reversed = true }


    [cmp]
    border = { fg = "#04d1f9", bold = true }
    active = { reversed = true }
    inactive = {}


    [tasks]
    border = { fg = "#04d1f9", bold = true }
    title = { fg = "#04d1f9" }
    hovered = { fg = "#f265b5", bold = true }


    [help]
    on = { fg = "#04d1f9" }
    run = { fg = "magenta" }
    desc = { fg = "#7081d0" }
    hovered = { bg = "#292e42", bold = true }
    footer = { fg = "#ebfafa", bg = "#292e42" }


    [filetype]
    rules = [
      # Image
      { mime = "image/*", fg = "#04d1f9" },
      # Media
      { mime = "video/*", fg = "#f1fc79" },
      { mime = "audio/*", fg = "#f1fc79" },
      # Archive
      { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "#f265b5" },
      # Document
      { mime = "application/{pdf,doc,rtf}", fg = "#37f499" },
      # Virtual file system
      { mime = "vfs/{absent,stale}", fg = "#7081d0" },
      # Special file
      { url = "*", is = "orphan", bg = "#f16c75" },
      { url = "*", is = "exec", fg = "#37f499" },
      # Symbolic link
      { url = "*", is = "link", fg = "#04d1f9" },
      # Dummy file
      { url = "*", is = "dummy", bg = "#f16c75" },
      { url = "*/", is = "dummy", bg = "#f16c75" },
      # Fallback
      { url = "*/", fg = "#a48cf2" },
    ]
  '';
in {
  programs.yazi = {
    enable = true;
    initLua = initLua;

    plugins = {
      git = pkgs.yaziPlugins.git;
      zfs = zfsYazi;
    };

    flavors = {
      eldritch = eldritchFlavor;
    };

    settings = {
      yazi = {
        mgr.show_hidden = true;
        plugin.prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "zfs";
            group = "zfs";
          }
        ];
      };

      theme = {
        flavor = {
          dark = "eldritch";
          light = "eldritch";
        };
      };
    };
  };
}
