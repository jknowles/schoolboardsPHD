# ---------------------------------------------------------------------------
# School Boards and the Democratic Promise -- reproduction build
#
#   make image      build the R 3.1.2 analysis container
#   make tex-image  build the LaTeX container
#   make chapters   knit all five .Rnw -> .tex (+ figures)
#   make chapter C=policy      knit one chapter
#   make pdf        typeset dissertation.pdf
#   make verify     compare everything against reference/2015-build/
#   make all        chapters + pdf + verify
#   make shell      interactive R 3.1.2 shell in the container
#   make audit      prove no 2015 source file has been modified
#
# The repository is mounted one level below /work/dissertation so that
# data/dataAssemble.R's "../Data/sbelectionresults" resolves to the vendored
# CSVs. entrypoint.sh wires up that symlink plus the two other compatibility
# shims. Nothing in the 2015 source is edited to make this work.
# ---------------------------------------------------------------------------

R_IMAGE   := schoolboards-phd:r312
TEX_IMAGE := schoolboards-phd:tex
MOUNT     := $(CURDIR):/work/dissertation/MasterText

# LC_COLLATE is a genuine reproduction variable: it changes the order in which
# district CSVs are concatenated, which changes the RNG stream chapter 4 draws
# from. Default matches the container. Override to test: make chapters LOCALE=C.UTF-8
LOCALE ?= en_US.UTF-8

DOCKER_RUN := docker run --rm -v "$(MOUNT)" -e LC_ALL=$(LOCALE) -e LC_COLLATE=$(LOCALE) \
                  -u $(shell id -u):$(shell id -g)

C ?=

.PHONY: all image tex-image chapters chapter pdf verify verify-tex shell audit pins clean-outputs help

help:
	@sed -n '3,17p' $(MAKEFILE_LIST) | sed 's/^# \?//'

# --- environment ------------------------------------------------------------
image:
	cp inst/pins/packages-2015.tsv docker/packages-2015.tsv
	docker build -f docker/Dockerfile.r312 -t $(R_IMAGE) docker/
	@echo
	@docker run --rm $(R_IMAGE) R --version | head -1

tex-image:
	docker build -f docker/Dockerfile.tex -t $(TEX_IMAGE) docker/

pins:
	Rscript docker/fetch-tarballs.R

# --- build ------------------------------------------------------------------
chapters:
	$(DOCKER_RUN) $(R_IMAGE) Rscript scripts/build_chapters.R

chapter:
	@test -n "$(C)" || { echo "usage: make chapter C=<aboutwisconsin|candidacy|voterturnout|policy|walker>"; exit 2; }
	$(DOCKER_RUN) $(R_IMAGE) Rscript scripts/build_chapters.R $(C)

# BIBINPUTS/BSTINPUTS replicate what build.R exported; the bibliography lives in
# bib/ and the modified chicago.bst in includes/, neither on the default path.
# The trailing colons matter -- without them kpathsea REPLACES the default search
# path instead of prepending to it, and bibtex silently produces no .bbl, which
# costs you the entire references chapter (23 pages) and 512 undefined citations.
#
# The latin1 injection is not a preference. chapters/voterturnout/voterturnout.tex
# line 194 contains three orphaned 0xE2 bytes -- a UTF-8 en-dash whose
# continuation bytes were replaced by the literal text "<U+0080><U+0093>"
# somewhere in 2015. includes/preamble.tex loads fontenc but never inputenc, so
# 2015 LaTeX passed those bytes through untouched and the deposited PDF renders
# the same garbage ("group<A-circumflex>...s"). Modern LaTeX defaults to UTF-8
# and hard-errors instead. Requesting latin1 on the command line reproduces the
# 2015 interpretation byte for byte, without editing a 2015 source file.
# -jobname keeps the aux/bbl names as "dissertation" despite the \input.
TEXCMD = \RequirePackage[latin1]{inputenc}\input{dissertation}

pdf:
	$(DOCKER_RUN) -e BIBINPUTS=/work/dissertation/MasterText/bib: \
	              -e BSTINPUTS=/work/dissertation/MasterText/includes: \
	              $(TEX_IMAGE) sh -c '\
	  set -e; \
	  pdflatex -interaction=nonstopmode -jobname=dissertation "$(TEXCMD)" >/dev/null 2>&1 || true; \
	  bibtex dissertation; \
	  pdflatex -interaction=nonstopmode -jobname=dissertation "$(TEXCMD)" >/dev/null 2>&1 || true; \
	  pdflatex -interaction=nonstopmode -jobname=dissertation "$(TEXCMD)" >/dev/null 2>&1 || true; \
	  pdflatex -interaction=nonstopmode -jobname=dissertation "$(TEXCMD)" >/dev/null 2>&1 || true'
	@test -f dissertation.pdf && pdfinfo dissertation.pdf | grep -E "^Pages"
	@echo "undefined citations: $$(grep -ac 'Citation .* undefined' dissertation.log || echo 0)"
	@echo "undefined references: $$(grep -ac 'Reference .* undefined' dissertation.log || echo 0)"

# --- verification -----------------------------------------------------------
verify:
	./scripts/verify.sh

verify-tex:
	./scripts/verify.sh --tex-only

# The load-bearing claim of the resurrection branch: no 2015 source file was
# modified or deleted to make any of this work.
audit:
	@echo "2015 source files modified or deleted since v2015-deposit:"
	@git diff --diff-filter=MD --name-only v2015-deposit..HEAD \
	   | grep -E '\.(R|Rnw|tex|bib|bst)$$' \
	   | sed 's/^/  /' || true
	@if git diff --diff-filter=MD --name-only v2015-deposit..HEAD \
	     | grep -qE '\.(R|Rnw|tex|bib|bst)$$'; then \
	   echo "  ^^ AUDIT FAILED"; exit 1; \
	 else echo "  none -- clean"; fi

all: chapters pdf verify

shell:
	$(DOCKER_RUN) -it $(R_IMAGE) R

# Removes build products only. Never touches reference/ or vendor/.
clean-outputs:
	rm -f dissertation.aux dissertation.bbl dissertation.blg dissertation.log \
	      dissertation.out dissertation.toc dissertation.lof dissertation.lot \
	      dissertation.idx chapters/*/*.aux
