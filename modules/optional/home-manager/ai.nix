{pkgs, ...}: {
  home.packages = with pkgs; [
    fabric-ai
    glow
  ];

  home.file.fabric-conf = {
    enable = true;
    target = ".config/fabric/.env";
    text = ''
      DEFAULT_VENDOR=OpenAI
      DEFAULT_MODEL=gpt-4o-mini
      PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
      PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=patterns
      OPENAI_API_KEY=REDACTED_OPENAI_API_KEY
      OPENAI_API_BASE_URL=https://api.openai.com/v1
      YOUTUBE_API_KEY=REDACTED_YOUTUBE_API_KEY
    '';
  };

  programs.zsh = {
    shellAliases = {
      summarize = "${pkgs.fabric-ai}/bin/fabric --pattern summarize";
      summarize_md = "${pkgs.fabric-ai}/bin/fabric --pattern summarize | ${pkgs.glow}/bin/glow -";
      extract_wisdom = "${pkgs.fabric-ai}/bin/fabric --pattern extract_wisdom";
      extract_wisdom_md = "${pkgs.fabric-ai}/bin/fabric --pattern extract_wisdom | ${pkgs.glow}/bin/glow -";
      youtube_transcript = "${pkgs.fabric-ai}/bin/fabric --transcript --youtube";
    };
  };
}
