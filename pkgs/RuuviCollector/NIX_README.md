# RuuviCollector Nix Flake

This directory contains a Nix flake for building and running RuuviCollector on NixOS, including support for Raspberry Pi (aarch64).

## Features

- Builds RuuviCollector using Maven
- NixOS module with comprehensive configuration options
- Systemd services for both BLE scanning and data collection
- Automatic Bluetooth capability management
- Support for both x86_64-linux and aarch64-linux (Raspberry Pi)
- Configuration via Nix options instead of property files

## Quick Start

### 1. Add to your flake inputs

In your NixOS configuration flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruuvi-collector.url = "path:/path/to/RuuviCollector";
    # Or from git:
    # ruuvi-collector.url = "github:Scrin/RuuviCollector";
  };

  outputs = { self, nixpkgs, ruuvi-collector, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";  # or "x86_64-linux"
      modules = [
        ruuvi-collector.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Configure the service

In your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  services.ruuvi-collector = {
    enable = true;

    # InfluxDB settings
    influxUrl = "http://localhost:8086";
    influxDatabase = "ruuvi";
    influxUser = "ruuvi";
    influxPasswordFile = "/run/secrets/influxdb-password";

    # Give friendly names to your tags
    tagNames = {
      "D04AB59C588B" = "Living Room";
      "D944923E0B70" = "Balcony";
      "F97C9896E88F" = "Fridge";
    };

    # Only collect from named tags
    filterMode = "named";

    # Include calculated values
    storageValues = "extended";
  };
}
```

### 3. Deploy

```bash
nixos-rebuild switch --flake .#your-hostname
```

## Configuration Options

### InfluxDB Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `influxUrl` | string | `"http://localhost:8086"` | InfluxDB URL |
| `influxDatabase` | string | `"ruuvi"` | Database name |
| `influxMeasurement` | string | `"ruuvi_measurements"` | Measurement name |
| `influxUser` | string or null | `null` | Username |
| `influxPassword` | string or null | `null` | Password (use influxPasswordFile instead) |
| `influxPasswordFile` | path or null | `null` | File containing password |
| `influxRetentionPolicy` | string | `"autogen"` | Retention policy |
| `influxGzip` | bool | `true` | Use gzip compression |
| `influxBatch` | bool | `true` | Use batch mode |
| `influxBatchMaxSize` | int | `2000` | Max datapoints per batch |
| `influxBatchMaxTime` | int | `100` | Max time (ms) before sending batch |
| `exitOnInfluxDBIOException` | bool | `false` | Exit on connection loss |

### Measurement Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `measurementUpdateLimit` | int | `9900` | Min interval (ms) between measurements |
| `limitingStrategy` | enum | `"default"` | `"default"` or `"defaultWithMotionSensitivity"` |
| `limitingStrategyThreshold` | float | `0.05` | Motion threshold in G |

### Filter Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `filterMode` | enum | `"none"` | `"none"`, `"blacklist"`, `"whitelist"`, or `"named"` |
| `filterMacs` | list of strings | `[]` | MAC addresses to filter |

### Storage Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storageMethod` | enum | `"influxdb"` | `"influxdb"`, `"prometheus"`, or `"dummy"` |
| `storageValues` | enum | `"extended"` | `"raw"`, `"extended"`, `"whitelist"`, or `"blacklist"` |
| `storageValuesList` | list of strings | `[]` | Values for whitelist/blacklist mode |
| `receiver` | string or null | `null` | Receiver identifier tag |

### Tag Names

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tagNames` | attribute set | `{}` | Map of MAC addresses to friendly names |

### Advanced Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `scanCommand` | string or null | `null` | Custom scan command (null uses lescan service) |
| `dumpCommand` | string | `"hcidump --raw"` | Command for BLE dump |
| `bluetoothDevice` | string | `"hci0"` | Bluetooth device to use |

## Usage Examples

### Basic Setup with Local InfluxDB

```nix
services.ruuvi-collector.enable = true;
services.influxdb.enable = true;
```

### Whitelist Specific Tags

```nix
services.ruuvi-collector = {
  enable = true;
  filterMode = "whitelist";
  filterMacs = [
    "ABCDEF012345"
    "F1E2D3C4B5A6"
  ];
};
```

### Named Tags Only with Extended Values

```nix
services.ruuvi-collector = {
  enable = true;
  filterMode = "named";
  storageValues = "extended";
  tagNames = {
    "D04AB59C588B" = "Living Room";
    "D944923E0B70" = "Balcony";
    "F97C9896E88F" = "Fridge";
  };
};
```

### Using a Remote InfluxDB

```nix
services.ruuvi-collector = {
  enable = true;
  influxUrl = "http://influxdb.local:8086";
  influxDatabase = "sensors";
  influxUser = "ruuvi";
  influxPasswordFile = "/run/secrets/influxdb-password";
};
```

### Motion-Sensitive Collection

```nix
services.ruuvi-collector = {
  enable = true;
  limitingStrategy = "defaultWithMotionSensitivity";
  limitingStrategyThreshold = 0.1;  # 100 mG threshold
};
```

## Building the Package Standalone

You can also build just the package without the NixOS module:

```bash
# Build
nix build .#ruuvi-collector

# Run
nix run .#ruuvi-collector
```

## Raspberry Pi Specific Notes

This flake is compatible with aarch64-linux (Raspberry Pi). When deploying to a Raspberry Pi:

1. Ensure your system is set to `aarch64-linux`:
```nix
nixosConfigurations.raspberrypi = nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  # ...
};
```

2. The Bluetooth device is typically `hci0` on Raspberry Pi (default).

3. Make sure Bluetooth is not blocked:
```bash
rfkill unblock bluetooth
```

## Systemd Services

The flake creates two systemd services:

- **lescan.service**: Runs the BLE scanning (hcitool lescan)
- **ruuvi-collector.service**: Runs the RuuviCollector application

Both services:
- Start automatically on boot
- Restart on failure
- Run after the Bluetooth service is ready

Check service status:
```bash
systemctl status lescan
systemctl status ruuvi-collector
```

View logs:
```bash
journalctl -u lescan -f
journalctl -u ruuvi-collector -f
```

## Troubleshooting

### Bluetooth not working

```bash
# Check Bluetooth status
systemctl status bluetooth

# Check if device is up
hciconfig hci0 up

# Check for rfkill blocks
rfkill list
```

### No data in InfluxDB

1. Check if tags are being detected:
```bash
journalctl -u ruuvi-collector -f
```

2. Verify InfluxDB is running:
```bash
systemctl status influxdb
```

3. Check InfluxDB connection:
```bash
curl http://localhost:8086/ping
```

4. Verify database exists:
```bash
influx -execute 'SHOW DATABASES'
```

### Permission issues

The flake automatically sets the required capabilities on `hcitool`, `hcidump`, and `hciconfig`. If you still have permission issues, check:

```bash
ls -la /run/wrappers/bin/hci*
getcap /run/wrappers/bin/hcitool
```

## Security

- The service runs as an unprivileged user `ruuvi-collector`
- Bluetooth tools have minimal capabilities set
- Configuration files are protected with appropriate permissions
- Use `influxPasswordFile` instead of `influxPassword` for better security
- Consider using `agenix` or `sops-nix` for secret management

## License

BSD-3-Clause (same as upstream RuuviCollector)
