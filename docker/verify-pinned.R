#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Prove the installed library matches the lockfile.
#
# Kept in its own Dockerfile layer, after the install, so that changing this
# check does not invalidate the 8-minute package build above it.
#
# Note on comparing versions: R's packageVersion() returns a package_version
# object whose character form normalises "-" to ".", so the CRAN version
# "1.4-3" reads back as "1.4.3". Comparing raw strings therefore rejects every
# correctly-installed package that uses a dash -- 25 of the 99 here. Both sides
# are coerced through package_version() so the comparison is on versions rather
# than on spelling.
# ---------------------------------------------------------------------------
LOCKFILE <- "/build/packages-2015.tsv"
LIB      <- "/usr/local/lib/R/site-library"

lock <- read.delim(LOCKFILE, stringsAsFactors = FALSE)
msg  <- function(...) { cat(sprintf(...), "\n", sep = ""); flush.console() }

msg("verifying %d packages in %s", nrow(lock), LIB)
bad <- character()
for (i in seq_len(nrow(lock))) {
  p <- lock$package[i]; want <- lock$version[i]
  ok <- suppressWarnings(suppressMessages(
    requireNamespace(p, lib.loc = c(LIB, .libPaths()), quietly = TRUE)))
  if (!ok) { bad <- c(bad, sprintf("%-14s will not load", p)); next }
  got <- utils::packageVersion(p, lib.loc = c(LIB, .libPaths()))
  if (got != package_version(want))
    bad <- c(bad, sprintf("%-14s want %s, got %s", p, want, as.character(got)))
}

if (length(bad)) {
  msg("VERIFY FAILED (%d):", length(bad))
  for (b in bad) msg("  %s", b)
  quit(status = 1)
}
msg("all %d packages load at the pinned version", nrow(lock))
