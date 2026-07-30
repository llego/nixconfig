let
  registry = import ./secrets/_registry.nix;
in
  builtins.listToAttrs (
    map (name: {
      name = "secrets/${name}.age";
      value = {
        inherit (registry.secrets.${name}) publicKeys;
      };
    }) (builtins.attrNames registry.secrets)
  )
