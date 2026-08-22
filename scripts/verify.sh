#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Compare a rebuild against the frozen 2015 outputs in reference/2015-build/.
#
# Three tiers, because "identical" means something different at each level:
#
#   1. chapters/*/*.tex  -- BYTE-identical. This is the acceptance test. Every
#      model coefficient, standard error, table cell and inline \Sexpr number in
#      the dissertation passes through these files, so a byte match is a
#      complete statement that the analysis reproduced.
#
#   2. phd_figs/*        -- CONTENT-identical. Figure PDFs embed a creation
#      timestamp and randomised font subset tags, so bytes cannot match. Compare
#      the extracted text layer (axis labels, tick values, legend entries -- all
#      of which are data) and a rasterised pixel hash of the drawing itself.
#
#   3. dissertation.pdf  -- TEXT-LAYER identical. Byte equality across TeX
#      versions is not achievable and was never the goal.
#
# Exit status is 0 only if every requested tier passes.
#
# Usage: scripts/verify.sh [--tex-only] [chapter ...]
# ---------------------------------------------------------------------------
set -uo pipefail

REF="reference/2015-build"
CHAPTERS=(aboutwisconsin candidacy voterturnout policy walker)
TEX_ONLY=0
SELECT=()

for a in "$@"; do
  case "$a" in
    --tex-only) TEX_ONLY=1 ;;
    -h|--help)  sed -n '2,25p' "$0"; exit 0 ;;
    *)          SELECT+=("$a") ;;
  esac
done
[ ${#SELECT[@]} -gt 0 ] && CHAPTERS=("${SELECT[@]}")

[ -d "$REF" ] || { echo "missing $REF -- the 2015 oracle is not present"; exit 2; }

# Drop xtable's "% Fri May 15 00:46:16 2015" generation-date comments.
strip_ts() {
  grep -vE '^% (Mon|Tue|Wed|Thu|Fri|Sat|Sun) [A-Z][a-z]{2} +[0-9]+ [0-9:]+ [0-9]{4}$' "$1"
}

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n'  "$1"; }

fails=0

# --- Tier 1: chapter .tex, byte-identical ----------------------------------
echo "=============================================================="
echo " Tier 1  chapters/*/*.tex  (byte-identical -- acceptance test)"
echo "=============================================================="
for c in "${CHAPTERS[@]}"; do
  new="chapters/$c/$c.tex"
  old="$REF/chapters/$c/$c.tex"
  if [ ! -f "$old" ]; then dim "  skip  $c (no reference)"; continue; fi
  if [ ! -f "$new" ]; then red  "  MISS  $c (not rebuilt)"; fails=$((fails+1)); continue; fi

  if cmp -s "$new" "$old"; then
    green "  PASS  $c.tex  ($(wc -l < "$new") lines, byte-identical)"
  elif diff -q <(strip_ts "$old") <(strip_ts "$new") >/dev/null; then
    # xtable stamps the generation date into a LaTeX comment on every table it
    # writes. That is a build artifact, not a result -- it cannot match and
    # nothing downstream reads it. Everything else must still be byte-identical.
    nts=$(diff "$old" "$new" | grep -c '^[<>]')
    green "  PASS  $c.tex  (byte-identical; $((nts/2)) xtable timestamp comments differ)"
  else
    fails=$((fails+1))
    nd=$(diff <(strip_ts "$old") <(strip_ts "$new") | grep -c '^[<>]')
    red  "  FAIL  $c.tex  ($nd differing lines, excluding xtable timestamps)"
    echo "        first differences:"
    diff <(strip_ts "$old") <(strip_ts "$new") | head -14 | sed 's/^/        /'
    echo "        full diff: diff $old $new"
  fi
done

if [ "$TEX_ONLY" -eq 1 ]; then
  echo
  [ "$fails" -eq 0 ] && green "Tier 1 passed." || red "Tier 1: $fails chapter(s) differ."
  exit $(( fails > 0 ))
fi

# --- Tier 2: figures, content-identical -------------------------------------
echo
echo "=============================================================="
echo " Tier 2  phd_figs/  (content-identical: text layer + pixels)"
echo "=============================================================="
if [ ! -d phd_figs ]; then
  dim "  skip  phd_figs/ not present (chapters not knitted yet)"
else
  tot=0; okc=0; badlist=""
  for old in "$REF"/phd_figs/*.pdf; do
    [ -e "$old" ] || continue
    base=$(basename "$old"); new="phd_figs/$base"
    tot=$((tot+1))
    [ -f "$new" ] || { badlist="$badlist\n        MISSING  $base"; continue; }

    # text layer (axis labels, tick values -- these are data)
    if ! diff -q <(pdftotext "$old" - 2>/dev/null) <(pdftotext "$new" - 2>/dev/null) >/dev/null; then
      badlist="$badlist\n        TEXT     $base"; continue
    fi
    # drawn content
    ha=$(pdftoppm -r 100 -gray -png -singlefile "$old" /tmp/vfa 2>/dev/null && sha256sum /tmp/vfa.png | cut -d' ' -f1)
    hb=$(pdftoppm -r 100 -gray -png -singlefile "$new" /tmp/vfb 2>/dev/null && sha256sum /tmp/vfb.png | cut -d' ' -f1)
    if [ "$ha" != "$hb" ]; then badlist="$badlist\n        PIXELS   $base"; continue; fi
    okc=$((okc+1))
  done
  rm -f /tmp/vfa.png /tmp/vfb.png
  if [ "$okc" -eq "$tot" ] && [ "$tot" -gt 0 ]; then
    green "  PASS  $okc/$tot figures content-identical"
  else
    fails=$((fails+1))
    red   "  FAIL  $okc/$tot figures matched"
    printf "%b\n" "$badlist" | head -25
  fi
fi

# --- Tier 3: final PDF, text layer ------------------------------------------
echo
echo "=============================================================="
echo " Tier 3  dissertation.pdf  (text layer identical)"
echo "=============================================================="
if [ ! -f dissertation.pdf ]; then
  dim "  skip  dissertation.pdf not built yet"
elif [ ! -f "$REF/dissertation.pdf" ]; then
  dim "  skip  no reference PDF"
else
  pa=$(pdfinfo "$REF/dissertation.pdf" | awk '/^Pages/{print $2}')
  pb=$(pdfinfo dissertation.pdf        | awk '/^Pages/{print $2}')
  if diff -q <(pdftotext "$REF/dissertation.pdf" -) <(pdftotext dissertation.pdf -) >/dev/null; then
    green "  PASS  text layer identical ($pb pages, reference $pa)"
  else
    fails=$((fails+1))
    nd=$(diff <(pdftotext "$REF/dissertation.pdf" -) <(pdftotext dissertation.pdf -) | grep -c '^[<>]')
    red   "  FAIL  text layer differs ($nd lines; $pb pages vs reference $pa)"
    diff <(pdftotext "$REF/dissertation.pdf" -) <(pdftotext dissertation.pdf -) | head -12 | sed 's/^/        /'
  fi
fi

echo
if [ "$fails" -eq 0 ]; then green "All tiers passed."; else red "$fails tier(s) failed."; fi
exit $(( fails > 0 ))
