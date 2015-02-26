# Do Sweave
library(knitr)
cleanUp <- function(){
  rm(list=ls())
  source("../../R/thesis_functions.R")
  detachPkgs()
  library(knitr)
}
setwd("chapters")

setwd("aboutwisconsin")
knit("aboutwisconsin.Rnw", envir=new.env())
cleanUp()
setwd("../")
setwd("candidacy")
knit("candidacy.Rnw", envir=new.env())
cleanUp()
setwd("../")
setwd("voterturnout")
knit("voterturnout.Rnw", envir=new.env())
cleanUp()
setwd("../")
setwd("policy")
knit("policy.Rnw", envir=new.env())
cleanUp()
setwd("../")
setwd("walker")
knit("walker.Rnw", envir=new.env())
rm(list=ls())

setwd("../..")


# Set texenv
BIBINPUTS=paste0(getwd(),"/","bib") #Path to tex file in Windows
BSTINPUTS=paste0(getwd(),"/","includes")
Sys.setenv(BIBINPUTS=BIBINPUTS, BSTINPUTS=BSTINPUTS)

# Build PDF
system("pdflatex dissertation")
system("bibtex dissertation")
system("pdflatex dissertation")
system("pdflatex dissertation")
system("pdflatex dissertation")

cleantex <- function(mydoc,keepPDF){
  a <- list.files(pattern=mydoc)
  save <- a[grep(".tex",a)]
  if(keepPDF==TRUE){  
    save <- append(save,a[grep(".pdf",a)])
  }
  else if(keepPDF==FALSE){
    save <- a[grep(".tex",a)]
  }
  rm <- setdiff(a,save)
  file.remove(rm)
}

cleantex("dissertation", keepPDF=TRUE)

# stackoverflow.com/questions/7512897/how-to-turn-a-latex-sweave-file-rnw-into-html
# Need imagemagick
# choco install imagemagick.app
# SWconvurl <- "http://biostat.mc.vanderbilt.edu/wiki/pub/Main/SweaveConvert/sweave2html"
# download.file(SWconvurl,dest="bin/sweave2html")
#  Sys.chmod(c("tth_exe","sweave2html"),mode="0755") ## ???
# system("bin/sweave2html chapters/aboutwisconsin/aboutwisconsin.tex")
# system("tth -a -d /chapters/aboutwisconsin.tex")
## Make word docs
# pandoc -s math.tex -o example30.docx
# # http://tex.stackexchange.com/questions/186606/partial-compile-latex-and-bibtex-for-pandoc 
# setwd("chapters")
# setwd("aboutwisconsin")
# system("pandoc -s aboutwisconsin.tex -o aboutwisconsin.docx") 
# system("pandoc -o word.docx --bibliography ../../bib/candidcay.bib --csl ../../bib/apsr.csl original.tex")