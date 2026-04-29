{lib, ...}: {
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # allowDiscards enables TRIM passthrough for SSD health/performance.
              # Safe to use: LUKS2 does not leak meaningful data via discard patterns.
              settings = {
                allowDiscards = true;
                # tpm2-device=auto tells systemd-cryptsetup in the initrd to attempt
                # TPM2 unlock automatically. Requires enrolling TPM2 post-install with:
                #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
                # Passphrase remains as fallback if TPM2 fails.
                crypttabExtraOpts = ["tpm2-device=auto"];
              };
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };
}
