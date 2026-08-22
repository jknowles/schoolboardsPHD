# `vendor/` — source data brought inside the repository

## Why this exists

`data/dataAssemble.R:9` reads

```r
struc <- list.dirs("../Data/sbelectionresults", recursive = FALSE)
```

— a path *outside* the repository, pointing at the author's 2015 Dropbox
layout. That single line was the only live external dependency in the entire
build; everything else the chapters need is already committed under
`data/cache/`.

The original tree is 1.1 GB, but **the CSVs the code actually parses total
865 KB**. The remaining ~1.1 GB is 982 scanned PDFs, 81 DOCs, 80 ZIPs and 36
XLS files — the county-clerk records the CSVs were transcribed *from*. Those
are provenance, never read by any code, and are archived separately.

So the CSVs are vendored here and the container recreates the 2015 directory
layout around them, which makes `../Data/sbelectionresults` resolve correctly
**without editing `dataAssemble.R`**. See `REPRODUCING.md`.

## Fidelity

`Data/sbelectionresults/` here is a byte-exact mirror of the CSV subset of the
2015 source tree. Verified:

- All 320 CSVs checksum-match the source (`CSV-MANIFEST.sha256`).
- `list.dirs(recursive = FALSE)` returns 314 directories with identical
  basenames in identical order.
- The per-directory `Sys.glob("*.csv")` result is identical for all 314.
- `struc[5]` = `Alma Center`, `struc[6]` = `Almond Bancroft` — the two
  positional indices `dataAssemble.R` hardcodes, the latter supplying the
  column-name template for the whole assembled data frame.

## Three things that look like mistakes and are not

**1. Three empty district directories.** `Dover 1`, `Goodman-Armstrong Creek`
and `Rosendale` contain no CSV at the depth the code globs. They carry a
`.gitkeep` so git preserves them. They must exist: `dataAssemble.R` indexes
`list.dirs()` *positionally*, so a missing directory shifts every later index
and silently changes which file supplies the column template. The loop's `else`
branch prints `skip` for exactly these three.

**2. CSVs nested deeper than one level.** `Dover 1/SCRAPPED/`,
`Goodman-Armstrong Creek/SCRAP/` and
`Gale-Ettrick-Trempealeau/galeettricktrempealeauschoolboardelectioninformation/`
hold CSVs that `Sys.glob(file.path(dir, "*.csv"))` does not reach. They are
mirrored for provenance but are not, and were not, part of the analysis. The
directory names record the author's judgement at the time.

**3. Two files with unusual encodings.** `Elmwood.csv` is ISO-8859 rather than
ASCII, and `New London.csv` uses classic-Mac CR-only line terminators. Both sit
at the *top level*, outside any district directory, so neither is in the read
path. The 311 files `dataAssemble.R` actually reads are uniformly ASCII with LF
endings — confirmed by scanning every byte of all 311. `.gitattributes` marks
`vendor/**` as `-text` so git never normalises any of this regardless.

## A hazard this data carries

Directory ordering is **locale-dependent**, and it genuinely differs here — not
hypothetically. Under `LC_COLLATE=C`, `Cedar Grove Belgium` sorts before
`Cedarburg` (space precedes letters); under `en_US.UTF-8` it sorts after. The
same flip affects `DC Everest`, `De Pere`, `De Soto`, `Elk Mound`, `La Crosse`
and others, starting around index 42.

That changes the `rbind.fill` row order of the assembled data frame, which
changes the RNG stream consumed by the unseeded `sample()` calls in Chapter 4.
It does *not* change `struc[5]`/`struc[6]`, which are identical under both
locales, so the column template is safe either way.

The container pins `LC_COLLATE` for this reason, and the setting is a
verification dial: if chapter output diverges from `reference/2015-build/` in a
way that looks like ordering, try the other locale. The 2015 build ran under
Windows `English_United States.1252`, which matches neither exactly.

## Archived separately

The full 1.1 GB tree, including all scanned source records, is checksummed in
`Reproduction-Archive/Data-tree.sha256` (4,152 files) alongside this repository
and is destined for a DOI-bearing deposit. Nothing in the build needs it.
