#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Knit the five analysis chapters, mirroring build.R exactly.
#
# build.R is the 2015 driver and is left untouched as historical record. This
# is its container-side twin: same chapters, same order, same working-directory
# choreography, same cleanUp() between chapters. Where build.R also shells out
# to pdflatex, this stops after knitting -- typesetting is a separate step on a
# modern TeX Live, because the acceptance test for the reproduction is that the
# generated .tex are byte-identical, which is a pure R question.
#
# The working-directory dance is not incidental and must not be "tidied". Each
# .Rnw setup chunk calls setwd("../../"), but knitr restores the working
# directory after every chunk. So the setup chunk runs at the repository root
# -- which is why it can say source("data/dataAssemble.R") -- while every later
# chunk runs in the chapter directory, which is why those say
# load("../../data/cache/springElectionVotes.rda") and
# fig.path="../../phd_figs/". Knitting from anywhere else silently breaks both
# halves.
#
# Usage:
#   Rscript scripts/build_chapters.R              # all five, in build.R order
#   Rscript scripts/build_chapters.R policy       # one chapter
#
# Building chapters individually is safe, and on the modernize branch it is how
# `make chapters` works. Every chapter is insulated from cross-chapter state:
# chapters 2 (aboutwisconsin), 5 (walker) and 6 (policy) consume no randomness
# at all, and 3 (candidacy) and 4 (voterturnout) both call set.seed(51315)
# before their first stochastic call.
#
# It is also more reliable. build.R ran all five in one session with
# detachPkgs() in between, which force-unloads every attached package; when that
# leaves a namespace half-torn-down a later chapter fails. Chapter 5 was seen
# dying in plyr's ldply for exactly that reason while building cleanly alone.
# ---------------------------------------------------------------------------

# chapter directory -> .Rnw basename, in build.R's order
CHAPTERS <- c(aboutwisconsin = "aboutwisconsin.Rnw",
              candidacy      = "candidacy.Rnw",
              voterturnout   = "voterturnout.Rnw",
              policy         = "policy.Rnw",
              walker         = "walker.Rnw")

args <- commandArgs(trailingOnly = TRUE)
want <- if (length(args)) args else names(CHAPTERS)
unknown <- setdiff(want, names(CHAPTERS))
if (length(unknown)) stop("unknown chapter(s): ", paste(unknown, collapse = ", "),
                          "\nvalid: ", paste(names(CHAPTERS), collapse = ", "))
want <- names(CHAPTERS)[names(CHAPTERS) %in% want]   # always build.R's order

ROOT <- normalizePath(getwd())
if (!file.exists(file.path(ROOT, "dissertation.tex")))
  stop("run this from the repository root (no dissertation.tex here): ", ROOT)

library(knitr)

# build.R's cleanUp(), reproduced. rm(list=ls()) inside a function clears only
# that function's frame, so it is effectively a no-op -- kept anyway, because
# the object here is to reproduce the 2015 driver, not to improve it.
cleanUp <- function() {
  rm(list = ls())
  source("../../R/thesis_functions.R")
  detachPkgs()
  library(knitr)
}

started <- Sys.time()
cat(sprintf("R %s | LC_COLLATE=%s | knitr %s\n",
            getRversion(), Sys.getlocale("LC_COLLATE"),
            as.character(packageVersion("knitr"))))
cat(sprintf("knitting %d chapter(s): %s\n\n", length(want), paste(want, collapse = ", ")))

failed <- character()
for (ch in want) {
  rnw <- CHAPTERS[[ch]]
  cat(sprintf("=== %s ===\n", ch)); flush.console()
  t0 <- Sys.time()

  setwd(file.path(ROOT, "chapters", ch))
  ok <- tryCatch({ knit(rnw, envir = new.env()); TRUE },
                 error = function(e) { cat("  ERROR: ", conditionMessage(e), "\n", sep = ""); FALSE })

  # build.R calls cleanUp() after every chapter except the last, where it does a
  # bare rm(list=ls()) instead. Immaterial, but mirrored.
  if (ok) {
    if (ch == tail(names(CHAPTERS), 1)) rm(list = ls()[!ls() %in%
        c("CHAPTERS","want","ROOT","cleanUp","failed","ch","rnw","t0","started","ok")])
    else cleanUp()
  }
  setwd(ROOT)

  if (!ok) failed <- c(failed, ch)
  else cat(sprintf("  done in %.1f min -> chapters/%s/%s\n\n",
                   as.numeric(difftime(Sys.time(), t0, units = "mins")), ch, sub("\\.Rnw$", ".tex", rnw)))
  flush.console()
}

dir.create("reference", showWarnings = FALSE)
writeLines(capture.output(sessionInfo()), "reference/sessionInfo-rebuild.txt")

cat(sprintf("total %.1f min\n", as.numeric(difftime(Sys.time(), started, units = "mins"))))
cat("sessionInfo written to reference/sessionInfo-rebuild.txt\n")
if (length(failed)) { cat("FAILED: ", paste(failed, collapse = ", "), "\n", sep = ""); quit(status = 1) }
if (length(want) > 1) cat("all requested chapters knitted\n")
