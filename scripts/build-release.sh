#!/bin/sh

set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$project_dir/scripts/build-private-release.py"
