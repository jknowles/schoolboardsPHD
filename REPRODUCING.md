# Reproducing this dissertation

*School Boards and the Democratic Promise* was written in 2015 with knitr and
pdfLaTeX, on a Windows 7 machine running R 3.1.2. This document explains how to
rebuild it now, and — more usefully — what was in the way.

The goal was never to modernise the analysis. It was to make the **same numbers**
come out again. So this branch changes the *environment* and leaves the 2015
source alone:

```
git diff --diff-filter=MD --name-only v2015-deposit..HEAD | grep -E '\.(R|Rnw|tex|bib|bst)$'
```

returns nothing, and `make audit` checks that on demand. Every fix below lives in
a Dockerfile, a symlink, or a new file. Nothing edits a line of 2015 code.

## Quick start

```bash
make image        # build the R 3.1.2 container (compiles 99 pinned packages, ~15 min)
make chapters     # knit the five .Rnw chapters -> .tex + figures
make verify       # compare against reference/2015-build/
```

`make tex-image && make pdf` typesets `dissertation.pdf`. `make all` does
everything. `make help` lists the targets.

## What "reproduced" means here

Three tiers, because the word means something different at each level.

| Tier | Artifact | Standard | Why |
|---|---|---|---|
| 1 | `chapters/*/*.tex` | **byte-identical** | Every coefficient, standard error, table cell and inline `\Sexpr` number passes through these five files. A byte match is a complete statement that the analysis reproduced. This is the acceptance test. |
| 2 | `phd_figs/*` (192) | content-identical | Figure PDFs embed creation timestamps and randomised font subset tags, so bytes cannot match. Compared by extracted text layer (axis labels and tick values are data) plus a rasterised pixel hash. |
| 3 | `dissertation.pdf` | text layer identical | Byte equality across TeX versions is not achievable and was never the goal. |

The 2015 outputs are committed under `reference/2015-build/` with a
`MANIFEST.sha256`. They were captured first, before anything else, because
`.gitignore` excluded `*.pdf` and `*.png` — all 192 figures, the final PDF and
both knitr caches were untracked and existed only on one disk.

## The environment

`rocker/r-ver:3.1.2` — genuinely R 3.1.2 on Debian wheezy, not a modern R in
compatibility mode. That distinction carries the whole project. **R changed the
default `sample()` algorithm in 3.6.0** (`sample.kind`: Rounding → Rejection),
and this dissertation draws from `boot(R=150)`, `PBmodcomp(nsim=200)`,
`arm::sim(n.sims=1000)`, `exactRLRT`, and two unseeded `sample()` calls in
chapter 4. Running the real interpreter sidesteps that instead of papering over
it with `RNGversion()`.

99 R packages are pinned in `inst/pins/packages-2015.tsv` with a sha256 each, and
their source tarballs are committed under `docker/vendor/`. See
`inst/pins/README.md` for how each version was decided. Two things are worth
knowing:

- **`backmatter/colophon.tex` contains a verbatim `sessionInfo()`** from the 2015
  build. It is the single most valuable artifact in the repository and it seeded
  the entire lockfile.
- **`apsrtable` is pinned to a GitHub fork**, not CRAN. The colophon says 0.9.1;
  CRAN never published past 0.8-8. Since apsrtable renders every regression table
  in chapters 3, 5 and 6, that difference would have been silently wrong.

## What was actually in the way

Each of these was verified, not assumed, and each is fixed in the environment.

### 1. The package repository no longer exists

`rocker/r-ver:3.1.2` configures CRAN as
`https://mran.microsoft.com/snapshot/2014-10-31`. Microsoft **retired MRAN in
July 2023**, so `install.packages()` in the stock image fails outright with
"cannot open the connection".

Posit's Public Package Manager is not a substitute: its earliest CRAN snapshot is
**2017-10-10**, and `packagemanager.posit.co/cran/2015-05-15` returns 404.

CRAN Archive is the only source that reaches back to 2015. The image installs
nothing from the network — every package arrives as a checksummed local tarball,
and `Rprofile.site` points `repos` at a deliberately nonexistent path so that a
stray `install.packages()` fails loudly rather than quietly pulling something
modern.

### 2. NLopt

`nloptr 1.0.4` — a hard dependency of `lme4` — looks for a system NLopt and,
failing that, downloads `nlopt-2.4.2.tar.gz` from `ab-initio.mit.edu` and builds
it in place. Three problems compounded:

- The download runs through `R -e download.file(...)`, and R 3.1.2 predates the
  `libcurl` method (added in 3.2.0).
