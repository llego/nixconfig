{lib, ...}: {
  disko.devices = {
    disk.boot = {
      # Standalone NixOS boot/root disk. Do not point this at the illby NVMe mirror.
      device = lib.mkDefault "/dev/disk/by-id/nvme-eui.0026b7282669e9f5";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02"; # BIOS boot
          };
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "nixos";
            };
          };
        };
      };
    };
    lvm_vg = {
      nixos = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
        };
      };
    };
  };
}
