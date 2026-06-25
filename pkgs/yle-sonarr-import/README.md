# YLE Sonarr Importer

Small Python app that reviews YLE Areena episode metadata, maps approved episodes
to Sonarr episodes, downloads mapped files with `yle-dl`, and asks Sonarr to
import them.

## Development

```bash
nix develop ./pkgs/yle-sonarr-import
pytest
```

Run the packaged app:

```bash
nix run ./pkgs/yle-sonarr-import
```

The production NixOS service passes secrets through
`/run/keys/yle-sonarr-import-env` and stores state under
`/var/lib/yle-sonarr-import/bluey-2018`.
