# Do Sweave
library(knitr)

# libraries
# library(eeptools)
# library(ROCR)
# library(coefplot)
# library(eeptools); library(gridExtra)
# library(ROCR); library(lme4)
# library(arm)
# library(coefplot)
# library(scales); 
# library(stargazer)

setwd("chapters/aboutwisconsin")
knit("aboutwisconsin.Rnw", envir=new.env())
rm(list=ls())
setwd("../candidacy")
knit("candidacy.Rnw", envir=new.env())
rm(list=ls())
setwd("../voterturnout")
knit("voterturnout.Rnw", envir=new.env())
rm(list=ls())
setwd("../policy")
knit("policy.Rnw", envir=new.env())
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