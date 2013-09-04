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
  } else if(length(f) < 1){
    message("skip")
  }
  rm(f)
}


head(dat)

length(unique(dat$distid))

# Query metadata
metadata <- read.csv("../Data/sbelectionresults/WisconsinSBelectionMetaData.csv")

metadata$general <- rowSums(metadata[, 3:13], na.rm=T)
table(metadata$general)

metadata$primary <- rowSums(metadata[, 14:24], na.rm=T)
table(metadata$primary)


