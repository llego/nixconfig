{pkgs, inputs, ...}: {
  environment.systemPackages = with pkgs; [
    claude-code
    opencode
    inputs.agenix.packages.${pkgs.system}.default
  ];
}
