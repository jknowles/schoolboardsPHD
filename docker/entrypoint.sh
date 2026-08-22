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

# The /work/dissertation/Data and /work/phd_figs symlinks are created at image
# build time (see the Dockerfiles) because this container runs as the invoking
# user, who cannot write to /work. They dangle until the repo is mounted.
# Verify rather than create:
[ -d /work/dissertation/Data ] || echo "warning: /work/dissertation/Data does not resolve -- is vendor/Data present?" >&2

# The one shim that must live inside the repo:
# data/cleanandprep_POLICY.R:5 loads "data/cache/hsc.rda"; the file on disk
#    is HSC.rda. Harmless on Windows, fatal on a case-sensitive filesystem --
#    chapter 6 cannot build without this. A symlink fixes it without touching
#    the 2015 source.
if [ -f "$REPO/data/cache/HSC.rda" ] && [ ! -e "$REPO/data/cache/hsc.rda" ]; then
  ln -sfn HSC.rda "$REPO/data/cache/hsc.rda" 2>/dev/null || \
    cp -p "$REPO/data/cache/HSC.rda" "$REPO/data/cache/hsc.rda" 2>/dev/null || \
    echo "warning: could not provide data/cache/hsc.rda (read-only mount?)" >&2
fi

exec "$@"
