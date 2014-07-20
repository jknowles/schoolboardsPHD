################################################################################
# Assemble Data from School Board Database
# Check data for errors
################################################################################

library(data.table); library(plyr)
struc <- list.dirs("../Data/sbelectionresults", recursive = FALSE)
file.exists(Sys.glob(file.path(struc[5],"*.csv")))

dat <- read.csv(Sys.glob(file.path(struc[6],"*.csv")))
dat <- dat[0, ]
names(dat) <- tolower(names(dat))
names(dat) <- gsub("\\.", "", names(dat))
#struc <- struc[-1]


for(i in 1:length(struc)){
  f <- Sys.glob(file.path(struc[i],"*.csv"))
  if(length(f) > 0){
    tmp <- read.csv(f, colClasses = "character")
    names(tmp) <- tolower(names(tmp))
    # clean up names
    names(tmp) <- gsub("\\.", "", names(tmp))
    names(tmp) <- gsub("q", "", names(tmp))
    dat <- rbind.fill(dat, tmp)
    rm(tmp)    
  } else if(length(f) < 1){
    message("skip")
  }
  rm(f)
}


rm(i, struc)

## Parse the column types
table(dat$electiontype)
dat$electiontype <- as.numeric(dat$electiontype)

table(dat$candidateid)
dat$candidateid[dat$candidateid == "Na"] <- NA
dat$candidateid <- as.numeric(dat$candidateid)
dat$candidateid[dat$candidateid == 0] <- NA

table(dat$year)
dat$year <- as.numeric(dat$year)

table(dat$distid)
dat$distid <- as.numeric(dat$distid)

dat$votes <- as.numeric(dat$votes)
dat$winner <- as.numeric(dat$winner)
dat$incumbent <- as.numeric(dat$incumbent)
dat$'repeat' <- as.numeric(dat$'repeat')
dat$minor <- as.numeric(dat$minor)
dat$raceid <- as.character(dat$raceid)
dat$areaid <- as.character(dat$areaid)
dat$districtwide <- as.numeric(dat$districtwide)

# table(dat$districtwide)

if(length(dat$distid[is.na(dat$distid)]) > 1){
  print(paste0("NAs in District IDs: ", length(dat$distid[is.na(dat$distid)])))
} else {
  print("No missing district IDs")
}


if(length(dat$Race.ID[is.na(dat$raceid)]) > 1){
  print(paste0("NAs in Race IDs: ", length(dat$Race.ID[is.na(dat$raceid)])))
} else {
  print("No missing Race IDs")
}


mysub <- dat[is.na(dat$distid),]

if(is.null(dim(mysub[!is.na(mysub)]))){
  dat <- dat[!is.na(dat$distid),]
  print(paste0(nrow(mysub), " spurious rows removed."))
  rm(mysub)
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


# candidate ID
## Recode Scatter
dat$candidateid[tolower(dat$first) == "scatter"] <- 99
print(paste0(length(dat$candidateid[is.na(dat$candidateid)]), " observations missing candidate id"))
print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$candidateid)]), collapse="|")))
print(paste0(length(dat$candidateid[dat$candidateid == 99]), 
             " observations of scatter votes"))
print(paste0(sum(dat$votes[is.na(dat$candidateid)], na.rm=TRUE), " votes cast for candidates with no ID and not scatter"))

# Candidate IDs
## Make them unique by school district
##
dat$candidateid2 <- paste(dat$distid, dat$candidateid, sep="-")
print(paste0("Candidates identified: ", length(unique(dat$candidateid2))))

print("Here are the top 10 most occurring candidates: ")
z <- table(dat$candidateid2[!grepl("-99", dat$candidateid2)])

head(z[order(-z)], 10)

print("Number of non-scatter candidates")
length(unique(dat$candidateid2[!grepl("-99", dat$candidateid2)]))

# Votes
print(paste0(length(dat$votes[dat$votes < 2]), 
             " observations with less than 2 votes"))
print(paste0(length(dat$votes[is.na(dat$votes)]), 
             " observations with NA votes"))

print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$votes)]), collapse="|")))

print(paste0(length(dat$votes[dat$votes > 20000 & !is.na(dat$votes)]), 
             " observations with greater than 50,000 votes"))

## Races
# Make unique race ID by district and year

dat$raceid2 <- paste(dat$distid, dat$year, dat$raceid, dat$electiontype, sep = "-")
length(unique(dat$raceid2))

plyr::ddply(dat, .(year), summarize, uniqueRaces = length(unique(raceid2)))

