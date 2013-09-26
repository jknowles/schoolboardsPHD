################################################################################
# Assemble Data from School Board Database
# Check data for errors
################################################################################

struc <- list.dirs("../Data/sbelectionresults")
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


rm(i, struc,struc2)


if(length(dat$distid[is.na(dat$distid)]) > 1){
  print(paste0("NAs in District IDs: ", length(dat$distid[is.na(dat$distid)])))
} else {
  print("No missing district IDs")
}


mysub <- dat[is.na(dat$distid),]

if(is.null(dim(mysub[!is.na(mysub)]))){
  dat <- dat[!is.na(dat$distid),]
  rm(mysub)
  print("Spurious rows removed.")
} else {
  print("Check NAs in mysub dataframe")
}

# Check for invalid fields

# year
print(paste0(length(dat$year[is.na(dat$year)]), " observations missing years"))
print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$year)]), collapse="|")))
print(paste0(length(dat$year[dat$year > 2012]), " observations with year > 2012"))
print(paste0(length(dat$year[dat$year < 2002]), " observations with year < 2002"))

# Election type
print(paste0(length(dat$electiontype[is.na(dat$electiontype)]), " observations missing electiontype"))
print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$electiontype)]), collapse="|")))
print(paste0(length(dat$electiontype[dat$electiontype > 3 | dat$electiontype < 1]), 
             " observations with improper election type"))

# Candidate IDs
## Make them unique by school district
##
dat$candidateid2 <- paste(dat$distid, dat$candidateid, sep="-")
print(paste0("Candidates identified: ", length(unique(dat$candidateid2))))

z <- table(as.vector(dat$candidateid2))
names(z)[z == max(z)]

print("Here are the top 10 most occurring candidates: ")
head(z[order(-z)], 10)

# Votes
print(paste0(length(dat$votes[dat$votes < 2]), 
             " observations with less than 2 votes"))
print(paste0(length(dat$votes[is.na(dat$votes)]), 
             " observations with NA votes"))
print(paste0(length(dat$votes[dat$votes > 50000 & !is.na(dat$votes)]), 
             " observations with greater than 50,000 votes"))

# Winners
table(dat$winner)

print(paste0(length(dat$winner[dat$winner != 0 & dat$winner != 1 & 
                                 !is.na(dat$winner)]), 
             " observations with invalid winner codes."))

print(paste0(dat$distid[dat$winner != 0 & dat$winner != 1 & 
                                 !is.na(dat$winner)], 
             " district id with invalid winner codes."))


print(paste0(length(dat$winner[is.na(dat$winner)]), 
             " observations with missing winner codes."))

# Incumbents

table(dat$incumbent)

print(paste0(length(dat$incumbent[dat$incumbent != 0 & dat$incumbent != 1 & 
                                 !is.na(dat$incumbent)]), 
             " observations with invalid incumbent codes."))

print(paste0(dat$distid[dat$incumbent != 0 & dat$incumbent != 1 & 
                          !is.na(dat$incumbent)], 
             " district id with invalid incumbent codes."))


print(paste0(length(dat$incumbent[is.na(dat$incumbent)]), 
             " observations with missing incumbent codes."))


# Repeaters
table(dat$"repeat.")

print(paste0(length(dat$"repeat."[dat$"repeat." != 0 & dat$"repeat." != 1 & 
                                    !is.na(dat$"repeat.")]), 
             " observations with invalid repeater codes."))

print(paste0(dat$distid[dat$"repeat." != 0 & dat$"repeat." != 1 & 
                          !is.na(dat$"repeat.")], 
             " district id with invalid repeater codes."))


print(paste0(length(dat$"repeat."[is.na(dat$"repeat.")]), 
             " observations with missing repeater codes."))


# Minor candidates
table(dat$minor)

print(paste0(length(dat$minor[dat$minor != 0 & dat$minor != 1 & 
                                    !is.na(dat$minor)]), 
             " observations with invalid repeater codes."))

print(paste0(dat$distid[dat$minor != 0 & dat$minor != 1 & 
                          !is.na(dat$minor)], 
             " district id with invalid repeater codes."))


print(paste0(length(dat$minor[is.na(dat$minor)]), 
             " observations with missing repeater codes."))


# Notes

dat$notes[is.na(dat$notes)] <- ""

#################
# Final output
#################

dimNA <- function(df){
  dims <- dim(df)[1] * dim(df)[2]
  propNA <- apply(df, 2, vecNAsearch)
  countNA <- propNA * dim(df)[1]
  total <- sum(countNA)
  totalP <- total / dims
  return(list("TotalCells" = dims, "MissingbyColumn" = countNA, 
              "TotalMissing" = total, "TotalProportionMissing" = totalP))
  
}

vecNAsearch <- function(x){
  l <- length(x)
  lNA <- length(x[is.na(x)])
  return(lNA / l)
}

print(paste0("Total records: ", nrow(dat)))
print(paste0("Records with some missing data: ", nrow(na.omit(dat))))
print(paste0(round(nrow(na.omit(dat))/ nrow(dat),2) *100, "% records with some missigness"))


dimNA(dat)

################################################################################
# Build checks between metadata and data
# Use data to validate metadata 
################################################################################

# Query metadata
metadata <- read.csv("../Data/sbelectionresults/WisconsinSBelectionMetaData.csv")

"%notin%" <- function(x, y) x[!x %in% y] #--  x without y

incomp <- unique(dat$distid) %notin% unique(metadata$distid)

print(paste0("Districts without metadata: ", length(incomp)))
print(paste0("Districts with metadata: ", nrow(metadata) - length(incomp)))
print(paste0("Districts without metadata: ", paste0(incomp, collapse=",")))

metadata$general <- rowSums(metadata[, 3:13], na.rm=T)
table(metadata$general)

metadata$primary <- rowSums(metadata[, 14:24], na.rm=T)
table(metadata$primary)

dat$repeater <- dat$"repeat."
dat$"repeat." <- NULL
