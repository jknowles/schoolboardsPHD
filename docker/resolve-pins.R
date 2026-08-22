#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Resolve the 2015 package environment to an exact, checksummed lockfile.
#
# Why this exists: backmatter/colophon.tex records a verbatim sessionInfo() from
# the 2015 build, which pins 59 packages. But sessionInfo() only reports what was
# loaded in ONE session, and the five chapters load different things -- so the
# colophon is necessary and not sufficient. This script starts from the colophon,
# adds the packages the code demonstrably loads but the colophon missed, then
# walks the dependency graph of the actual 2015 tarballs until it closes.
#
# Everything is resolved against CRAN Archive, not a snapshot service. MRAN is
# dead (retired July 2023) and Posit's earliest CRAN snapshot is 2017-10-10 --
# verified 404 for 2015-05-15 -- so CRAN Archive is the only source that reaches
# back this far. It is also permanent, which is the point.
#
# Output: inst/pins/packages-2015.tsv (the lockfile) and docker/vendor/*.tar.gz
#
# Usage: Rscript docker/resolve-pins.R
# ---------------------------------------------------------------------------

BUILD_DATE <- as.Date("2015-05-15")   # date on the deposited dissertation.pdf
VENDOR     <- "docker/vendor"
LOCKFILE   <- "inst/pins/packages-2015.tsv"
COLOPHON   <- "backmatter/colophon.tex"

dir.create(VENDOR, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(LOCKFILE), recursive = TRUE, showWarnings = FALSE)

# Ship with R itself; never install these.
BASE <- c("base", "compiler", "datasets", "graphics", "grDevices", "grid",
          "methods", "parallel", "splines", "stats", "stats4", "tcltk",
          "tools", "utils")

# Loaded by the chapters but absent from the colophon's single-session capture.
# GGally and devtools are deliberately excluded: every mention of them in the
# source is commented out (verified), and devtools in particular would drag in
# httr/curl/git2r for nothing.
EXTRA <- c("ROCR", "boot", "RLRsim", "broom", "dplyr", "doParallel", "rms", "reshape")

# apsrtable is the one pin CRAN cannot satisfy. The colophon records 0.9.1, but
# CRAN only ever published up to 0.8-8 -- 0.9.1 exists solely in the author's
# fork. Falling back to the CRAN version is not an option: apsrtable renders
# every regression table in chapters 3, 5 and 6, and the code also calls the
# internal apsrtable:::stars.note. Pinned by commit SHA, built from the pkg/
# subdirectory into a deterministic tarball (sorted entries, commit mtime, no
# owner metadata) so its checksum is stable across rebuilds.
GITHUB_PINS <- list(
  apsrtable = list(repo    = "jknowles/apsrtable",
                   sha     = "bb8fd4571efddac55ff258d61ce49ae11b1905eb",
                   subdir  = "pkg",
                   version = "0.9.1",
                   mtime   = "2015-04-18T03:49:54Z"))

# ---------------------------------------------------------------------------

msg <- function(...) cat(sprintf(...), "\n", sep = "")

read_colophon <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  txt <- sub("^.*Computing Environment", "", txt)
  m <- regmatches(txt, gregexpr("[A-Za-z][A-Za-z0-9._]*~[0-9][0-9A-Za-z._-]*", txt))[[1]]
  parts <- strsplit(m, "~", fixed = TRUE)
  out <- setNames(vapply(parts, `[`, "", 2L), vapply(parts, `[`, "", 1L))
  out[!names(out) %in% BASE]
}

