let
  pkgs = import <nixpkgs> {};
in
  pkgs.stdenv.mkDerivation {
    name = "RuuviCollector";

    # Bring the package defined in ginsim.nix in scope.  buildInputs is
    # therefore a one-element list.  Its only element is the call of the
    # anonymous function defined in ginsim.nix.  I could have used let
    # to define a local binding ginsim = callPackage ./ginsim.nix {}; to
    # explicitly bind a name to this function call.
    #
    # callPackage can also be replaced by import.  In this case, the
    # arguments of the anonymous function defined in ginsim.nix get
    # their respective default values.
    buildInputs = [(pkgs.callPackage ./ruuvi.nix {})];
  }
