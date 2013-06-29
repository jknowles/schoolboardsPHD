# Do Sweave
library(knitr)

setwd("chapters/aboutwisconsin")
knit("aboutwisconsin.Rnw")
setwd("../..")


# Build PDF

system("pdflatex dissertation")
system("bibtex dissertation")
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

cleantex("dissertation",keepPDF=TRUE)

