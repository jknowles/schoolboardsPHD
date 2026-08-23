# School Boards and the Democratic Promise

**Jared E. Knowles** · PhD dissertation, Political Science · University of
Wisconsin–Madison, 2015

A study of school board elections in Wisconsin from 2002–2012: who runs, who
votes, whether it changes anything, and what the Act 10 upheaval did to all
three. Built on an original panel of election returns from over 300 school
districts, assembled from county clerk records.

**This repository rebuilds the dissertation from source, and the numbers come out
the same.** That is not a claim about intent — it is checked, and the check is in
here.

---

## Build it

You need Docker and `make`. Nothing else — no R, no LaTeX, no package installs.

```bash
make image        # the R 3.1.2 analysis container (~15 min, compiles 99 pinned packages)
make tex-image    # the LaTeX container
make chapters     # knit the five analysis chapters -> .tex + figures
make pdf          # typeset dissertation.pdf
make verify       # compare everything against the frozen 2015 outputs
```

`make all` does the last three. `make help` lists everything.

## What "reproduces" means here, concretely

`reference/2015-build/` holds the original 2015 outputs — the knitted chapters,
all 192 figures, and the deposited PDF — checksummed. `make verify` compares a
fresh build against them in three tiers. The current result:

| | Result |
|---|---|
| **Chapters 2, 4 and 6** | numerically **exact** (2 and 6 byte-identical) |
| **All five chapters** | 5,058 decimal values, **43 differ (0.85%)**, largest difference **0.006** |
| **Significance markers** | **0 of 967 changed** |
| **Figures** | 91 of 96 within tolerance |
| **Document** | 369 pages vs 368; zero undefined citations |

The residual drift sits entirely in chapters 3 and 5 — the two that fit `glmer`
through derivative-free optimisers, where platform `libm` differences between
Windows and glibc surface in the last printed digit. It is not hidden: the exact
reviewed diff for every chapter is committed under
`reference/accepted-differences/`, and `make verify` passes **only** if a rebuild
matches it exactly, so any regression fails loudly.

[`REPRODUCING.md`](REPRODUCING.md) explains all of it, including the eight things
that had to be fixed to make a 2015 toolchain run at all.

## Layout

```
chapters/          the five analysis chapters as knitr .Rnw, plus three static ones
data/              dataAssemble.R + cleanandprep_*.R (the build path)
  raw/             the primary election records, 320 CSVs
  cache/           committed intermediate datasets the chapters read
  provenance/      how the cache was made; historical, not run by the build
R/                 thesis_functions.R
docker/            two Dockerfiles, the pin resolver, 99 vendored package tarballs
inst/pins/         packages-2015.tsv -- the lockfile, with checksums
reference/         the 2015 oracle and the accepted-difference baseline
scripts/           build_chapters.R, verify.sh
```

`build.R` is the original 2015 driver, kept untouched.
`scripts/build_chapters.R` is its container-side twin.

## The two branches

The work was deliberately split so that "made it run again" and "made it
pleasant to run" are separate, reviewable changesets.

- **`resurrect`** (`v1.0-resurrection`) — got the 2015 code running on a modern
  machine by **changing the environment and never the code**. Between
  `v2015-deposit` and that tag, exactly one 2015 file is modified: `.gitignore`.
  `make audit` proves it.
- **`modernize`** — fixes the things `resurrect` deliberately worked around,
  with `make verify` gating every commit so each cleanup is proven
  results-neutral before it lands.

## Reading the research

- [`RESEARCH-NOTES.md`](RESEARCH-NOTES.md) — the author's working summary of the
  argument, hypotheses and variables, written while the research was underway.
- `reference/2015-build/dissertation.pdf` — the dissertation as deposited.
- `appendix/datacollection/` — how the data was collected.

## Data

The election returns, board rosters and administrative records are **public
records** from Wisconsin county clerks, the Department of Public Instruction, the
Employment Relations Commission, the Census, and NCES. See
[`data/raw/README.md`](data/raw/README.md) for provenance and for three things in
the raw tree that look like mistakes and are not.

Two cached files name public officials — elected board members and appointed
district administrators — as the public rosters and election returns they came
from do. See [`LICENSE`](LICENSE).

## Licence

Scholarship under CC BY 4.0, code under MIT, data as public records, third-party
components under their own terms. [`LICENSE`](LICENSE) maps each.

To cite:

> Knowles, Jared E. (2015). *School Boards and the Democratic Promise.*
> PhD dissertation, University of Wisconsin–Madison.