- Its in-place build patches NLopt sources with `ed`, which is not installed.
- Debian wheezy packages only NLopt 2.3, which would have silently substituted a
  different optimiser version underneath `lme4`.

NLopt **2.4.2** — the version `nloptr 1.0.4` pins, and therefore what 2015 used —
is vendored and built in the image. One upstream wrinkle: `--with-cxx` makes
NLopt install itself as `libnlopt_cxx` while its own generated `nlopt.pc` still
advertises `-lnlopt`, so the link fails with "cannot find -lnlopt". The image
adds alias symlinks rather than dropping `--with-cxx`, because nloptr's own
bundled build links `libnlopt_cxx.a`.

### 3. A case-sensitivity bug that only ever worked on Windows

`data/cleanandprep_POLICY.R:5` loads `data/cache/hsc.rda`. The file on disk is
`HSC.rda`. Harmless on a case-insensitive filesystem, fatal on Linux — **chapter
6 cannot build**. `entrypoint.sh` creates a `hsc.rda` symlink rather than
touching the source.

### 4. Paths pointing outside the repository

`data/dataAssemble.R:9` reads `../Data/sbelectionresults` — the author's 2015
Dropbox layout. It was the only live external dependency in the whole build.

The 865 KB of CSVs that the code actually parses are vendored under
`vendor/Data/` (the surrounding 1.1 GB is scanned county-clerk source records,
which no code reads). The container then mounts the repository at
`/work/dissertation/MasterText` so that `../Data/sbelectionresults` **resolves
correctly without editing that line**. See `vendor/README.md`, including why
three empty district directories must be preserved.

### 5. Figure paths two levels above the repository

The generated `.tex` reference figures as `../../phd_figs/<name>`. LaTeX resolves
those from the main document's directory — the repository root — so they point
two levels above it. MiKTeX accepted this in 2015; TeX Live's default
`openin_any = p` refuses `..` outright. The TeX image sets `openin_any = a` and
`entrypoint.sh` provides `/work/phd_figs`.

### 6. bibtex silently produced nothing

`build.R` exported `BIBINPUTS` and `BSTINPUTS` so LaTeX could find `bib/` and the
locally modified `includes/chicago.bst`. Setting those **without a trailing
colon** makes kpathsea *replace* the default search path rather than prepend to
it. bibtex then exits 0, writes no `.bbl`, and you lose the entire references
chapter — 23 pages and 512 undefined citations — with no error anywhere except
the LaTeX log. The `Makefile` sets `BIBINPUTS=...bib:` and `BSTINPUTS=...includes:`.

### 7. A UTF-8 defect in the deposited text

`chapters/voterturnout/voterturnout.tex` line 194 contains three orphaned `0xE2`
bytes. They are the lead byte of a UTF-8 en-dash whose two continuation bytes
were replaced, somewhere in 2015, by the literal ASCII text `<U+0080><U+0093>`:

```
62 65 6E 65 66 69 74 73 20 | E2 | 3C 55 2B 30 30 38 30 3E 3C 55 2B 30 30 39 33 3E
b  e  n  e  f  i  t  s     |  ?  | <  U  +  0  0  8  0  >  <  U  +  0  0  9  3  >
```

`includes/preamble.tex` loads `fontenc` but never `inputenc`, so 2015 LaTeX passed
the bytes through untouched and **the deposited PDF renders the same garbage** —
`groupâ<U+0080><U+0099>s` appears in `dissertation.pdf` at page 153. Modern LaTeX
defaults to UTF-8 input and hard-errors instead.

Faithful reproduction means reproducing the defect, not repairing it. The build
requests latin1 on the command line —

```
pdflatex -jobname=dissertation "\RequirePackage[latin1]{inputenc}\input{dissertation}"
```

— which restores the 2015 interpretation without editing a 2015 file. If you ever
want this *fixed*, that is a `modernize` change, and it will legitimately alter
the rendered text.

### 8. Locale changes the answer

`data/dataAssemble.R` indexes `list.dirs()` **positionally** (`struc[5]`,
`struc[6]`) and concatenates the district CSVs in that order. That order is
locale-dependent, and it genuinely differs here — not hypothetically:

| | `LC_COLLATE=C` | `en_US.UTF-8` |
|---|---|---|
| `Cedar Grove Belgium` | before `Cedarburg` | after |

with the same flip on `DC Everest`, `De Pere`, `De Soto`, `Elk Mound` and
`La Crosse`, starting around index 42. That changes the row order of the
assembled data frame, which changes the RNG stream chapter 4 draws from.

The image defaults to `en_US.UTF-8`, since the 2015 build ran under Windows
`English_United States.1252`. It is a dial:

```bash
make chapters LOCALE=C.UTF-8
```

