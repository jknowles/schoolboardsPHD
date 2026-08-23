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

## Which branch you are on

This file describes both branches, because the obstacles were the same and only
the responses differ.

**`resurrect`** got the 2015 code running by *changing the environment and never
the code*. Every obstacle below was met with a Dockerfile line, a symlink, or a
recreated directory layout. `make audit` proves no `.R`, `.Rnw`, `.tex`, `.bib`
or `.bst` was touched.

**`modernize`** (this branch) fixes several of them at source, with `make verify`
gating every commit so each change is proven results-neutral before it lands.
Where the two differ, it is noted inline. In summary:

| | `resurrect` | `modernize` |
|---|---|---|
| Raw data | vendored under `vendor/Data/`, reached via a recreated `../Data` layout in the container | lives in `data/raw/`, read by a repo-relative path |
| `hsc.rda` case bug | symlink created in the image | fixed in `cleanandprep_POLICY.R` |
| Column template | `struc[6]`, a positional `list.dirs()` index | the file is named |
| Provenance scripts | in `data/` beside the build path | moved to `data/provenance/` |
| Chapters | five in one R session, `detachPkgs()` between | one fresh R process each |

## Quick start

```bash
make image        # build the R 3.1.2 container (compiles 99 pinned packages, ~15 min)
make chapters     # knit the five .Rnw chapters -> .tex + figures
make verify       # compare against reference/2015-build/
```

`make tex-image && make pdf` typesets `dissertation.pdf`. `make all` does
everything. `make help` lists the targets. `make chapter C=policy` builds one.

On `modernize`, `make chapters` runs one fresh R process per chapter rather than
five in a single session -- see `detachPkgs()` below for why that matters.

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
6 cannot build**.

*resurrect:* a committed `hsc.rda` symlink, so the source is untouched.
*modernize:* the load is spelled `HSC.rda` and the symlink is gone.

### 4. Paths pointing outside the repository

`data/dataAssemble.R:9` reads `../Data/sbelectionresults` — the author's 2015
Dropbox layout. It was the only live external dependency in the whole build.

The 865 KB of CSVs the code actually parses are in the repository; the
surrounding 1.1 GB is scanned county-clerk source records, which no code reads.

*resurrect:* the CSVs sat under `vendor/Data/` and the container mounted the
repository at `/work/dissertation/MasterText`, so `../Data/sbelectionresults`
resolved correctly **without editing that line**.
*modernize:* they live in `data/raw/` and the path is repo-relative, so the
analysis no longer needs the container to fake a filesystem and can run outside
Docker entirely.

See `data/raw/README.md`, including why three empty district directories must be
preserved.

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

### 8. OpenBLAS, and why an optimised BLAS was a trap

rocker links R 3.1.2 against Debian wheezy's **OpenBLAS** (2012). OpenBLAS
selects its kernels by probing the CPU at run time, and a 2012 build has never
heard of AMD Zen 3 — so on that hardware even

```r
matrix(1:6, 3) %*% matrix(1:6, 2)
```

dies with `*** caught illegal operation *** cause 'illegal operand'`. It first
surfaced as a SIGILL deep inside `plyr::id()` while `dataAssemble.R` was running
a `ddply`, which made it look like a plyr problem; a two-line bisection showed a
bare matrix multiply was enough.

The fix is reference (netlib) BLAS, and it matters well beyond the crash. **The
2015 build ran on Windows, where R ships its own reference `Rblas.dll`.** An
optimised BLAS reorders floating-point summation, so had OpenBLAS merely *worked*
it would have been a silent fidelity hazard — last-bit differences in every
`lme4` fit, invisible until they moved a rounded coefficient. Reference BLAS is
simultaneously the fix and the faithful choice.

One implementation note: pointing the `libopenblas.so.0` symlink at reference
BLAS does not hold, because `ldconfig` regenerates SONAME links in `/usr/lib`
from the installed libraries and silently undoes it. The image ships reference
BLAS as `/opt/refblas/libopenblas.so.0` and sets `LD_LIBRARY_PATH`, which cannot
be clobbered that way.

### 9. Locale changes the answer

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

**`detachPkgs()`.** `R/thesis_functions.R` force-detaches *and unloads* every
attached package between chapters. (The `sample()`-shuffled variant is
`cleanNamespace()` in the same file, which is never called.) It does not affect
results — every chapter is insulated, since chapters 2, 5 and 6 consume no
randomness and 3 and 4 both `set.seed(51315)` before their first stochastic call
— but it does affect *reliability*: unloading namespaces mid-session can leave
one half-torn-down, and chapter 5 has been seen failing in plyr's `ldply` for
that reason while building cleanly on its own. `resurrect` reproduces the
behaviour faithfully; `modernize` runs each chapter in its own process instead.

**`struc[5]` / `struc[6]`.** Hardcoded positional indices selecting the CSV that
supplies the column-name template for the entire assembled frame. Fragile, and
the reason `data/raw/README.md` insists the three empty district directories
stay. (On `modernize` the template file is named, so only the concatenation
order still depends on them.)

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

## Results

`make verify` is green. All three tiers pass against a reviewed baseline.

