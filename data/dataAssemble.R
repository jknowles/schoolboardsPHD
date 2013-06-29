# Assemble datasets for analysis in chapters
# Scrape school board election sub-data

struc <- list.dirs("../Data/sbelectionresults")

list.files(struc[2])

file.exists(Sys.glob(file.path(struc[5],"*.csv")))

dat <- read.csv(Sys.glob(file.path(struc[6],"*.csv")))
dat <- dat[0, ]


struc2 <- struc[-1]
struc2 <- struc2[-1]
for(i in 1:length(struc2)){
  f <- Sys.glob(file.path(struc2[i],"*.csv"))
  if(length(f) > 0){
    tmp <- read.csv(f)
    dat <- rbind(dat, tmp)
    rm(tmp)    
  } else{
    message("skip")
  }

}
head(dat)

length(unique(dat$distid))
