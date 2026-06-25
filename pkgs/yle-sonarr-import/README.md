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

## Adding A Series

Edit `/var/lib/yle-sonarr-import/series.yaml` and add a top-level key matching
Sonarr's `titleSlug`. Only `yle_url` is required; `sonarr_series_id` is cached
after the next successful Sonarr lookup.

```yaml
alfie-atkins-2012:
  enabled: true
  yle_url: https://arenan.yle.fi/1-50504909
  language: sv
```

Then run:

```bash
sudo systemctl start yle-sonarr-import.service
```

The importer derives per-series state and download paths from the top-level key.
