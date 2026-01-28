{
  config,
  pkgs,
  inputs,
  ...
}: let
  noctaliaShell = "${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell";
in {
  # ensure binaries exist system-wide (optional but recommended)
  environment.systemPackages = with pkgs; [
    swayidle
  ];

  systemd.user.services.swayidle = {
    description = "Idle manager (swayidle)";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          before-sleep '${noctaliaShell} ipc call lockScreen lock' \
          timeout 300  '${pkgs.niri}/bin/niri msg action power-off-monitors' \
          timeout 600  '${noctaliaShell} ipc call lockScreen lock' \
          timeout 1200 '${pkgs.systemd}/bin/systemctl suspend'
      '';
      Restart = "on-failure";
    };
  };
}
