#!/bin/sh
# Release configuration with local ad-hoc signing; not a notarized distribution build.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$project_dir/scripts/build-private-release.py"
