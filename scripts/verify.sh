#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Compare a rebuild against the frozen 2015 outputs in reference/2015-build/.
#
# Three tiers, because "identical" means something different at each level:
#
#   1. chapters/*/*.tex  -- BYTE-identical. Every coefficient, standard error,
#      table cell and inline \Sexpr number in the dissertation passes through
#      these five files.
#
#   2. phd_figs/*.pdf    -- CONTENT-identical. Figure PDFs embed creation
#      timestamps and randomised font subset tags, so bytes cannot match.
#      Compared by extracted text layer (axis labels and tick values are data)
#      and by rasterised RMSE, which tolerates antialiasing but not redrawn data.
#
#   3. dissertation.pdf  -- numeric content. Byte equality across TeX versions
#      is not achievable and was never the goal.
#
# ACCEPTED DIFFERENCES
# Reproduction is not perfect and the residue is documented rather than hidden.
# reference/accepted-differences/ holds the exact, reviewed diff for each
# chapter. A rebuild whose differences match that baseline exactly PASSES; a
# rebuild that differs from it in any way FAILS and shows what is new. The test
# keeps its teeth: the known residue is frozen, and regressions surface.
#
# Regenerate the baseline deliberately, never casually:  scripts/verify.sh --bless
#
# Usage: scripts/verify.sh [--tex-only] [--bless] [chapter ...]
# ---------------------------------------------------------------------------
set -uo pipefail

REF="reference/2015-build"
BASE="reference/accepted-differences"
CHAPTERS=(aboutwisconsin candidacy voterturnout policy walker)
TEX_ONLY=0; BLESS=0; SELECT=()

for a in "$@"; do
  case "$a" in
    --tex-only) TEX_ONLY=1 ;;
    --bless)    BLESS=1 ;;
    -h|--help)  sed -n '2,28p' "$0"; exit 0 ;;
    *)          SELECT+=("$a") ;;
  esac