plyr::ddply(dat, .(year), summarize, 
            racesperDistrict = length(unique(raceid2))/ length(unique(distid)))

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

print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$winner)]), collapse="|")))

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

print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$incumbent)]), collapse="|")))


# Repeaters
table(dat$"repeat")

print(paste0(length(dat$"repeat"[dat$"repeat" != 0 & dat$"repeat" != 1 & 
                                    !is.na(dat$"repeat")]), 
             " observations with invalid repeater codes."))

print(paste0(dat$distid[dat$"repeat" != 0 & dat$"repeat" != 1 & 
                          !is.na(dat$"repeat")], 
             " district id with invalid repeater codes."))


print(paste0(length(dat$"repeat"[is.na(dat$"repeat")]), 
             " observations with missing repeater codes."))


print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$"repeat")]), collapse="|")))

# Minor candidates
table(dat$minor)

print(paste0(length(dat$minor[dat$minor != 0 & dat$minor != 1 & 
                                    !is.na(dat$minor)]), 
             " observations with invalid minor codes."))

print(paste0(dat$distid[dat$minor != 0 & dat$minor != 1 & 
                          !is.na(dat$minor)], 
             " district id with invalid minor codes."))


print(paste0(length(dat$minor[is.na(dat$minor)]), 
             " observations with missing minor codes."))

##

print(paste0(length(dat$raceid[is.na(dat$raceid)]), 
             " observations with invalid minor codes."))


print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$raceid)]), collapse="|")))

print(paste0("Check districts: ", paste0(unique(dat$distid[is.na(dat$districtwide)]), collapse="|")))

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
print(paste0("Records without some missing data: ", nrow(na.omit(dat))))
print(paste0(round(1-nrow(na.omit(dat))/ nrow(dat),2) *100, "% records with some missigness"))

dimNA(dat)

###########################
# Check multiple variable combinations

## Same Race and area ID
length(dat$distid[dat$raceid != dat$areaid])

## At least one winner per race id
length(unique(dat$raceid2))

winsPer <- as.data.table(dat[dat$candidateid!= 99,])[, list(winsPer = sum(winner)), 
                                     by = c("raceid2")]

check1 <- winsPer$raceid2[winsPer$winsPer == 0]

print(paste0(length(check1), " races with no winners in a race."))

library(stringr)
extr <- str_split(check1, "-")
distid <- as.character(lapply(extr, "[[", 1))

print(paste0("Check districts: ", paste0(unique(distid), collapse="|")))

## Incumbent but not repeat

length(dat$distid[dat$incumbent == 1 & dat$'repeat' == 0])
length(dat$distid[dat$incumbent == 0 & dat$'repeat' == 1])

dat[dat$incumbent == 1 & dat$'repeat' == 0,]

dat$'repeat'[dat$incumbent > 0] <- 1
length(dat$distid[dat$incumbent == 1 & dat$'repeat' == 0])

## Enforce business rule that says that minor candidates are those with fewer 
## than 20 votes

## Fewer than 20 votes and not minor
length(dat$distid[dat$votes < 20 & dat$minor == 0])
dat$minor[dat$votes < 20 & dat$candidateid != 99] <- 1


length(dat$distid[dat$votes > 20 & dat$minor > 0 & dat$candidateid != 99])
dat$minor[dat$votes > 20 & dat$candidateid != 99] <- 0


## All scatter are minor candidates

length(dat$distid[dat$candidateid == 99 & dat$minor == 0])
dat[dat$candidateid == 99 & dat$minor == 0, ]
dat$minor[dat$candidateid == 99] <- 1

rm(winsPer, check1, distid, extr, z)

################################################################################
# Assemble candidate quality measure
# Meaure 1 = number of elections run
# Measure 2 = Measure 1 + number of times incumbent
#
################################################################################

cand <- as.data.table(dat[dat$candidateid != 99,])[, list(nraces = .N, 
                                  nwins = sum(winner), 
                                  ninc = sum(incumbent)), 
                           by = c("candidateid2")]

races <- as.data.table(dat)[, list(ncand = .N,
                                   nrealcand = length(winner[candidateid!=99]),
                                   nwins = sum(winner), 
                                   ninc = sum(incumbent), 
                                   nminor = sum(minor), 
                                   votes = sum(votes), 
                                   districtwide = max(districtwide)), 
                            by = c("raceid2")]

################################################################################
# Check for extreme values
# Within districts
################################################################################

## By district year
## Minimax

