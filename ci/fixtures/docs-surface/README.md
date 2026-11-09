# docs-surface fixtures

Synthetic route manifests for `ci/scripts/test-docs-surface.sh`, shaped
like a documentation site's `routes/*.yaml` (one published page per
entry: a `route`, exactly one canonical `source:` file, and optional
further `sources:`). They exercise every YAML form the detector's
subset parser accepts — inline and block lists, nested maps, a folded
description, comments — and `bad/` holds a manifest it must refuse.
Nothing here is lq-ai content; the paths are illustrative.
