#Set Environment Variables
TEXINPUTS="C:\\Users\\Jared\\Dropbox\\
           Dissertation\\MasterText"

Sys.setenv(TEXINPUTS="C:\\Users\\Jared\\Dropbox\\Dissertation\\MasterText",
           BIBINPUTS=paste(TEXINPUTS,"\\bib",sep=""),BSTINPUTS=paste(TEXINPUTS,"\\bib",sep=""))