# As.double allows data.table to proceed in cases of Inf
check_dat <- as.data.table(dat)[, list(totalvotes = as.double(sum(votes, na.rm=T)), 
                                       minvotes = as.double(min(votes, na.rm=T)),
                                       maxvotes = as.double(max(votes, na.rm=T)),
                                       candidates = .N, 
                                       winners = as.double(sum(winner, na.rm=T)),
                                       incumbents = as.double(sum(incumbent, na.rm=T)), 
                                       minor = as.double(sum(minor, na.rm=TRUE))),
                                      by = c("distid", "year", "electiontype")]

# Only focus on general elections for now
check_dat <- as.data.frame(check_dat[check_dat$electiontype==1,])
check_dat$electiontype <- NULL

#
check_dat$totalvotes[!is.finite(check_dat$totalvotes)] <- 0
check_dat$minvotes[!is.finite(check_dat$minvotes)] <- 0
check_dat$maxvotes[!is.finite(check_dat$maxvotes)] <- 0
summary(check_dat$maxvotes/check_dat$totalvotes)

# reshape wide by district to check within district consistency

check_dat_ts <- reshape(check_dat, idvar="distid", drop=c("minvotes", "maxvotes"),
                        v.names=c("totalvotes"),
                        timevar="year", direction="wide")

check_dat_ts <- check_dat_ts[!is.na(check_dat_ts$distid),]

check_dat_ts$totalvotes.max <- apply(check_dat_ts[ , 2:15], 1, max, na.rm=T)
check_dat_ts$totalvotes.min <- apply(check_dat_ts[ , 2:15], 1, min, na.rm=T)
check_dat_ts$totalvotes.med <- apply(check_dat_ts[ , 2:15], 1, median, na.rm=T)

# check for large within district swings

check_dat_ts$consist1 <- (check_dat_ts$totalvotes.max - check_dat_ts$totalvotes.min) / check_dat_ts$totalvotes.med 
check_dat_ts$consist1[is.na(check_dat_ts$consist1)] <- 0

check_dat_ts$consist2 <- (check_dat_ts$totalvotes.max) / check_dat_ts$totalvotes.med 
check_dat_ts$consist2[is.na(check_dat_ts$consist2)] <- 0

check_dat_ts$consist3 <- (check_dat_ts$totalvotes.min) / check_dat_ts$totalvotes.med 
check_dat_ts$consist3[is.na(check_dat_ts$consist3)] <- 0

check_dat_ts$flag <- 0
check_dat_ts$flag[check_dat_ts$consist1 > 3 & check_dat_ts$consist2 >3] <- 1
check_dat_ts$flag[check_dat_ts$consist1 > 3 & check_dat_ts$consist3 < 0.2] <- 1
check_dat_ts$flag[check_dat_ts$consist2 > 3 & check_dat_ts$consist3 < 0.2] <- 1

# View(check_dat_ts[check_dat_ts$consist1 > 3,])
# View(check_dat_ts[check_dat_ts$consist2 > 3,])
# View(check_dat_ts[check_dat_ts$consist3 < 0.2,])

################################################################################
# Output checks

print(paste0("Total deviations: ", nrow(check_dat_ts[check_dat_ts$flag >0,])))

print(paste0("Check districts: ", paste0(unique(check_dat_ts$distid[check_dat_ts$flag >0]), collapse="|")))

#
#




################################################################################
# Build checks between metadata and data
# Use data to validate metadata 
################################################################################

# # Query metadata
# metadata <- read.csv("../Data/sbelectionresults/WisconsinSBelectionMetaData.csv")
# 
# "%notin%" <- function(x, y) x[!x %in% y] #--  x without y
# 
# incomp <- unique(dat$distid) %notin% unique(metadata$distid)
# 
# print(paste0("Districts without metadata: ", length(incomp)))
# print(paste0("Districts with metadata: ", nrow(metadata) - length(incomp)))
# print(paste0("Districts without metadata: ", paste0(incomp, collapse=",")))
# 
# metadata$general <- rowSums(metadata[, 3:13], na.rm=T)
# table(metadata$general)
# 
# metadata$primary <- rowSums(metadata[, 14:24], na.rm=T)
# table(metadata$primary)
# 
# dat$repeater <- dat$"repeat."
# dat$"repeat." <- NULL

rm(check_dat, check_dat_ts)

dat$repeater <- dat$'repeat'
dat$'repeat' <- NULL


tmp <- str_split(races$raceid2, "-")
races$distid <- as.character(lapply(tmp, "[[", 1))
races$year <- as.character(lapply(tmp, "[[", 2))
races$raceid <- as.character(lapply(tmp, "[[", 3))
races$electiontype <- as.character(lapply(tmp, "[[", 4))