done
[ ${#SELECT[@]} -gt 0 ] && CHAPTERS=("${SELECT[@]}")
[ -d "$REF" ] || { echo "missing $REF -- the 2015 oracle is not present"; exit 2; }
mkdir -p "$BASE"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n'  "$1"; }

# xtable stamps its generation date into a LaTeX comment above every table it
# writes. A build artifact: nothing downstream reads it, and it cannot match.
strip_ts() {
  grep -avE '^% (Mon|Tue|Wed|Thu|Fri|Sat|Sun) [A-Z][a-z]{2} +[0-9]+ [0-9:]+ [0-9]{4}$' "$1"
}

fails=0

# --- Tier 1 -----------------------------------------------------------------
echo "=============================================================="
echo " Tier 1  chapters/*/*.tex"
echo "=============================================================="
for c in "${CHAPTERS[@]}"; do
  new="chapters/$c/$c.tex"; old="$REF/chapters/$c/$c.tex"; acc="$BASE/$c.diff"
  [ -f "$old" ] || { dim "  skip  $c (no reference)"; continue; }
  [ -f "$new" ] || { red  "  MISS  $c (not rebuilt)"; fails=$((fails+1)); continue; }

  cur=$(diff <(strip_ts "$old") <(strip_ts "$new"))
  if [ -z "$cur" ]; then
    nts=$(( $(diff "$old" "$new" | grep -c '^[<>]') / 2 ))
    green "  PASS  $c.tex  byte-identical ($nts xtable timestamps aside)"
    [ "$BLESS" -eq 1 ] && rm -f "$acc"
    continue
  fi

  if [ "$BLESS" -eq 1 ]; then
    printf '%s\n' "$cur" > "$acc"
    dim "  BLESS $c.tex  ($(( $(grep -c '^[<>]' <<<"$cur") / 2 )) lines recorded)"
    continue
  fi

  if [ -f "$acc" ] && diff -q <(printf '%s\n' "$cur") "$acc" >/dev/null; then
    n=$(grep -c '^[<>]' "$acc")
    green "  PASS  $c.tex  matches accepted baseline ($((n/2)) lines, see $acc)"
  else
    fails=$((fails+1))
    red "  FAIL  $c.tex  differs from the accepted baseline"
    if [ -f "$acc" ]; then
      echo "        NEW differences (not in $acc):"
      diff "$acc" <(printf '%s\n' "$cur") | grep '^[<>]' | head -12 | sed 's/^/        /'
    else
      echo "        no baseline recorded; differences are:"
      printf '%s\n' "$cur" | head -12 | sed 's/^/        /'
    fi
  fi
done

if [ "$TEX_ONLY" -eq 1 ]; then
  echo
  if [ "$BLESS" -eq 1 ]; then dim "baseline written to $BASE/"; exit 0; fi
  [ "$fails" -eq 0 ] && green "Tier 1 passed." || red "Tier 1: $fails chapter(s) failed."
  exit $(( fails > 0 ))
fi

# --- Tier 2 -----------------------------------------------------------------
# RMSE tolerance: rasterising the same vector drawing through two poppler builds
# moves a handful of edge pixels. 0.002 admits that and nothing more -- the
# chapter 3 ROC plots, whose underlying coefficients genuinely moved, score
# 0.0070 and 0.0037 and are correctly reported.
RMSE_TOL=0.002
echo
echo "=============================================================="
echo " Tier 2  phd_figs/  (text layer + rasterised RMSE, tol $RMSE_TOL)"
echo "=============================================================="
if [ ! -d phd_figs ]; then
  dim "  skip  phd_figs/ not present"
else
  rep=$(mktemp); tot=0; okc=0
  for old in "$REF"/phd_figs/*.pdf; do
    [ -e "$old" ] || continue
    base=$(basename "$old"); new="phd_figs/$base"; tot=$((tot+1))
    [ -f "$new" ] || { echo "MISSING $base" >> "$rep"; continue; }
    if ! diff -q <(pdftotext "$old" - 2>/dev/null) <(pdftotext "$new" - 2>/dev/null) >/dev/null; then
      echo "TEXT    $base" >> "$rep"; continue
    fi
    pdftoppm -r 100 -gray -png -singlefile "$old" /tmp/vfa 2>/dev/null
    pdftoppm -r 100 -gray -png -singlefile "$new" /tmp/vfb 2>/dev/null
    r=$(compare -metric RMSE /tmp/vfa.png /tmp/vfb.png null: 2>&1 | grep -oE '\(0?\.[0-9]+\)' | tr -d '()')
    r=${r:-0}
    if awk -v r="$r" -v t="$RMSE_TOL" 'BEGIN{exit !(r>t)}'; then
      echo "PIXELS  $base" >> "$rep"
    else
      okc=$((okc+1))
    fi
  done
  rm -f /tmp/vfa.png /tmp/vfb.png
  sort -o "$rep" "$rep"
  accf="$BASE/figures.txt"
  if [ "$BLESS" -eq 1 ]; then
    cp "$rep" "$accf"; dim "  BLESS figures ($(wc -l < "$rep") recorded, $okc/$tot within tolerance)"
  elif [ -s "$rep" ] || [ -s "$accf" ]; then
    if [ -f "$accf" ] && diff -q "$rep" "$accf" >/dev/null; then
      green "  PASS  $okc/$tot within tolerance; $(wc -l < "$rep") known differences match baseline"
    else
      fails=$((fails+1)); red "  FAIL  figure differences do not match baseline"
      diff "$accf" "$rep" 2>/dev/null | head -15 | sed 's/^/        /'
    fi
  else
    green "  PASS  all $tot figures within tolerance"
  fi
  rm -f "$rep"
fi

# --- Tier 3 -----------------------------------------------------------------
echo
echo "=============================================================="
echo " Tier 3  dissertation.pdf"
echo "=============================================================="
if [ ! -f dissertation.pdf ] || [ ! -f "$REF/dissertation.pdf" ]; then
  dim "  skip  PDF not built"
else
  pa=$(pdfinfo "$REF/dissertation.pdf" | awk '/^Pages/{print $2}')
  pb=$(pdfinfo dissertation.pdf        | awk '/^Pages/{print $2}')
  # Numbers are what matter; layout and pagination are not.
  nums() { pdftotext "$1" - | grep -oE '[-−]?[0-9]+\.[0-9]+' | sed 's/−/-/' | LC_ALL=C sort | uniq -c; }
  pdfacc="$BASE/pdf-numbers.txt"
  cur=$(diff <(nums "$REF/dissertation.pdf") <(nums dissertation.pdf) | grep '^[<>]')
  nd=$(printf '%s\n' "$cur" | grep -c '^[<>]')
  echo "  pages: $pb (reference $pa)"
  echo "  decimal values differing in frequency: $nd"
  if [ "$BLESS" -eq 1 ]; then
    printf '%s\n' "$cur" > "$pdfacc"; chmod 0644 "$pdfacc"
    dim "  BLESS pdf numeric residue ($nd entries recorded)"
  elif [ -z "$cur" ]; then
    green "  PASS  every decimal value appears identically often"
  elif [ -f "$pdfacc" ] && diff -q <(printf '%s\n' "$cur") "$pdfacc" >/dev/null; then
    green "  PASS  numeric residue matches accepted baseline ($nd entries, see $pdfacc)"
  else
    fails=$((fails+1)); red "  FAIL  PDF numeric residue differs from the accepted baseline"
    diff "${pdfacc:-/dev/null}" <(printf '%s\n' "$cur") 2>/dev/null | grep '^[<>]' | head -12 | sed 's/^/        /'
  fi
fi

echo
if [ "$BLESS" -eq 1 ]; then dim "baseline written to $BASE/ -- review before committing"; exit 0; fi
if [ "$fails" -eq 0 ]; then green "All tiers passed."; else red "$fails tier(s) failed."; fi
exit $(( fails > 0 ))
