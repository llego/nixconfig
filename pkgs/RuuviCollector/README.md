# RuuviCollector (Nix Fork)

**This is a Nix-focused fork of [RuuviCollector](https://github.com/Scrin/RuuviCollector) for NixOS deployment.**

For the original version with Docker and traditional Linux setup scripts, see the [upstream repository](https://github.com/Scrin/RuuviCollector).

## Why This Fork?

This fork provides:
- **Nix Flake** for reproducible builds on x86_64-linux and aarch64-linux (Raspberry Pi)
- **NixOS Module** with declarative configuration via Nix options
- **Automatic systemd service setup** with proper Bluetooth capabilities
- **No manual setup required** - everything configured through NixOS

**For NixOS deployment instructions, see [NIX_README.md](./NIX_README.md).**

---

## About RuuviCollector

RuuviCollector is an application for collecting sensor measurements from RuuviTags and storing them to InfluxDB. For more about how and for what this is used for, see [this](https://f.ruuvi.com/t/collecting-ruuvitag-measurements-and-displaying-them-with-grafana/267) post.

Do you have a [Ruuvi Gateway](https://ruuvi.com/gateway/)? You might be insterested in [RuuviBridge](https://github.com/Scrin/RuuviBridge) instead. You can also use [ruuvi-go-gateway](https://github.com/Scrin/ruuvi-go-gateway) if you want to upgrade to the "new stack" without needing a physical Ruuvi Gateway, or want to use a mix of both.

Note: This tool is primarily intended for advanced users, so some knowledge in Linux and Java might be necessary for fully understanding how to use this. However there is a more beginner friendly setup "guide" [here](https://ruuvi.com/setting-up-raspberry-pi-as-a-ruuvi-gateway/)

### Features

Supports following RuuviTag [Data Formats](https://github.com/ruuvi/ruuvi-sensor-protocols):

-   Data Format 2: Eddystone-URL, URL-safe base64 -encoded, kickstarter edition
-   Data Format 3: "RAW v1" BLE Manufacturer specific data, all current sensor readings
-   Data Format 4: Eddystone-URL, URL-safe base64 -encoded, with tag id
-   Data Format 5: "RAW v2" BLE Manufacturer specific data, all current sensor readings + extra

Additionally basic support for iBeacon and Eddystone exists:

-   iBeacon: MAC, RSSI and other receiver-side generated data
-   Eddystone UID: MAC, RSSI and other receiver-side generated data
-   Eddystone TLM: temperature, battery voltage, MAC, RSSI and other receiver-side generated data

Supports following data from the tag (depending on tag firmware):

-   Temperature (Celsius)
-   Relative humidity (0-100%)
-   Air pressure (Pascal)
-   Acceleration for X, Y and Z axes (g)
-   Battery voltage (Volts)
-   TX power (dBm)
-   RSSI (Signal strength _at the receiver_, dBm)
-   Movement counter (Running counter incremented each time a motion detection interrupt is received)
-   Measurement sequence number (Running counter incremented each time a new measurement is taken on the tag)

Ability to calculate following values in addition to the raw data (the accuracy of these values are approximations):

-   Total acceleration (g)
-   Absolute humidity (g/m³)
-   Dew point (Celsius)
-   Equilibrium vapor pressure (Pascal)
-   Air density (Accounts for humidity in the air, kg/m³)
-   Acceleration angle from X, Y and Z axes (Degrees)

See [MEASUREMENTS.md](./MEASUREMENTS.md) for additional details about the measurements.

## NixOS Installation

**See [NIX_README.md](./NIX_README.md) for complete NixOS installation and configuration instructions.**

Quick example:

```nix
{
  services.ruuvi-collector = {
    enable = true;
    influxUrl = "http://localhost:8086";
    influxDatabase = "ruuvi";
    tagNames = {
      "D04AB59C588B" = "Living Room";
      "F97C9896E88F" = "Fridge";
    };
    filterMode = "named";
  };
}
```

All dependencies (Bluetooth stack, Java runtime, systemd services) are handled automatically.

## Traditional Building (Non-NixOS)

For non-NixOS systems, you can still build manually with Maven:

### Requirements

-   Linux-based OS (this application uses the bluez stack for Bluetooth which is not available for Windows for example)
-   Bluetooth adapter supporting Bluetooth Low Energy
-   _bluez_ and _bluez-hcidump_ at least version 5.41
-   Maven (For building from sources)
-   JDK8 (For building from sources, JRE8 is enough for just running the built JAR)

### Building

```sh
mvn clean package
```

### Running

```sh
java -jar target/ruuvi-collector-*.jar
```

For configuration options and manual setup, see the [upstream documentation](https://github.com/Scrin/RuuviCollector#readme).
