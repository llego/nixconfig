{
  networking.networkmanager.ensureProfiles.profiles = {
    crona_elisa = {
      connection = {
        id = "crona_elisa";
        type = "wifi";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        method = "auto";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "crona_elisa";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "2c8dcf4fbc5236fce97c79cfce7f89b56c94af9528a80ac8e85accc797225140";
      };
    };
  };
}
