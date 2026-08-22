# `inst/pins/` — the 2015 package lockfile

`packages-2015.tsv` pins every R package the build needs, at the exact version
used in 2015, with a sha256 over the source tarball.

| column | meaning |
|---|---|
| `order` | install order; a package never installs before its dependencies |
| `package`, `version` | what to install |
| `source` | `CRAN-Archive` or `GitHub` |
| `origin` | how the version was decided — see below |
| `sha256` | checksum of the tarball in `docker/vendor/` |

## How each version was decided

**`colophon` (59 packages).** `backmatter/colophon.tex` contains a verbatim
`sessionInfo()` from the 2015 build. These versions are transcribed from it
mechanically, not by hand, and all 59 are reproduced exactly in the lockfile.

**`dated` (8 packages).** `sessionInfo()` only reports what was loaded in *one*
session, and the five chapters load different things — so the colophon is
necessary but not sufficient. `ROCR`, `boot`, `RLRsim`, `broom`, `dplyr`,
`doParallel`, `rms` and `reshape` are demonstrably loaded by the chapter code
and absent from the colophon. Each is resolved to the newest CRAN release
published **on or before 2015-05-15**, the date on the deposited PDF.

`GGally` and `devtools` are deliberately *excluded*: every mention of them in
the source is inside a comment (verified across all `.Rnw` and `.R` files), and
devtools would otherwise drag in httr/curl/git2r for nothing.

**`dependency` (32 packages).** Discovered by walking `Depends`/`Imports`/
`LinkingTo` from the DESCRIPTION inside each **2015 tarball** — the dependency
graph as it stood then, not as it stands now — until the set closed.

**`github:bb8fd457` (1 package).** `apsrtable`. See below.

## Why apsrtable is special

The colophon records `apsrtable 0.9.1`. **CRAN never published 0.9.1** — it
tops out at 0.8-8. Version 0.9.1 exists only in `jknowles/apsrtable`, a fork of
`malecki/apsrtable`, on the `dev` branch.

Falling back to the CRAN version would be silently wrong: apsrtable renders
every regression table in chapters 3, 5 and 6, and the chapter code also reaches
into the internal `apsrtable:::stars.note`. So it is pinned by commit SHA
`bb8fd4571efddac55ff258d61ce49ae11b1905eb` and built from the `pkg/`
subdirectory into a deterministic tarball — sorted entries, mtime fixed to the
commit date, no owner metadata — which makes its sha256 stable across rebuilds.
`resolve-pins.R` asserts that the fork's DESCRIPTION really does say 0.9.1
before accepting it.

This is also the most fragile dependency in the project: a personal fork with
no releases, which is why the tarball is committed rather than fetched.

## Why CRAN Archive and not a snapshot service

Both obvious options are dead ends, verified rather than assumed:

- **MRAN** — what `rocker/r-ver:3.1.2` itself configures — was retired by
  Microsoft in July 2023. `install.packages()` in the stock image fails outright.
- **Posit Public Package Manager** has dated CRAN snapshots, but the earliest is
  **2017-10-10**. `packagemanager.posit.co/cran/2015-05-15` returns 404.

CRAN Archive reaches back indefinitely and is retained as policy. All 99
tarballs were fetched and checksummed from it (bar apsrtable).

## Regenerating vs restoring

```bash
Rscript docker/resolve-pins.R              # re-derive the lockfile from scratch
Rscript docker/fetch-tarballs.R            # restore docker/vendor/ from lockfile
Rscript docker/fetch-tarballs.R --verify-only   # checksum what is already there
```

`resolve-pins.R` hits the network and rebuilds the whole graph; you only need it
if the pin set changes. `fetch-tarballs.R` is the normal path and fails hard on
any checksum mismatch.

The tarballs (60 MB) are committed. That is deliberate: this project exists
because a ten-year-old dependency chain evaporated, and vendoring is that lesson
applied to itself. A durable copy also lives in `Reproduction-Archive/`.
