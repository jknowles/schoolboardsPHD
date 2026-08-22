#!/bin/sh
# ---------------------------------------------------------------------------
# Recreate the 2015 filesystem layout around the mounted repository, then run
# whatever was asked for.
#
# The 2015 code carries relative paths that only make sense inside the author's
# Dropbox tree. Track A's rule is to change the environment rather than the
# code, so instead of editing those paths we rebuild the shape of the world
# they expect.
# ---------------------------------------------------------------------------
set -e

REPO=/work/dissertation/MasterText

# On modernize the raw data lives in data/raw/ and dataAssemble.R reads it by a
# repo-relative path, so no ../Data shim is needed. Only /work/phd_figs remains,
# created at image build time (the container runs as the invoking user, who
# cannot write to /work), and it dangles until the repository is mounted.
[ -d /work/phd_figs ] || echo "note: /work/phd_figs does not resolve yet -- normal until phd_figs/ exists" >&2

exec "$@"