`struc[5]` and `struc[6]` resolve identically under both, so the column-name
template is safe either way.

## Things that look like bugs and are load-bearing

Do not "clean these up" on this branch. Some are addressed on `modernize`, where
`make verify` gates every commit.

**The `setwd()` dance.** Every `.Rnw` setup chunk calls `setwd("../../")`, but
knitr restores the working directory after each chunk. So the setup chunk runs at
the repository root — which is why it can say `source("data/dataAssemble.R")` —
while every later chunk runs in the chapter directory, which is why those say
`load("../../data/cache/springElectionVotes.rda")` and
`fig.path="../../phd_figs/"`. Both halves are consistent once you know the
working directory flips back. Knitting from anywhere else silently breaks it.

**`detachPkgs()`.** `R/thesis_functions.R` force-detaches packages in a
`sample()`-shuffled loop between chapters, perturbing RNG state. It turns out not
to matter: every chapter is insulated. Chapters 2, 5 and 6 consume no randomness
at all, and 3 and 4 both call `set.seed(51315)` before their first stochastic
call. This is also why chapters can be verified one at a time.

**`struc[5]` / `struc[6]`.** Hardcoded positional indices selecting the CSV that
supplies the column-name template for the entire assembled frame. Fragile, and
the reason `vendor/README.md` insists the three empty district directories stay.

## Where the fragility now sits

Ranked by how likely it is to produce a diff:

1. **`voterturnout.Rnw:2015` and `:2049`** — `sample(unique(plotdf$distid), 12)`
   with no local seed. They inherit whatever RNG state the chapter has reached,
   so they are correct only if every preceding draw is bit-identical: four
   `exactRLRT` calls, four `FEsim` calls, and fifteen `boot(R=150)` runs.
2. **`boot` / `PBmodcomp` chunks** — chapter 3 and 4's expensive resampling.
3. **`lme4` convergence digits** — pinned to 1.1-7, but chapters 3 and 5 also
   drive it through `optimx 2013.8.7` with `method="nlminb"`.

Chapter 2 is the right place to start verifying: it is purely descriptive, uses
no RNG, and exercises the whole toolchain. Then 6, then 3, 5, and 4 last.

If a chunk proves irreducible, the 2015 knitr caches for exactly these
computations survive — chapters 3 and 4 marked them `cache=TRUE` at the time —
and are archived with checksums in `reference/2015-knitr-cache-MANIFEST.sha256`.
**If any of them is ever used to satisfy a build, it will be stated here.** A
reused 2015 number and a recomputed 2015 number are not the same claim.

### Tier 3 — typesetting: verified

Compiling the **2015 `.tex` files** with the modern TeX container isolates the
typesetting toolchain from the analysis. Result:

| | 2015 (MiKTeX) | rebuild (TeX Live 2022) |
|---|---|---|
| Pages | 368 | 369 |
| Undefined citations / references | — | 0 / 0 |
| Distinct decimal values in the text | 1,737 | 1,737 |
| Values differing | — | **2, and only in frequency** |

The two are `3.14` and `5.19` — List-of-Tables entries for tables that span a
different number of pages, which is also where the extra page comes from and why
contents pagination shifts by one from about page 264. Neither appears next to a
standard error or significance marker.

**Every statistical value in the document reproduces identically.** The remaining
`pdftotext` diff is List-of-Tables line grouping and pagination, which is what
"byte-identical PDF is not the goal" meant in practice.

<!-- STATUS: Tier 1 and Tier 2 to be completed once the R image finishes.
     - sessionInfo diff (reference/sessionInfo-rebuild.txt vs colophon)
     - per-chapter tier-1 result
     - any cache reuse, named explicitly -->

## The data

`data/cache/SchoolBoardRosterVerification.csv` and `districtadmin0211.csv`
contain names and addresses of school board members and district administrators.
These are elected and appointed public officials, and the records are public
election returns and Department of Public Instruction rosters, published as such.
`vendor/README.md` and (in due course) `DATA.md` document provenance per file.

## Repository layout added by this work

```
docker/          Dockerfile.r312, Dockerfile.tex, entrypoint.sh,
                 resolve-pins.R, fetch-tarballs.R, install-pinned.R,
                 vendor/  (99 package tarballs + nlopt 2.4.2)
inst/pins/       packages-2015.tsv  -- the lockfile
reference/       2015-build/  -- the oracle, checksummed
scripts/         build_chapters.R (mirrors build.R), verify.sh
vendor/Data/     the 865 KB of raw election CSVs
Makefile         image / chapters / pdf / verify / audit
```

`build.R` is untouched and remains the historical 2015 driver.