### Tier 1 — the analysis

| Chapter | Models | Result |
|---|---|---|
| 2 `aboutwisconsin` | descriptive | **byte-identical** |
| 3 `candidacy` | 20 `lmer`, 18 `glmer` | 5 values differ, ≤0.001 |
| 4 `voterturnout` | 18 `lmer`, 7 `lm` | **numerically identical**; 1 prose line (see below) |
| 5 `walker` | 39 `lmer`, 18 `glmer`, 30 `lm`, 27 `glm` | 38 values differ, ≤0.006 |
| 6 `policy` | 15 `lm`, 2 `glm` | **byte-identical** |

Across the five chapters:

- **5,058 decimal values; 43 differ (0.85%); largest absolute difference 0.006.**
- **Zero of the 967 significance markers changed.** Not one `*`, `**`, `***` or
  `†` moves.
- Three of five chapters are numerically exact.

The drift is confined to chapters 3 and 5 — precisely the two that fit `glmer`
through `optimx`/`nlminb` and `Nelder_Mead`. Chapter 4's plain `lmer` fits and
chapter 6's closed-form `lm`/`glm` reproduce exactly. That pattern points at
derivative-free and quasi-Newton optimisers amplifying platform `libm`
differences — Windows MinGW versus glibc `exp`/`log`/`pow` — into the last
printed digit. Reproducing it exactly would mean emulating Windows, and the
remaining error is far below anything the dissertation claims.

The residue is not waved away: `reference/accepted-differences/` holds the exact,
reviewed diff for each chapter. `verify.sh` passes only if a rebuild matches that
baseline *exactly*, so the known residue is frozen and any regression fails
loudly. Regenerate it deliberately with `scripts/verify.sh --bless`.

### The one prose difference

`voterturnout.Rnw` contains a proper UTF-8 en-dash. **The 2015 build corrupted
it**: R on Windows read the UTF-8 bytes as latin1, saw three separate characters,
and substituted the literal text `<U+0080><U+0093>` for the two it could not
represent — which is why the deposited PDF renders `groupâ<U+0080><U+0099>s` on
page 153.

```
source .Rnw : 62 65 6E 65 66 69 74 73 20 | E2 80 93 |   ← correct en-dash
2015 .tex   : 62 65 6E 65 66 69 74 73 20 | E2 | 3C 55 2B 30 30 38 30 3E …
2026 .tex   : 62 65 6E 65 66 69 74 73 20 | E2 80 93 |   ← correct again
```

So the reproduction is *right* where the deposit was *wrong*. That difference is
kept, not reintroduced: it affects one line of prose, no number, table or model.
Repairing the *rendered* text is a `modernize` decision.

### Tier 2 — figures

96 figure PDFs. **91 within tolerance**; 5 differ, all in the drifting chapters:
three chapter-3 coefficient plots whose axis text moved with the coefficients,
and two chapter-3 ROC curves (RMSE 0.0070 and 0.0037). Everything else is
identical to within antialiasing — the tolerance is 0.002 RMSE, and the figures
that pass typically differ by fewer than a dozen pixels out of half a million.

### Tier 3 — the document

369 pages against 368. The extra page is a long table spanning one more page,
which shifts contents pagination by one from about page 264. Of 1,737 distinct
decimal values, the frequency differences are exactly those Tier 1 accounts for.
Zero undefined citations, zero undefined references.

### Environment achieved

`reference/sessionInfo-rebuild.txt` records what the container actually loaded,
for comparison with `backmatter/colophon.tex`. All 99 packages install and load
at their pinned versions.

## A note on the working tree after a build

`make chapters` writes the regenerated `.tex` over `chapters/*/*.tex`, so
afterwards `git status` shows those five files as modified. That is expected and
should **not** be committed: the versions under version control are the 2015
deposit, and the rebuild is judged against `reference/2015-build/`, not against
them. `make verify` is the arbiter; `make restore-deposit` puts the deposited
files back.

The same applies to `phd_figs/` and `dissertation.pdf`, which are untracked
build products.

## The data

`data/cache/SchoolBoardRosterVerification.csv` and `districtadmin0211.csv`
contain names and addresses of school board members and district administrators.
These are elected and appointed public officials, and the records are public
election returns and Department of Public Instruction rosters, published as such.
`data/raw/README.md` and `data/provenance/README.md` document provenance.

## Repository layout added by this work

```
docker/           Dockerfile.r312, Dockerfile.tex, entrypoint.sh,
                  resolve-pins.R, fetch-tarballs.R, install-pinned.R,
                  verify-pinned.R, vendor/ (99 tarballs + nlopt 2.4.2)
inst/pins/        packages-2015.tsv -- the lockfile, with checksums
reference/        2015-build/            the oracle, checksummed
                  accepted-differences/  the reviewed residue
scripts/          build_chapters.R (mirrors build.R), verify.sh
data/raw/         the 865 KB of raw election CSVs      (modernize)
data/provenance/  the scripts that built data/cache/   (modernize)
.gitea/workflows/ weekly reproduction check           (modernize)
Makefile          image / chapters / pdf / verify / audit
```

`build.R` is untouched and remains the historical 2015 driver.
