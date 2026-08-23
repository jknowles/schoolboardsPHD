#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Build the archival deposit bundle from the source-records tree.
#
# The scanned records are far too large for this repository (1.6 GB, mostly
# image-only PDFs) and are deposited separately. This script assembles that
# deposit so the bundle is reproducible rather than something that was made once
# by hand and can never be checked.
#
#   scripts/build-deposit.sh <path-to-Data-tree> [output-dir]
#
# Defaults assume the 2015 layout, with the archive one level above the
# repository:
#
#   <parent>/
#     Data/                 <- the source-records tree
#     MasterText/           <- this repository
#     Reproduction-Archive/ <- output goes here
#
# What it does:
#   - copies the tree, excluding editor state (.Rproj.user, .Rhistory, .RData,
#     .Rproj) -- archive hygiene, not redaction
#   - writes MANIFEST.sha256 over every remaining file
#   - carries README.md and metadata.yml in from deposit-template/
#   - zips it and reports the checksum
#
# Zip archives are not bit-reproducible across zip implementations, so the
# guarantee here is over *contents*: MANIFEST.sha256 covers every file, and the
# 320 transcribed CSVs are checked against the copies vendored in this
# repository.
# ---------------------------------------------------------------------------
set -euo pipefail

SRC="${1:-../Data}"
OUT="${2:-../Reproduction-Archive/deposit}"
NAME="schoolboards-source-records-v1"
REPO_CSVS="data/raw/sbelectionresults"

[ -d "$SRC" ] || { echo "source tree not found: $SRC" >&2; exit 2; }
[ -d "$REPO_CSVS" ] || { echo "run from the repository root" >&2; exit 2; }
[ -d inst/deposit-template ] || { echo "missing inst/deposit-template/" >&2; exit 2; }

STAGE="$OUT/$NAME"
echo "source : $SRC"
echo "output : $STAGE"

rm -rf "$STAGE"; mkdir -p "$STAGE"

echo "staging (excluding editor state)..."
rsync -a \
  --exclude '.Rproj.user/' --exclude '.Rhistory' --exclude '.RData' \
  --exclude '*.Rproj' --exclude '.DS_Store' --exclude 'Thumbs.db' \
  "$SRC/" "$STAGE/Data/"

n_src=$(find "$SRC" -type f | wc -l)
n_out=$(find "$STAGE/Data" -type f | wc -l)
echo "  kept $n_out files, excluded $(( n_src - n_out ))"

cp inst/deposit-template/README.md   "$STAGE/README.md"
cp inst/deposit-template/metadata.yml "$STAGE/metadata.yml"

echo "checksumming..."
( cd "$STAGE/Data" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum ) \
  > "$STAGE/MANIFEST.sha256"
echo "  $(wc -l < "$STAGE/MANIFEST.sha256") entries"

echo "cross-checking the transcribed CSVs against this repository..."
( cd "$STAGE/Data/sbelectionresults" && find . -name '*.csv' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum ) > /tmp/dep.sha
( cd "$REPO_CSVS" && find . -name '*.csv' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum ) > /tmp/repo.sha
if diff -q /tmp/dep.sha /tmp/repo.sha >/dev/null; then
  echo "  all $(wc -l < /tmp/dep.sha) CSVs match the repository byte-for-byte"
else
  echo "  MISMATCH between the deposit and the vendored CSVs:" >&2
  diff /tmp/dep.sha /tmp/repo.sha | head -10 >&2
  rm -f /tmp/dep.sha /tmp/repo.sha
  exit 1
fi
rm -f /tmp/dep.sha /tmp/repo.sha

echo "zipping..."
( cd "$OUT" && rm -f "$NAME.zip" && zip -q -r -X "$NAME.zip" "$NAME" )

ZIP="$OUT/$NAME.zip"
echo
echo "built $ZIP"
echo "  size   : $(du -h "$ZIP" | cut -f1)"
echo "  sha256 : $(sha256sum "$ZIP" | cut -d' ' -f1)"
echo
echo "Next: upload the zip, fill the form from $STAGE/metadata.yml,"
echo "      then run  scripts/record-deposit-doi.sh <doi>"
