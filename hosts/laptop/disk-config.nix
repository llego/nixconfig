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
                # TPM2 disabled for reliability - using passphrase-only unlock
                # Traditional initrd handles passphrase unlock without extra options
                crypttabExtraOpts = [];
                # nixos-anywhere uploads the passphrase to this path before disko runs.
                # The file is ephemeral — only exists in the installer RAM environment.
                keyFile = "/tmp/disk.key";
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