# All (version, date) pairs CRAN has ever published for a package.
cran_versions <- local({
  cache <- new.env(parent = emptyenv())
  function(pkg) {
    if (!is.null(cache[[pkg]])) return(cache[[pkg]])
    grab <- function(url, pat) {
      h <- tryCatch(paste(readLines(url, warn = FALSE), collapse = "\n"),
                    error = function(e) NA_character_)
      if (is.na(h)) return(NULL)
      rows <- regmatches(h, gregexpr(pat, h))[[1]]
      if (!length(rows)) return(NULL)
      data.frame(
        ver  = sub(sprintf("^%s_(.+?)\\.tar\\.gz.*$", pkg), "\\1", rows),
        date = as.Date(regmatches(rows, regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", rows))),
        stringsAsFactors = FALSE)
    }
    pat <- sprintf('%s_[^"]+\\.tar\\.gz</a>\\s*</td><td[^>]*>\\s*[0-9]{4}-[0-9]{2}-[0-9]{2}', pkg)
    a <- grab(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/", pkg), pat)
    # A package whose current release predates the cutoff never entered Archive.
    b <- grab("https://cran.r-project.org/src/contrib/", pat)
    res <- unique(rbind(a, b))
    if (!is.null(res)) res <- res[order(res$date), ]
    cache[[pkg]] <- res
    res
  }
})

# Newest version published on or before BUILD_DATE.
resolve_by_date <- function(pkg) {
  v <- cran_versions(pkg)
  if (is.null(v)) return(NA_character_)
  ok <- v[v$date <= BUILD_DATE, ]
  if (!nrow(ok)) return(NA_character_)
  ok$ver[nrow(ok)]
}

tarball_urls <- function(pkg, ver) {
  f <- sprintf("%s_%s.tar.gz", pkg, ver)
  c(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", pkg, f),
    sprintf("https://cran.r-project.org/src/contrib/%s", f))
}

download <- function(pkg, ver) {
  dest <- file.path(VENDOR, sprintf("%s_%s.tar.gz", pkg, ver))
  if (file.exists(dest) && file.size(dest) > 1000) return(dest)
  for (u in tarball_urls(pkg, ver)) {
    ok <- tryCatch({ download.file(u, dest, mode = "wb", quiet = TRUE); TRUE },
                   error = function(e) FALSE, warning = function(w) FALSE)
    if (ok && file.exists(dest) && file.size(dest) > 1000) return(dest)
  }
  if (file.exists(dest)) unlink(dest)
  NA_character_
}

build_github_pin <- function(pkg) {
  spec <- GITHUB_PINS[[pkg]]
  dest <- file.path(VENDOR, sprintf("%s_%s.tar.gz", pkg, spec$version))
  if (file.exists(dest) && file.size(dest) > 1000) return(dest)
  work <- tempfile(); dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  src <- file.path(work, "src.tar.gz")
  url <- sprintf("https://codeload.github.com/%s/tar.gz/%s", spec$repo, spec$sha)
  ok <- tryCatch({ download.file(url, src, mode = "wb", quiet = TRUE); TRUE },
                 error = function(e) FALSE)
  if (!ok) return(NA_character_)
  untar(src, exdir = work)
  root <- file.path(work, sprintf("%s-%s", sub(".*/", "", spec$repo), spec$sha))
  from <- if (nzchar(spec$subdir)) file.path(root, spec$subdir) else root
  file.rename(from, file.path(work, pkg))
  st <- system2("tar", c("--sort=name", sprintf("--mtime=%s", shQuote(spec$mtime)),
                         "--owner=0", "--group=0", "--numeric-owner", "--format=gnu",
                         "-czf", shQuote(normalizePath(dest, mustWork = FALSE)),
                         "-C", shQuote(work), pkg))
  if (st != 0 || !file.exists(dest)) return(NA_character_)
  # The version in DESCRIPTION must be what the colophon claims.
  lst <- untar(dest, list = TRUE)
  inner <- grep("^[^/]+/DESCRIPTION$", lst, value = TRUE)[1]
  td <- tempfile(); dir.create(td); untar(dest, files = inner, exdir = td)
  got <- read.dcf(file.path(td, inner))[1, "Version"]
  if (!identical(unname(got), spec$version))
    stop(sprintf("%s: fork at %s declares version %s, expected %s",
                 pkg, substr(spec$sha, 1, 8), got, spec$version))
  dest
}

# Depends/Imports/LinkingTo straight from the tarball's own DESCRIPTION -- the
# 2015 dependency graph, not today's.
deps_of <- function(tarball) {
  td <- tempfile(); dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)
  # Top-level DESCRIPTION only. Several packages bundle example packages under
  # inst/ that carry their own DESCRIPTION -- mvtnorm/inst/C_API_Example declares
  # "Depends: mvtnorm" -- which would inject phantom self-dependencies.
  inner <- tryCatch({
    lst <- untar(tarball, list = TRUE)
    grep("^[^/]+/DESCRIPTION$", lst, value = TRUE)[1]
  }, error = function(e) NA_character_)
  if (is.na(inner)) return(character())
  untar(tarball, files = inner, exdir = td)
  d <- read.dcf(file.path(td, inner))
  fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(d))
  if (!length(fields)) return(character())
  raw <- paste(d[1, fields], collapse = ",")
  nm <- trimws(gsub("\\(.*?\\)", "", strsplit(raw, ",")[[1]]))
  nm <- nm[nzchar(nm) & nm != "R" & !is.na(nm)]
  setdiff(unique(nm), BASE)
}

# ---------------------------------------------------------------------------

pins   <- read_colophon(COLOPHON)
msg("colophon supplies %d pinned versions", length(pins))

for (p in EXTRA) if (!p %in% names(pins)) pins[p] <- NA_character_
msg("adding %d packages the colophon missed: %s", length(EXTRA), paste(EXTRA, collapse = ", "))

resolved <- character()   # pkg -> version, once downloaded
origin   <- character()   # colophon | dated | dependency
queue    <- names(pins)

while (length(queue)) {
  pkg   <- queue[1]
  queue <- queue[-1]
  if (pkg %in% names(resolved) || pkg %in% BASE) next

  if (pkg %in% names(GITHUB_PINS)) {
    spec <- GITHUB_PINS[[pkg]]
    tb <- build_github_pin(pkg)
    if (is.na(tb)) { msg("  !! %-16s GitHub pin FAILED", pkg); next }
    resolved[pkg] <- spec$version
    origin[pkg]   <- sprintf("github:%s", substr(spec$sha, 1, 8))
    msg("  ok %-16s %-12s (%s)", pkg, spec$version, origin[pkg])
    new <- setdiff(deps_of(tb), c(names(resolved), queue, BASE))
    if (length(new)) queue <- c(queue, new)
    next
  }

  ver <- if (!is.na(pins[pkg])) pins[[pkg]] else resolve_by_date(pkg)
  if (is.na(ver)) { msg("  !! %-16s could not resolve a version", pkg); next }

  tb <- download(pkg, ver)
  if (is.na(tb)) {
    # A colophon version may predate what Archive kept under that exact name;
    # fall back to the newest release at or before the build date.
    alt <- resolve_by_date(pkg)
    if (!is.na(alt) && !identical(alt, ver)) {
      msg("  ~~ %-16s %s unavailable, falling back to %s", pkg, ver, alt)
      ver <- alt; tb <- download(pkg, ver)
    }
  }
  if (is.na(tb)) { msg("  !! %-16s %s DOWNLOAD FAILED", pkg, ver); next }

  resolved[pkg] <- ver
  origin[pkg] <- if (pkg %in% names(pins) && !is.na(pins[pkg])) "colophon"
                 else if (pkg %in% EXTRA) "dated" else "dependency"
  msg("  ok %-16s %-12s (%s)", pkg, ver, origin[pkg])

  new <- setdiff(deps_of(tb), c(names(resolved), queue, BASE))
  if (length(new)) queue <- c(queue, new)
}

msg("")
msg("resolved %d packages", length(resolved))

# Topological install order: a package installs only after its dependencies.
dep_map <- lapply(names(resolved), function(p)
  intersect(deps_of(file.path(VENDOR, sprintf("%s_%s.tar.gz", p, resolved[[p]]))), names(resolved)))
names(dep_map) <- names(resolved)

order_out <- character()
remaining <- names(resolved)
while (length(remaining)) {
  ready <- remaining[vapply(remaining, function(p) all(dep_map[[p]] %in% order_out), TRUE)]
  if (!length(ready)) { msg("!! dependency cycle among: %s", paste(remaining, collapse = ", ")); ready <- remaining[1] }
  ready <- sort(ready)
  order_out <- c(order_out, ready)
  remaining <- setdiff(remaining, ready)
}

sha256 <- function(f) {
  out <- system2("sha256sum", shQuote(f), stdout = TRUE)
  sub(" .*$", "", out)
}

df <- data.frame(
  order   = seq_along(order_out),
  package = order_out,
  version = unname(resolved[order_out]),
  source  = ifelse(order_out %in% names(GITHUB_PINS), "GitHub", "CRAN-Archive"),
  origin  = unname(origin[order_out]),
  sha256  = vapply(order_out, function(p)
              sha256(file.path(VENDOR, sprintf("%s_%s.tar.gz", p, resolved[[p]]))), ""),
  stringsAsFactors = FALSE)

write.table(df, LOCKFILE, sep = "\t", quote = FALSE, row.names = FALSE)
msg("wrote %s (%d packages)", LOCKFILE, nrow(df))
msg("vendor dir: %s (%s)", VENDOR,
    format(structure(sum(file.size(list.files(VENDOR, full.names = TRUE))), class = "object_size"),
           units = "auto"))
