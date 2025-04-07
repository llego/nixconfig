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
    [storj]
    type = s3
    provider = Storj
    access_key_id = secret123456
    secret_access_key = secret123456
    endpoint = gateway.storjshare.io
    chunk_size = 64Mi
    disable_checksum: true%
  '';
  */
}
