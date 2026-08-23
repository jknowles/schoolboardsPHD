# `data/provenance/` — how the cached data was made

These scripts are **historical record, not part of the build**. Nothing in
`chapters/` sources them, and `make chapters` never runs them. They are here so
the cached datasets have a documented origin rather than appearing by magic.

Each was run by hand, once, in 2015, against a raw source tree that is **not in
this repository** — roughly 1.1 GB of scanned county-clerk records, spreadsheets
and voter files. Between them they produced the `data/cache/*.rda` files that the
chapters actually read.

| Script | Reads | Writes |
|---|---|---|
| `dataMerge.R` | voter counts, MCD crosswalk, school-district/municipality pieces | `data/cache/DataMergeVAP.rda` |
| `unionStrengthData.R` | WERC recertification results, teacher contract choices | `data/cache/WERC.rda` |
| `cleanHSC.R` | High School Completion files | `data/cache/HSC.rda` |
| `dataBoardSize.R` | `data/cache/SchoolBoardRosterVerification.csv` | `data/cache/boardSize.rda` |

`dataBoardSize.R` is the exception: its input *is* in the repository, so it can
be re-run as-is.

## Why they are not wired up

The build depends on the `.rda` outputs, which are committed. Re-deriving them
would require the archived raw tree, and re-deriving them is not what
reproducing the dissertation means — the cached data *is* the analysed data. If
you want to audit how it was constructed, read these; if you want to reproduce
the results, you do not need them.

They still contain paths pointing outside the repository (`../Data/...`) and,
in `dataMerge.R`, a `setwd()` back to `../../../MasterText`. Those are left as
they were: they document the 2015 working layout, and rewriting paths in scripts
nobody runs would be false tidiness. The one exception is `cleanHSC.R`, whose
hardcoded `C:/Users/Jared/Dropbox/...` would not even parse as a location on any
other machine; it now reads `HSC_DIR` from the environment and fails with a
useful message instead of a confusing one.

## Getting the raw tree

The full source tree — 3,995 files, 1.6 GB — is archived outside this repository
and deposited under its own DOI. It is not needed to reproduce anything; it is
the evidence layer, so that the numbers stay checkable after the working copies
are gone.

<!-- deposit-doi -->

Restore it one level above the repository, matching the 2015 layout, and the
scripts here will find it:

```
<parent>/
  Data/            <- the archived source tree
  MasterText/      <- this repository
```

### Rebuilding the deposit

The bundle is reproducible rather than a one-off:

```bash
scripts/build-deposit.sh ../Data
```

It stages the tree (excluding editor state — `.Rproj.user`, `.Rhistory`,
`.RData`, `.Rproj`; 157 files, nothing redacted), writes a SHA-256 manifest over
all 3,995 remaining files, carries in `inst/deposit-template/`, and zips it to
about 1.1 GB.

It also **cross-checks the 320 transcribed CSVs against `data/raw/`** and refuses
to build if they have drifted apart, so the deposit and this repository cannot
silently disagree about what the records say.

Zip containers are not bit-reproducible across implementations, so the guarantee
is over contents: two independent builds produce byte-identical
`MANIFEST.sha256` files, which has been verified.

Once the deposit is published, `scripts/record-deposit-doi.sh <doi>` writes the
DOI into `CITATION.cff`, `README.md` and this file in one step.

## The one thing here that is in the build path

Nothing. `data/dataAssemble.R` and the five `data/cleanandprep_*.R` scripts stay
in `data/` because the chapters do source them. Everything in this directory is
inert.
