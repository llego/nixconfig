{config, pkgs, inputs, ...}:
{
	home.packages = with pkgs; [
		(writeShellScriptBin "bandcamp-collection" (builtins.readFile ./bandcamp-collection/bandcamp-collection.sh))
    inputs.bandsnatch.packages."${pkgs.system}".default
	];
}
