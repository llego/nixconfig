{
  description = "RuuviCollector - Collect sensor measurements from RuuviTags and store them to InfluxDB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Systems to support
      systems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Fixed-output derivation to fetch Maven dependencies
        mavenDeps = pkgs.stdenv.mkDerivation {
          name = "ruuvi-collector-maven-deps";
          src = ./.;

          nativeBuildInputs = [ pkgs.maven ];

          buildPhase = ''
            # Fetch all dependencies including plugins
            mvn dependency:go-offline -Dmaven.repo.local=$out/.m2
            # Also fetch plugin dependencies
            mvn dependency:resolve-plugins -Dmaven.repo.local=$out/.m2

            # Manually fetch specific plugin dependencies
            mvn dependency:get -Dartifact=org.apache.maven.plugins:maven-clean-plugin:3.2.0 -Dmaven.repo.local=$out/.m2 || true
            mvn dependency:get -Dartifact=org.junit.platform:junit-platform-surefire-provider:1.2.0 -Dmaven.repo.local=$out/.m2 || true
            mvn dependency:get -Dartifact=org.junit.jupiter:junit-jupiter-engine:5.3.2 -Dmaven.repo.local=$out/.m2 || true
          '';

          # This is a fixed-output derivation
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-YFlu0BaUCytTVVQnEf0Fuiie7JzltbTcUVl8O44flQg=";

          installPhase = "true";
        };

        ruuvi-collector = pkgs.stdenv.mkDerivation rec {
          pname = "ruuvi-collector";
          version = "0.2";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            maven
            makeWrapper
            jdk8
          ];

          buildPhase = ''
            # Copy dependencies to a writable location
            export HOME=$TMPDIR
            mkdir -p $HOME/.m2
            cp -r ${mavenDeps}/.m2/* $HOME/.m2/
            chmod -R +w $HOME/.m2

            # Use the pre-fetched dependencies in offline mode
            # Skip tests completely (both compilation and execution)
            mvn package -Dmaven.repo.local=$HOME/.m2 -Dmaven.test.skip=true --offline
          '';

          installPhase = ''
            mkdir -p $out/share/ruuvi-collector
            mkdir -p $out/bin

            # Install the JAR file
            cp target/ruuvi-collector-${version}.jar $out/share/ruuvi-collector/

            # Create wrapper script
            makeWrapper ${pkgs.jre8}/bin/java $out/bin/ruuvi-collector \
              --add-flags "-jar $out/share/ruuvi-collector/ruuvi-collector-${version}.jar" \
              --set JAVA_HOME "${pkgs.jre8}"
          '';

          meta = with pkgs.lib; {
            description = "Collect sensor measurements from RuuviTags and store them to InfluxDB";
            homepage = "https://github.com/Scrin/RuuviCollector";
            license = licenses.bsd3;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };
      in
      {
        packages = {
          default = ruuvi-collector;
          ruuvi-collector = ruuvi-collector;
        };

        apps.default = {
          type = "app";
          program = "${ruuvi-collector}/bin/ruuvi-collector";
        };
      }
    ) // {
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.services.ruuvi-collector;

          # Generate properties file content
          mkPropertiesFile = settings:
            pkgs.writeText "ruuvi-collector.properties" (
              concatStringsSep "\n" (
                mapAttrsToList (name: value:
                  if value == null then ""
                  else if isBool value then "${name}=${if value then "true" else "false"}"
                  else "${name}=${toString value}"
                ) (filterAttrs (n: v: v != null) settings)
              )
            );

          mkNamesFile = names:
            pkgs.writeText "ruuvi-names.properties" (
              concatStringsSep "\n" (
                mapAttrsToList (mac: name: "${mac}=${name}") names
              )
            );
        in
        {
          options.services.ruuvi-collector = {
            enable = mkEnableOption "RuuviCollector service";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
              defaultText = literalExpression "pkgs.ruuvi-collector";
              description = "The RuuviCollector package to use";
            };

            # InfluxDB settings
            influxUrl = mkOption {
              type = types.str;
              default = "http://localhost:8086";
              description = "Base URL to connect to InfluxDB";
            };

            influxDatabase = mkOption {
              type = types.str;
              default = "ruuvi";
              description = "InfluxDB database to use for measurements";
            };

            influxMeasurement = mkOption {
              type = types.str;
              default = "ruuvi_measurements";
              description = "InfluxDB measurement name to use";
            };

            influxUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Username for InfluxDB authentication";
            };

            influxPassword = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Password for InfluxDB authentication (consider using influxPasswordFile instead)";
            };

            influxPasswordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing the InfluxDB password";
            };

            influxRetentionPolicy = mkOption {
              type = types.str;
              default = "autogen";
              description = "Retention policy to use";
            };

            influxGzip = mkOption {
              type = types.bool;
              default = true;
              description = "Use gzip compression";
            };

            influxBatch = mkOption {
              type = types.bool;
              default = true;
              description = "Use batch mode for improved performance";
            };

            influxBatchMaxSize = mkOption {
              type = types.int;
              default = 2000;
              description = "Maximum number of datapoints before sending a batch";
            };

            influxBatchMaxTime = mkOption {
              type = types.int;
              default = 100;
              description = "Maximum time in milliseconds before sending a batch";
            };

            exitOnInfluxDBIOException = mkOption {
              type = types.bool;
              default = false;
              description = "Exit when InfluxDB connection is lost";
            };

            # Measurement settings
            measurementUpdateLimit = mkOption {
              type = types.int;
              default = 9900;
              description = "Minimum interval in milliseconds for measurements per tag";
            };

            limitingStrategy = mkOption {
              type = types.enum [ "default" "defaultWithMotionSensitivity" ];
              default = "default";
              description = "Limiting strategy for measurements";
            };

            limitingStrategyThreshold = mkOption {
              type = types.float;
              default = 0.05;
              description = "Threshold for motion sensitivity (in G)";
            };

            # Filter settings
            filterMode = mkOption {
              type = types.enum [ "none" "blacklist" "whitelist" "named" ];
              default = "none";
              description = "Filtering mode for source MAC addresses";
            };

            filterMacs = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "MAC addresses to filter";
              example = [ "ABCDEF012345" "F1E2D3C4B5A6" ];
            };

            # Storage settings
            storageMethod = mkOption {
              type = types.enum [ "influxdb" "prometheus" "dummy" ];
              default = "influxdb";
              description = "Storage method to use";
            };

            storageValues = mkOption {
              type = types.enum [ "raw" "extended" "whitelist" "blacklist" ];
              default = "extended";
              description = "Values to store";
            };

            storageValuesList = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "List of values for whitelist/blacklist mode";
            };

            receiver = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Receiver identifier to tag values";
            };

            # Tag names
            tagNames = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Friendly names for RuuviTag MAC addresses";
              example = {
                "D04AB59C588B" = "Indoors";
                "D944923E0B70" = "Terrace";
                "F97C9896E88F" = "Fridge";
              };
            };

            # Advanced settings
            scanCommand = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Custom scan command (leave null to use lescan service)";
            };

            dumpCommand = mkOption {
              type = types.str;
              default = "hcidump --raw";
              description = "Command for BLE dump";
            };

            # Bluetooth device
            bluetoothDevice = mkOption {
              type = types.str;
              default = "hci0";
              description = "Bluetooth device to use";
            };
          };

          config = mkIf cfg.enable {
            # Install required packages
            environment.systemPackages = with pkgs; [
              cfg.package
              bluez
              bluez-tools
            ];

            # Enable Bluetooth
            hardware.bluetooth.enable = true;
            hardware.bluetooth.powerOnBoot = true;

            # Set capabilities on bluetooth tools
            security.wrappers = {
              hcitool = {
                source = "${pkgs.bluez}/bin/hcitool";
                capabilities = "cap_net_raw,cap_net_admin+eip";
                owner = "root";
                group = "root";
              };
              hcidump = {
                source = "${pkgs.bluez}/bin/hcidump";
                capabilities = "cap_net_raw,cap_net_admin+eip";
                owner = "root";
                group = "root";
              };
              hciconfig = {
                source = "${pkgs.bluez}/bin/hciconfig";
                capabilities = "cap_net_raw,cap_net_admin+eip";
                owner = "root";
                group = "root";
              };
            };

            # Create runtime directory and config files
            systemd.tmpfiles.rules = [
              "d /var/lib/ruuvi-collector 0755 ruuvi-collector ruuvi-collector -"
            ];

            # Create user for the service
            users.users.ruuvi-collector = {
              isSystemUser = true;
              group = "ruuvi-collector";
              description = "RuuviCollector service user";
            };

            users.groups.ruuvi-collector = {};

            # BLE Scanning Service
            systemd.services.lescan = {
              description = "BLE Scanning Service";
              wantedBy = [ "multi-user.target" ];
              # Conflicts with bluetooth.service to ensure exclusive access
              conflicts = [ "bluetooth.service" ];
              after = [ "bluetooth.service" ];

              serviceConfig = {
                Type = "simple";
                ExecStartPre = "${config.security.wrapperDir}/hciconfig ${cfg.bluetoothDevice} reset";
                ExecStart = "${config.security.wrapperDir}/hcitool -i ${cfg.bluetoothDevice} lescan --duplicates --passive";
                StandardOutput = "null";
                StandardError = "journal";
                Restart = "always";
                RestartSec = "10";
              };
            };

            # RuuviCollector Service
            systemd.services.ruuvi-collector = let
              # Build the configuration settings
              settings = {
                influxUrl = cfg.influxUrl;
                influxDatabase = cfg.influxDatabase;
                influxMeasurement = cfg.influxMeasurement;
                influxUser = cfg.influxUser;
                influxPassword = if cfg.influxPasswordFile != null then null else cfg.influxPassword;
                influxRetentionPolicy = cfg.influxRetentionPolicy;
                influxGzip = cfg.influxGzip;
                influxBatch = cfg.influxBatch;
                influxBatchMaxSize = cfg.influxBatchMaxSize;
                influxBatchMaxTime = cfg.influxBatchMaxTime;
                exitOnInfluxDBIOException = cfg.exitOnInfluxDBIOException;
                measurementUpdateLimit = cfg.measurementUpdateLimit;
                limitingStrategy = cfg.limitingStrategy;
                "limitingStrategy.defaultWithMotionSensitivity.threshold" =
                  if cfg.limitingStrategy == "defaultWithMotionSensitivity"
                  then cfg.limitingStrategyThreshold
                  else null;
                "filter.mode" = cfg.filterMode;
                "filter.macs" = if cfg.filterMacs != []
                  then concatStringsSep "," cfg.filterMacs
                  else null;
                "storage.method" = cfg.storageMethod;
                "storage.values" = cfg.storageValues;
                "storage.values.list" = if cfg.storageValuesList != []
                  then concatStringsSep "," cfg.storageValuesList
                  else null;
                receiver = cfg.receiver;
                "command.scan" = cfg.scanCommand;
                "command.dump" = cfg.dumpCommand;
              };

              configFile = mkPropertiesFile settings;
              namesFile = if cfg.tagNames != {} then mkNamesFile cfg.tagNames else null;
            in {
              description = "RuuviCollector Service";
              after = [ "network.target" "lescan.service" ];
              requires = [ "lescan.service" ];
              wantedBy = [ "multi-user.target" ];

              preStart = ''
                # Copy config files to working directory
                cp ${configFile} /var/lib/ruuvi-collector/ruuvi-collector.properties

                ${optionalString (cfg.influxPasswordFile != null) ''
                  # Add password from file
                  echo "influxPassword=$(cat ${cfg.influxPasswordFile})" >> /var/lib/ruuvi-collector/ruuvi-collector.properties
                ''}

                ${optionalString (namesFile != null) ''
                  cp ${namesFile} /var/lib/ruuvi-collector/ruuvi-names.properties
                ''}

                chown -R ruuvi-collector:ruuvi-collector /var/lib/ruuvi-collector
              '';

              serviceConfig = {
                Type = "simple";
                User = "ruuvi-collector";
                Group = "ruuvi-collector";
                WorkingDirectory = "/var/lib/ruuvi-collector";
                ExecStart = "${cfg.package}/bin/ruuvi-collector";
                Restart = "always";
                RestartSec = "10";

                # Security hardening
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [ "/var/lib/ruuvi-collector" ];
              };
            };
          };
        };
    };
}
