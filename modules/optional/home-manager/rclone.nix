{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.rclone
    pkgs.storj-uplink
  ];

  xdg.configFile."rclone/rclone.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/llego/rclone-secret.txt";

  /*
    xdg.configFile."rclone/rclone.conf".text = ''
  zzz
    '';
  */
}
