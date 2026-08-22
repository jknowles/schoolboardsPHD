#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Restore and verify docker/vendor/ from the lockfile.
#
# The tarballs are committed, so normally this only verifies. It re-downloads
# anything missing or corrupt, and it is the recovery path if the vendor
# directory is ever lost.
#
# Every file is checked against the sha256 recorded in
# inst/pins/packages-2015.tsv. A checksum mismatch is a hard failure: the whole
# point of the lockfile is that the bytes going into the container are the
# bytes that produced the 2015 results.
#
# Note this runs on the HOST, not inside the container. rocker/r-ver:3.1.2 is
# built on debian:wheezy, whose curl and OpenSSL predate modern TLS and current
# root certificates, so in-container HTTPS to CRAN cannot be relied on. Fetching
# here and installing from local files sidesteps that entirely.
#
# Usage: Rscript docker/fetch-tarballs.R [--verify-only]
# ---------------------------------------------------------------------------

LOCKFILE <- "inst/pins/packages-2015.tsv"
VENDOR   <- "docker/vendor"
verify_only <- "--verify-only" %in% commandArgs(TRUE)

if (!file.exists(LOCKFILE)) stop("missing ", LOCKFILE, " -- run docker/resolve-pins.R first")
dir.create(VENDOR, recursive = TRUE, showWarnings = FALSE)

lock <- read.delim(LOCKFILE, stringsAsFactors = FALSE)
msg  <- function(...) cat(sprintf(...), "\n", sep = "")

sha256 <- function(f) sub(" .*$", "", system2("sha256sum", shQuote(f), stdout = TRUE))

urls_for <- function(row) {
  f <- sprintf("%s_%s.tar.gz", row$package, row$version)
  if (identical(row$source, "GitHub")) {
    # Rebuilt from the fork rather than downloaded; see resolve-pins.R. If this
    # file is missing, resolve-pins.R must be re-run to reconstruct it.
    return(character())
  }
  c(sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", row$package, f),
    sprintf("https://cran.r-project.org/src/contrib/%s", f))
}

ok <- 0L; fetched <- 0L; bad <- character()

for (i in seq_len(nrow(lock))) {
  row  <- lock[i, ]
  dest <- file.path(VENDOR, sprintf("%s_%s.tar.gz", row$package, row$version))

  if (file.exists(dest) && identical(sha256(dest), row$sha256)) { ok <- ok + 1L; next }

  if (file.exists(dest)) {
    msg("  !! %-16s checksum mismatch, refetching", row$package)
    unlink(dest)
  }
  if (verify_only) { bad <- c(bad, row$package); next }

  got <- FALSE
  for (u in urls_for(row)) {
    got <- tryCatch({ download.file(u, dest, mode = "wb", quiet = TRUE); TRUE },
                    error = function(e) FALSE, warning = function(w) FALSE)
    if (got && file.exists(dest) && identical(sha256(dest), row$sha256)) break
    got <- FALSE
  }
  if (got) { fetched <- fetched + 1L; msg("  ok %-16s %s (fetched)", row$package, row$version) }
  else {
    bad <- c(bad, row$package)
    if (identical(row$source, "GitHub"))
      msg("  !! %-16s missing; rebuild with: Rscript docker/resolve-pins.R", row$package)
    else
      msg("  !! %-16s %s could not be fetched or failed checksum", row$package, row$version)
  }
}

msg("")
msg("verified %d, fetched %d, failed %d (of %d)", ok, fetched, length(bad), nrow(lock))
if (length(bad)) {
  msg("FAILED: %s", paste(bad, collapse = ", "))
  quit(status = 1)
}
msg("vendor directory matches the lockfile exactly.")
