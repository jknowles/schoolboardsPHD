#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Install the pinned 2015 package set, offline, from vendored source tarballs.
#
# Runs inside the container at image-build time. Nothing here touches the
# network: MRAN (which this base image configures) was retired in 2023, and
# debian:wheezy's OpenSSL cannot negotiate with modern CRAN anyway. Every
# tarball is supplied by the host and checked against the lockfile's sha256
# before it is installed.
#
# Installs into site-library, which precedes the bundled library on .libPaths(),
# so the pinned MASS/Matrix/boot/etc. shadow the versions that ship with R 3.1.2.
# The colophon records newer versions of several recommended packages than
# R 3.1.2 bundles, so this shadowing is required, not incidental.
# ---------------------------------------------------------------------------

LOCKFILE <- "/build/packages-2015.tsv"
VENDOR   <- "/build/vendor"
LIB      <- "/usr/local/lib/R/site-library"

dir.create(LIB, recursive = TRUE, showWarnings = FALSE)
lock <- read.delim(LOCKFILE, stringsAsFactors = FALSE)
lock <- lock[order(lock$order), ]

msg <- function(...) { cat(sprintf(...), "\n", sep = ""); flush.console() }
sha256 <- function(f) sub(" .*$", "", system2("sha256sum", shQuote(f), stdout = TRUE))

msg("installing %d pinned packages into %s", nrow(lock), LIB)

failed <- character()
for (i in seq_len(nrow(lock))) {
  row <- lock[i, ]
  tb  <- file.path(VENDOR, sprintf("%s_%s.tar.gz", row$package, row$version))

  if (!file.exists(tb)) { failed <- c(failed, row$package); msg("  !! %-16s tarball missing", row$package); next }
  got <- sha256(tb)
  if (!identical(got, row$sha256)) {
    # A corrupt or substituted tarball is not a warning. The entire claim of
    # this project is that these exact bytes produced the 2015 numbers.
    stop(sprintf("checksum mismatch for %s %s\n  expected %s\n  got      %s",
                 row$package, row$version, row$sha256, got))
  }

  install.packages(tb, lib = LIB, repos = NULL, type = "source", INSTALL_opts = "--no-test-load")
  if (!row$package %in% rownames(installed.packages(lib.loc = LIB))) {
    failed <- c(failed, row$package)
    msg("  !! %3d/%3d %-16s %-12s FAILED", i, nrow(lock), row$package, row$version)
  } else {
    msg("  ok %3d/%3d %-16s %-12s", i, nrow(lock), row$package, row$version)
  }
}

msg("")
if (length(failed)) {
  msg("FAILED (%d): %s", length(failed), paste(failed, collapse = ", "))
  quit(status = 1)
}

# Every pinned package must load and report the pinned version. --no-test-load
# above skips the per-package load test for speed, so this is where we actually
# prove the library is coherent.
msg("verifying all %d packages load at the pinned version...", nrow(lock))
bad <- character()
for (i in seq_len(nrow(lock))) {
  p <- lock$package[i]; want <- lock$version[i]
  ok <- suppressWarnings(suppressMessages(
    requireNamespace(p, lib.loc = c(LIB, .libPaths()), quietly = TRUE)))
  if (!ok) { bad <- c(bad, sprintf("%s (will not load)", p)); next }
  got <- as.character(utils::packageVersion(p, lib.loc = c(LIB, .libPaths())))
  if (!identical(got, want)) bad <- c(bad, sprintf("%s (want %s, got %s)", p, want, got))
}
if (length(bad)) { msg("VERIFY FAILED:"); for (b in bad) msg("  %s", b); quit(status = 1) }

msg("all %d packages installed and verified at pinned versions", nrow(lock))
