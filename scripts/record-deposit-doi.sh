#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Record the source-records deposit DOI everywhere it needs to appear.
#
# The archival deposit is made by hand — it needs a human to agree to a
# repository's terms — and the DOI only exists afterwards. Rather than leave
# that DOI to be pasted into four files and forgotten in a fifth, this puts it
# in all of them at once.
#
#   scripts/record-deposit-doi.sh 10.3886/E123456V1
#
# Idempotent: run it again with a corrected DOI and it replaces the previous
# one rather than accumulating.
# ---------------------------------------------------------------------------
set -euo pipefail

DOI="${1:-}"
if [ -z "$DOI" ]; then
  echo "usage: $0 <doi>            e.g. $0 10.3886/E123456V1" >&2
  exit 2
fi
# Accept a bare DOI or a doi.org URL; normalise to bare.
DOI="${DOI#https://doi.org/}"; DOI="${DOI#http://doi.org/}"; DOI="${DOI#doi:}"
case "$DOI" in
  10.*/*) ;;
  *) echo "does not look like a DOI: $DOI" >&2; exit 2 ;;
esac
URL="https://doi.org/$DOI"
echo "recording $URL"

# 1. CITATION.cff -- uncomment and set the data reference's doi
python3 - "$DOI" <<'PY'
import re, sys, pathlib
doi = sys.argv[1]
p = pathlib.Path("CITATION.cff"); s = p.read_text()
if re.search(r'^\s*doi: "10\..*"\s*$', s, re.M):
    s = re.sub(r'^(\s*)doi: "10\..*"\s*$', rf'\g<1>doi: "{doi}"', s, flags=re.M)
else:
    s = s.replace('    # doi: "10.xxxxx/xxxxxx"   # set once the deposit is published',
                  f'    doi: "{doi}"')
p.write_text(s); print("  CITATION.cff")
PY

# 2. data/provenance/README.md -- the "Getting the raw tree" section
python3 - "$DOI" "$URL" <<'PY'
import re, sys, pathlib
doi, url = sys.argv[1], sys.argv[2]
p = pathlib.Path("data/provenance/README.md"); s = p.read_text()
line = f"The deposit is published at <{url}> (DOI `{doi}`)."
if "doi.org/" in s:
    s = re.sub(r"The deposit is published at <[^>]*> \(DOI `[^`]*`\)\.", line, s)
else:
    s = s.replace("## Getting the raw tree", f"## Getting the raw tree\n\n{line}")
p.write_text(s); print("  data/provenance/README.md")
PY

# 3. README.md -- the Data section
python3 - "$DOI" "$URL" <<'PY'
import re, sys, pathlib
doi, url = sys.argv[1], sys.argv[2]
p = pathlib.Path("README.md"); s = p.read_text()
line = f"The scanned source records they were transcribed from are deposited separately: <{url}>."
if "deposited separately: <https://doi.org/" in s:
    s = re.sub(r"The scanned source records they were transcribed from are deposited separately: <[^>]*>\.", line, s)
else:
    s = s.replace("Two cached files name public officials",
                  f"{line}\n\nTwo cached files name public officials")
p.write_text(s); print("  README.md")
PY

# 4. The appendix records it too -- that is where a reader looks for provenance.
if grep -q "doi.org/" appendix/datacollection/datacollection.tex 2>/dev/null; then
  echo "  appendix/datacollection/datacollection.tex already cites a DOI -- left alone"
else
  echo "  NOTE: appendix/datacollection/datacollection.tex is 2015 text and is NOT"
  echo "        edited automatically. Add the DOI by hand if you want it in the PDF;"
  echo "        doing so changes the typeset document and Tier 3 of make verify."
fi

echo
echo "done. Review with: git diff"
