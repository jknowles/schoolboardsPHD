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
    tmp <- read.csv(f)
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


rm(i, struc,struc2)


if(length(dat$distid[is.na(dat$distid)]) > 1){
  print(paste0("NAs in District IDs: ", length(dat$distid[is.na(dat$distid)])))
} else {
  print("No missing district IDs")
}


if(length(dat$Race.ID[is.na(dat$Race.ID)]) > 1){
  print(paste0("NAs in Race IDs: ", length(dat$Race.ID[is.na(dat$Race.ID)])))
} else {
  print("No missing Race IDs")
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

## Races

names(dat)

# Make unique race ID by district and year

dat$raceID <- paste(dat$distid, dat$year, dat$Race.ID, sep = "-")
length(unique(dat$raceID))

plyr::ddply(dat, .(year), summarize, uniqueRaces = length(unique(raceID)))

plyr::ddply(dat, .(year), summarize, 
            racesperDistrict = length(unique(raceID))/ length(unique(distid)))


# 
# plyr::ddply(dat, .(year, distid), summarize, 
#             candidatesPerRace = length(unique(raceID))/ length(unique(candidateid2)))


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
             " observations with invalid minor codes."))

print(paste0(dat$distid[dat$minor != 0 & dat$minor != 1 & 
                          !is.na(dat$minor)], 
             " district id with invalid minor codes."))


print(paste0(length(dat$minor[is.na(dat$minor)]), 
             " observations with missing minor codes."))


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
# Assemble candidate quality measure
# Meaure 1 = number of elections run
# Measure 2 = Measure 1 + number of times incumbent
#
################################################################################


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

#
#
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

rm(check_dat, check_dat_ts)

################################################################################
## Read in CSV Files of voter turnout
## 
################################################################################


struc <- list.files("../Data/Raw Files/Election Data/VoterCounts", 
                    full.names=TRUE)

struc <- struc[grep(".csv", struc)]

for(i in 1:length(struc)){
  eval(parse(text=paste0("dat",i,"<- read.csv(file=struc[",i,"])")))
}

rm(i,struc)

names(dat1) <- c("doacode", "muni", "split", "county", "Census2000", 
                 "PopEstimate2009", "num_change", "per_change", 
                 "vap2000", "vap2009")
vap2009 <- dat1
rm(dat1)

dat2 <- dat2[, c(1:8,12,13)]
names(dat2) <- c("doacode", "muni", "split", "county", "Census2000", 
                 "PopEstimate2009", "num_change", "per_change", 
                 "vap2000", "vap2010")
vap2010 <- dat2
rm(dat2)

names(dat3) <- c("doacode", "muni", "split", "county", "PopEstimate2011", 
                 "Census2010", "num_change", "per_change", 
                 "vap2011", "vap2010_census")
vap2011 <- dat3
rm(dat3)


names(dat4) <- c("doacode", "muni", "split", "county", "PopEstimate2012", 
                 "Census2010", "num_change", "per_change", 
                 "vap2012", "vap2010_census")
vap2012 <- dat4
rm(dat4)

names(dat5) <- c("doacode", names(dat5)[2:length(names(dat5))])

vap2000_08 <- dat5
rm(dat5)

gc()

# Reshape vap2000_08 long

names(vap2000_08)[7:17] <- c("vap.1993", "vap.1999", "vap.2000", "vap.2001", 
                             "vap.2002", "vap.2003", "vap.2004", "vap.2005", 
                             "vap.2006", "vap.2007", "vap.2008")

vNames <- names(vap2000_08)[7:17]

vap2000_08 <- vap2000_08[!duplicated(vap2000_08$doacode),]

vaplong <- reshape(vap2000_08, idvar = c("doacode", "mcd_type", "municipality", "county_name"), 
                   varying=vNames, direction="long", sep=".")


row.names(vaplong) <- 1:nrow(vaplong)
vaplong$split <- ""
vaplong$LastCensusPop <- NA
vaplong$LastCensusVAP <- NA
vaplong$LastCensusYear <- NA
vaplong$year <- vaplong$time
vaplong$time <- NULL
vaplong$PopEstimate <- NA

vaplong <- vaplong[, c('doacode', 'mcd_type', 'municipality', 'split','county_name', 
                       'change_type', 'change_date', 'year', 'vap','LastCensusPop',
                       'LastCensusVAP', 'LastCensusYear', "PopEstimate")]

# Split the 09-12 muni names into muni name and muni type
# reformat the data so it can be rbinded onto the vaplong dataframe

vap2009$mcd_type <- substr(vap2009$muni, 1,1)
vap2009$mcd_type <- toupper(vap2009$mcd_type)
vap2009$year <- 2009
vap2009$PopEstimate <- vap2009$PopEstimate2009
vap2009$PopEstimate2009 <- NULL
vap2009$LastCensusPop <- vap2009$Census2000
vap2009$Census2000 <- NULL
vap2009$LastCensusVAP <- vap2009$vap2000
vap2009$LastCensusYear <- 2000
vap2009$vap2000 <- NULL
vap2009$vap <- vap2009$vap2009
vap2009$vap2009 <- NULL
vap2009$per_change <- NULL
vap2009$num_change <- NULL
vap2009$change_type <- ""
vap2009$change_date <- ""


vap2009 <- vap2009[, c("doacode", "mcd_type", "muni", 'split',"county", "change_type", 
                       "change_date", "year", "vap", "LastCensusPop", 
                       "LastCensusVAP", "LastCensusYear", "PopEstimate")]

names(vap2009) <- names(vaplong)

vap2009$municipality <- as.character(vap2009$municipality)
vap2009$municipality <- substr(vap2009$municipality, 2, nchar(vap2009$municipality))

vaplong <- rbind(vaplong, vap2009)

rm(vap2009)

###########################
# 2010

vap2010$mcd_type <- substr(vap2010$muni, 1,1)
vap2010$mcd_type <- toupper(vap2010$mcd_type)
vap2010$year <- 2010
vap2010$PopEstimate <- vap2010$PopEstimate2009
vap2010$PopEstimate2009 <- NULL
vap2010$LastCensusPop <- vap2010$Census2000
vap2010$Census2000 <- NULL
vap2010$LastCensusVAP <- vap2010$vap2000
vap2010$LastCensusYear <- 2000
vap2010$vap2000 <- NULL
vap2010$vap <- vap2010$vap2010
vap2010$vap2010 <- NULL
vap2010$per_change <- NULL
vap2010$num_change <- NULL
vap2010$change_type <- ""
vap2010$change_date <- ""


vap2010 <- vap2010[, c("doacode", "mcd_type", "muni", 'split',"county", "change_type", 
                       "change_date", "year", "vap", "LastCensusPop", 
                       "LastCensusVAP", "LastCensusYear", "PopEstimate")]

names(vap2010) <- names(vaplong)
vap2010$municipality <- as.character(vap2010$municipality)
vap2010$municipality <- substr(vap2010$municipality, 2, nchar(vap2010$municipality))

vaplong <- rbind(vaplong, vap2010)

rm(vap2010)

########################
# 2011
#

vap2011$mcd_type <- substr(vap2011$muni, 1,1)
vap2011$mcd_type <- toupper(vap2011$mcd_type)
vap2011$year <- 2011
vap2011$PopEstimate <- vap2011$PopEstimate2011
vap2011$PopEstimate2011 <- NULL
vap2011$LastCensusPop <- vap2011$Census2010
vap2011$Census2010 <- NULL
vap2011$LastCensusVAP <- vap2011$vap2010_census
vap2011$LastCensusYear <- 2010
vap2011$vap2010_census <- NULL
vap2011$vap <- vap2011$vap2011
vap2011$vap2011 <- NULL
vap2011$per_change <- NULL
vap2011$num_change <- NULL
vap2011$change_type <- ""
vap2011$change_date <- ""


vap2011 <- vap2011[, c("doacode", "mcd_type", "muni", 'split',"county", "change_type", 
                       "change_date", "year", "vap", "LastCensusPop", 
                       "LastCensusVAP", "LastCensusYear", "PopEstimate")]

names(vap2011) <- names(vaplong)
vap2011$municipality <- as.character(vap2011$municipality)
vap2011$municipality <- substr(vap2011$municipality, 2, nchar(vap2011$municipality))

vaplong <- rbind(vaplong, vap2011)

rm(vap2011)

##########################
# 2012
#

vap2012$mcd_type <- substr(vap2012$muni, 1,1)
vap2012$mcd_type <- toupper(vap2012$mcd_type)
vap2012$year <- 2012
vap2012$PopEstimate <- vap2012$PopEstimate2012
vap2012$PopEstimate2012 <- NULL
vap2012$LastCensusPop <- vap2012$Census2010
vap2012$Census2010 <- NULL
vap2012$LastCensusVAP <- vap2012$vap2010_census
vap2012$LastCensusYear <- 2010
vap2012$vap2010_census <- NULL
vap2012$vap <- vap2012$vap2012
vap2012$vap2012 <- NULL
vap2012$per_change <- NULL
vap2012$num_change <- NULL
vap2012$change_type <- ""
vap2012$change_date <- ""


vap2012 <- vap2012[, c("doacode", "mcd_type", "muni", 'split',"county", "change_type", 
                       "change_date", "year", "vap", "LastCensusPop", 
                       "LastCensusVAP", "LastCensusYear", "PopEstimate")]

names(vap2012) <- names(vaplong)
vap2012$municipality <- as.character(vap2012$municipality)
vap2012$municipality <- substr(vap2012$municipality, 2, nchar(vap2012$municipality))


vaplong <- rbind(vaplong, vap2012)

rm(vap2012)

rm(vap2000_08, z, vNames, incomp)
################################################################################
############ CLEAN UP VAP LONG #################################################
################################################################################
apply(vaplong, 2, class)

# ERROR IN MILWAUKEE CODES

vaplong <- vaplong[!is.na(vaplong$doacode),]

vaplong$municipality <- gsub("\\*", "", vaplong$municipality)
library(stringr)
vaplong$municipality <- str_trim(vaplong$municipality, side="both")

vaplong$county_name <- as.character(vaplong$county_name)
vaplong$county_name[vaplong$county_name=="ST. CROIX"] <- "SAINT CROIX"

#vaplong$municipality <- gsub(" +\\*", "", vaplong$municipality)
#vaplong$municipality <- gsub(" *", "", vaplong$municipality, fixed=TRUE)

char2num <- function(x){
  x <- gsub(",", "", x)
  x <- as.numeric(x)
  return(x)
}

vaplong$year <- as.numeric(vaplong$year)
vaplong$vap <- char2num(vaplong$vap)
vaplong$LastCensusPop <- char2num(vaplong$LastCensusPop)
vaplong$LastCensusVAP <- char2num(vaplong$LastCensusVAP)
vaplong$LastCensusYear <- char2num(vaplong$LastCensusYear)
vaplong$PopEstimate <- char2num(vaplong$PopEstimate)
vaplong$LastCensusYear[vaplong$year < 2009] <- 2000
vaplong$LastCensusYear[vaplong$year < 2000] <- 1990

# Backfill Census population data

library(data.table)

#vaplongDT <- as.data.table(vaplong)

#vaplong <- as.data.frame(vaplongDT)

vaplongLag <- subset(vaplong, year==2009, select=c("doacode", "year","LastCensusPop", "LastCensusVAP"))

yrs <- c(2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008)

vaplongTEST <- vaplong

for(i in yrs){
  vaplongLag$year <- i
  vaplongTEST <- merge(vaplongTEST, vaplongLag, by=c("doacode","year"), all.x=TRUE)
  vaplongTEST$LastCensusPop[vaplongTEST$year == i] <- vaplongTEST$LastCensusPop.y[vaplongTEST$year==i] 
  vaplongTEST$LastCensusPop[vaplongTEST$year != i] <- vaplongTEST$LastCensusPop.x[vaplongTEST$year!=i] 
  vaplongTEST$LastCensusVAP[vaplongTEST$year == i] <- vaplongTEST$LastCensusVAP.y[vaplongTEST$year==i] 
  vaplongTEST$LastCensusVAP[vaplongTEST$year != i] <- vaplongTEST$LastCensusVAP.x[vaplongTEST$year!= i] 
  vaplongTEST$LastCensusVAP.x <- NULL; vaplongTEST$LastCensusVAP.y <- NULL
  vaplongTEST$LastCensusPop.x <- NULL; vaplongTEST$LastCensusPop.y <- NULL
}

# Check that merge worked
identical(vaplongTEST$LastCensusVAP[vaplongTEST$year == 2010], vaplong$LastCensusVAP[vaplong$year == 2010])
identical(vaplongTEST$LastCensusVAP[vaplongTEST$year == 2011], vaplong$LastCensusVAP[vaplong$year == 2011])
identical(vaplongTEST$LastCensusVAP[vaplongTEST$year == 2012], vaplong$LastCensusVAP[vaplong$year == 2012])
identical(vaplongTEST$LastCensusVAP[vaplongTEST$year == 2009], vaplong$LastCensusVAP[vaplong$year == 2009])

vaplong <- vaplongTEST

rm(vaplongLag, vaplongTEST, yrs, i)

# Check for unusual leaps
#
#outlier <- subset(vaplong, (vaplong$vap - vaplong$LastCensusVAP) > 2000)


################################################################################
# Calculate district VAP using munipieces
################################################################################

####################################################################
# REMERGE BASED ON DOR AND DOA CODES
# DOA CODES FROM MILWAUKEE DO NOT EQUAL DOR CODES
# SD DATA IS DOR DATA AND NEEDS THESE CODES
# VOTE DATA IS DOA CODES
# NEED TO RECONCILE TO MERGE

cw <- read.csv("../Data/Raw Files/Election Data/mcdcrosswalk.csv")

struc <- list.files("../Data/Raw Files/Election Data/sdmunipieces", 
                    full.names=TRUE)


for(i in 1:length(struc)){
  eval(parse(text=paste0("sd0",1+i,"<- read.csv(file=struc[",i,"], 
                         stringsAsFactors=FALSE)")))
  eval(parse(text=paste0("collength <- ifelse(ncol(sd0",i+1,")>11, 11, ncol(sd0", i+1,"))")))
  eval(parse(text=paste0("sd0",1+i,"<- sd0", 1+i,"[,1:collength]")))
}

library(plyr)
library(stringr)

cleanSDdata <- function(df){
  myregexp <- "[[:digit:]]+"
  df$eqv <- gsub(",", "", df$eqv)
  df$levy <- gsub(",","", df$levy)
  df <- df[, 1:6]
  df <- na.omit(df)
  df[,1] <- as.character(df[,1])
  df[,1] <- str_extract(df[,1], myregexp)
  df[,1] <- as.numeric(df[,1])
  names(df)[1] <- "municode"
  df$eqv<-as.numeric(df$eqv)
  df$levy<-as.numeric(df$levy)
  df$rate <- NA
  df$eqvout <- NA
  return(df)
}

sd02 <- cleanSDdata(sd02)
sd02$year <- 2002
sd03 <- cleanSDdata(sd03)
sd03$year <- 2003
sd04 <- cleanSDdata(sd04)
sd04$year <- 2004

cleanSDdata2 <- function(df){
  df$eqv <- gsub(",", "", df$eqv)
  if(exists("eqvout", where=df)){
    df$eqvout <- gsub(",", "", df$eqvout)
    df$eqvout <- as.numeric(df$eqvout)
  }
  if(exists("rate", where=df)){
    df$rate <- as.numeric(df$rate)
  }
  if(exists("taxrate", where=df)){
    df$rate <- as.numeric(df$taxrate)
    df$taxrate <- NULL
  }
  df$rate <- NA
  df$eqvout <- NA
  df$levy <- gsub(",","", df$levy)
  df$distname <- NULL
  df$muniname <- NULL
  df$X <- NULL
  df$county <- NULL
  df[,1] <- as.numeric(df[,1])
  names(df)[1] <- "municode"
  df$eqv<-as.numeric(df$eqv)
  df$levy<-as.numeric(df$levy)
  return(df)
}

sd05 <- cleanSDdata2(sd05)
sd05$year <- 2005
sd06 <- cleanSDdata2(sd06)
sd06$year <- 2006
sd07 <- cleanSDdata2(sd07)
sd07$year <- 2007
sd08 <- cleanSDdata2(sd08)
sd08$year <- 2008
sd09 <- cleanSDdata2(sd09)
sd09$year <- 2009
sd09$distid <- sd09$distcode
sd09$distcode <- NULL
sd010 <- cleanSDdata2(sd010)
sd010$year <- 2010
sd011 <- cleanSDdata2(sd011)
sd011$year <- 2011
sd012 <- cleanSDdata2(sd012)
sd012$year <- 2012
sd012$municname <- NULL

vars <- names(sd02)

# cw$flag <- cw$doaCode != cw$dorCode
# 
# cw_sub <- subset(cw, flag==TRUE)
# 
# cw_sub <- cw_sub[, 1:2]
# 
# test <- merge(sd02, cw[,1:2], by.x="municode", by.y="dorCode")

for(i in 1:length(struc)){
  eval(parse(text=paste0("sd0", 1+i,"<- sd0", 1+i, "[, vars]")))
  eval(parse(text=paste0("tmp <- merge(sd0", 1+i, ", cw[,1:2], by.x='municode', by.y='dorCode')")))
  eval(parse(text=paste0("vptempA <- merge(vaplong, tmp, by.x=c('doacode', 'year'), 
                         by.y=c('doaCode', 'year'), all.y=TRUE)")))
  if(exists("vptemp")){
    vptemp <- rbind.fill(vptempA, vptemp)
  } else if(!exists("vptemp")){
    vptemp <- vptempA
  }
}

rm(vptempA)

for(i in 1:length(struc)){
  #eval(parse(text=paste0("sd0", 1+i,"<- sd0", 1+i, "[, vars]")))
  eval(parse(text=paste0("rm(sd0",1+i,")")))
}

rm(collength, i, struc, vars)


###########################################
# Pro-rate vap by size of EQV in the district
# This is the only correct way to measure the share of each MCD that is in the 
# school district
# Data comes from DOR records
sdprop <- ddply(vptemp, .(doacode, year), summarize, "eqvtot"=sum(eqv,na.rm=T))
vptemp <- merge(vptemp, sdprop, by=c("doacode", "year"))
vptemp$share <- vptemp$eqv / vptemp$eqvtot


vptemp <- as.data.table(vptemp)

VAP_dist <- vptemp[, list(VAP = sum(vap*share, na.rm=T), 
                          TOTPOP = sum(PopEstimate*share, na.rm=T),
                          LastCensusPop = sum(LastCensusPop*share, na.rm=T), 
                          LastCensusVAP = sum(LastCensusVAP*share, na.rm=T)),
                   by=c("year", "distid")]


###########################
# Checks
###########################
# Need to interpolate for too big of swings in VAP 
# This is probably due to redrawing MCD boundaries
# Need to fix this by smoothing out across
# Not sure how to describe this method, but will need to be done
# Find way to flag outliers within district
# Find way to replace them with a more sensible guess? 
# Mark them as replaced
# THIS IS MORE DEFENSIBLE THAN MI right?

# Identify districts where VAP changes over 15% in one direction or another 
# from 1, 2, and 3 year lags
# Change these to a 3 year avg of the non-crazy hears

#toosmall <- subset(VAP_dist, VAP < 300 & distid!=3976)
#toobig <- subset(VAP_dist, VAP <e 200)
library(eeptools)

mylag <- function(df){
  lag1 <- eeptools:::lag_data(df, group = "distid", 
                              time= "year", values = c("VAP"), 
                              periods=1)
  
  lag2 <- eeptools:::lag_data(lag1, group = "distid", 
                              time= "year", values = c("VAP"), 
                              periods=2)
  
  lag3 <- eeptools:::lag_data(lag2, group = "distid", 
                              time= "year", values = c("VAP"), 
                              periods=3)
  lag4 <- eeptools:::lag_data(lag3, group = "distid", 
                              time= "year", values = c("VAP"), 
                              periods=4)
  
  return(lag4)
}

#VAPwide <- reshape(VAP_dist[, c(1, 2, 3)], timevar="year", idvar = "distid",direction="wide")

## Fully smooth


LinInterp <- function(x, includeLast = NULL){
  n <- length(x)
  idx <- 1:n
  if(missing(includeLast)){
    includeLast <- FALSE
  }
  if(includeLast == TRUE){
    m1 <- lm(x ~ idx)
    y <- predict(m1, newdata = data.frame(idx=n))
    
  } else if(includeLast == FALSE){
    x <- x[1:n-1]
    idx <- 1:(n-1)
    m1 <- lm(x ~ idx)
    y <- predict(m1, newdata = data.frame(idx=n-1))
      
  }
  return(y)
}

annlchg <- mylag(as.data.frame(VAP_dist))

annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
annlchg$VAP_chg4 <- (annlchg$VAP - annlchg$VAP.lag4) / annlchg$VAP.lag4


annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
annlchg$VAP_flag4 <- ifelse(annlchg$VAP_chg4 > .15 | annlchg$VAP_chg4 < -.15, 1, 0)
annlchg$VAP_flag4[is.na(annlchg$VAP_flag4)] <- 0


annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3 + 
                            annlchg$VAP_flag4



################################################################################
# Manually adjust Kohler (2842)
# OTHERS??
# 665
# 6328
# 3976 (Norris, should be dropped)
# 3510
# 1092
# 5593
# 4011
# 3787
################################################################################

annlchg$VAP[annlchg$distid==2842 & annlchg$year == 2005] <- 1995
annlchg$LastCensusPop[annlchg$distid==2842 & annlchg$year == 2005] <- 2675
annlchg$LastCensusVAP[annlchg$distid==2842 & annlchg$year == 2005] <- 1930



################################################################################
# Interpolate remaining outliers
#################################################################################

annlchg.tmp <- annlchg[annlchg$VAP_flag_rollup > 1 & !is.na(annlchg$VAP_flag_rollup), ]
annlchg <- annlchg[annlchg$VAP_flag_rollup < 2, ]

annlchg.tmp$VAP <- apply(annlchg.tmp[,c(10, 9, 8, 7)], 1, function(x) 
                          tryCatch(LinInterp(x, includeLast=TRUE), error = function(e) NA))


annlchg <- rbind(annlchg, annlchg.tmp)

#annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
annlchg <- mylag(annlchg[, c(1, 2, 3)])

annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
annlchg$VAP_chg4 <- (annlchg$VAP - annlchg$VAP.lag4) / annlchg$VAP.lag4


annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
annlchg$VAP_flag4 <- ifelse(annlchg$VAP_chg4 > .15 | annlchg$VAP_chg4 < -.15, 1, 0)
annlchg$VAP_flag4[is.na(annlchg$VAP_flag4)] <- 0


annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3 + 
  annlchg$VAP_flag4

table(annlchg$VAP_flag_rollup)

table(annlchg$VAP_flag1)
table(annlchg$VAP_flag2)
table(annlchg$VAP_flag3)
table(annlchg$VAP_flag4)


############### Smooth out 1 year 

annlchg.tmp <- annlchg[annlchg$VAP_flag1 == 1 & !is.na(annlchg$VAP_flag1), ]
annlchg <- annlchg[annlchg$VAP_flag1 < 1, ]

#annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7,9,11)], 1, psych::geometric.mean)

annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7, 6, 5, 4)], 1, function(x) 
  tryCatch(LinInterp(x, includeLast=TRUE), error = function(e) NA))


annlchg <- rbind(annlchg, annlchg.tmp)

#annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
annlchg <- mylag(annlchg[, c(1, 2, 3)])

annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
annlchg$VAP_chg4 <- (annlchg$VAP - annlchg$VAP.lag4) / annlchg$VAP.lag4


annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
annlchg$VAP_flag4 <- ifelse(annlchg$VAP_chg4 > .15 | annlchg$VAP_chg4 < -.15, 1, 0)
annlchg$VAP_flag4[is.na(annlchg$VAP_flag4)] <- 0


annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3 + 
  annlchg$VAP_flag4

table(annlchg$VAP_flag_rollup)

table(annlchg$VAP_flag1)
table(annlchg$VAP_flag2)
table(annlchg$VAP_flag3)
table(annlchg$VAP_flag4)

############### Smooth out 2 year 

annlchg.tmp <- annlchg[annlchg$VAP_flag2 == 1 & !is.na(annlchg$VAP_flag2), ]
annlchg <- annlchg[annlchg$VAP_flag2 < 1, ]

#annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7,9,11)], 1, psych::geometric.mean)

annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7, 6, 5, 4)], 1, function(x) 
  tryCatch(LinInterp(x, includeLast=TRUE), error = function(e) NA))


annlchg <- rbind(annlchg, annlchg.tmp)

#annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
annlchg <- mylag(annlchg[, c(1, 2, 3)])

annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
annlchg$VAP_chg4 <- (annlchg$VAP - annlchg$VAP.lag4) / annlchg$VAP.lag4


annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
annlchg$VAP_flag4 <- ifelse(annlchg$VAP_chg4 > .15 | annlchg$VAP_chg4 < -.15, 1, 0)
annlchg$VAP_flag4[is.na(annlchg$VAP_flag4)] <- 0


annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3 + 
  annlchg$VAP_flag4

table(annlchg$VAP_flag_rollup)

table(annlchg$VAP_flag1)
table(annlchg$VAP_flag2)
table(annlchg$VAP_flag3)
table(annlchg$VAP_flag4)


############### Smooth out 3 year 

annlchg.tmp <- annlchg[annlchg$VAP_flag3 == 1 & !is.na(annlchg$VAP_flag3), ]
annlchg <- annlchg[annlchg$VAP_flag3 < 1, ]

#annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7,9,11)], 1, psych::geometric.mean)

annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7, 6, 5, 4)], 1, function(x) 
  tryCatch(LinInterp(x, includeLast=TRUE), error = function(e) NA))


annlchg <- rbind(annlchg, annlchg.tmp)

#annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
annlchg <- mylag(annlchg[, c(1, 2, 3)])

annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
annlchg$VAP_chg4 <- (annlchg$VAP - annlchg$VAP.lag4) / annlchg$VAP.lag4


annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
annlchg$VAP_flag4 <- ifelse(annlchg$VAP_chg4 > .15 | annlchg$VAP_chg4 < -.15, 1, 0)
annlchg$VAP_flag4[is.na(annlchg$VAP_flag4)] <- 0


annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3 + 
  annlchg$VAP_flag4

table(annlchg$VAP_flag_rollup)

table(annlchg$VAP_flag1)
table(annlchg$VAP_flag2)
table(annlchg$VAP_flag3)
table(annlchg$VAP_flag4)


################################################################################
# Recombine VAP adjusted
################################################################################


names(annlchg)
annlchg <- annlchg[, c(1, 2, 3)]
names(annlchg) <- c("distid", "year", "VAP_adj")

VAP_dist <- merge(as.data.frame(VAP_dist), as.data.frame(annlchg), 
                  by=c("year", "distid"))

names(VAP_dist)

rm(annlchg.tmp, tmp, sdprop,  annlchg)

################################################################################
## Add the regular voter turnout from standard elections
## 
################################################################################

setwd("../Data/Raw Files/Election Data")
source("dataclean.R")
setwd("../../../MasterText")

names(distvotes02)

distvotes02 <- subset(distvotes02, select=c("distid", "year","TOTPOP18", "GOVTOT", 
                                            "GOVDEM", "GOVREP", "CONTOT", 
                                            "CONDEM", "CONREP"))

mynames <- c("distid", "year", "TOTPOP", "TOPTOTVOTES", "TOPDEM", "TOPREP", 
             "SECTOT", "SECDEM", "SECREP")

names(distvotes04)

distvotes04 <- subset(distvotes04, select=c("distid", "year", "TOTPOP18", "PRESTOT", 
                                            "PRESDEM", "PRESREP", "CONTOT", "CONDEM", 
                                            "CONREP"))

names(distvotes06)

distvotes06 <- subset(distvotes06, select=c("distid", "year","TOTPOP18", "GOVTOT", 
                                            "GOVDEM", "GOVREP", "CONTOT", "CONDEM",
                                            "CONREP"))

names(distvotes08)

distvotes08 <- subset(distvotes08, select=c("distid", "year", "TOTPOP18", "PRESTOT", 
                                            "PRESDEM", "PRESREP", "CONTOT", "CONDEM", 
                                            "CONREP"))

names(distvotes10)

distvotes10$TOTPOP18 <- NA

distvotes10 <- subset(distvotes10, select=c("distid", "year","TOTPOP18", "GOVTOT", 
                                            "GOVDEM", "GOVREP", "USCONTOT", "USCONDEM",
                                            "USCONREP"))


distvotes12$TOTPOP18 <- NA


test <- merge(distvotes12, distvotes12r)

distvotes12 <- subset(test, select=c("distid", "year", "TOTPOP18", "PRESTOT", "PRESDEM", "PRESREP",  "RECTOT", 
                                     "GOVDEM", "GOVREP"))



names(distvotes02) <- mynames
names(distvotes04) <- mynames
names(distvotes06) <- mynames
names(distvotes08) <- mynames
names(distvotes10) <- mynames
names(distvotes12) <- mynames


district_vote_panel <- rbind(distvotes02, distvotes04)
district_vote_panel <- rbind(district_vote_panel, distvotes06)
district_vote_panel <- rbind(district_vote_panel, distvotes08)
district_vote_panel <- rbind(district_vote_panel, distvotes10)
district_vote_panel <- rbind(district_vote_panel, distvotes12)

###################################################################################
# Interpolate district population
##################################################################################

library(data.table)
dvp <- as.data.table(district_vote_panel)


dvp2 <- dvp[, list(TOTPOP_CHG = (TOTPOP[year==2008] - TOTPOP[year==2002]) / 4),
            by=c("distid")]


dvp <- merge(dvp, dvp2, by=c("distid"))

for(i in unique(dvp$distid)){
  for(j in c(2010,2012)){
    dvp$TOTPOP[dvp$distid==i & dvp$year==j] <- 
      dvp$TOTPOP[dvp$distid==i & dvp$year==j - 2] + dvp$TOTPOP_CHG[dvp$distid==i & dvp$year == j-2]
    
  }
}

###############################################################################################



rm(district_vote_panel)

dvp$TOPturnout1 <- dvp$TOPTOTVOTES / dvp$TOTPOP
dvp$TOPdemShare <- dvp$TOPDEM / dvp$TOPTOTVOTES
dvp$TOPrepShare <- dvp$TOPREP / dvp$TOPTOTVOTES
dvp$SECdemShare <- dvp$SECDEM / dvp$SECTOT
dvp$SECrepShare <- dvp$SECREP / dvp$SECTOT


dvp$TOTPOP_CHG <- NULL
dvp$SECdemShare <- ifelse(is.finite(dvp$SECdemShare), dvp$SECdemShare, 0)
dvp$SECrepShare <- ifelse(is.finite(dvp$SECrepShare), dvp$SECrepShare, 0)

# Clean up divide by 0 errors
# consider what to do with outliers / badly measured turnout

names(dvp) <- tolower(names(dvp))

dvp <- as.data.frame(dvp)
dvp2 <- dvp
dvp2$year <- as.numeric(dvp2$year) + 1
dvp <- rbind(dvp, dvp2)
rm(dvp2)

rm(distvotes12r, distvotes12, distvotes10, distvotes09, distvotes08, 
   distvotes06, distvotes05, distvotes04, distvotes02, bigtest11)
rm(dvp2, prespref11, sd11, test, i, j, mynames, wisc)
# 
# save(vptemp, vaplong, cw, dvp, file="data/cache/VotingPopulation.rda", 
#      compress="gzip")

rm(vptemp, vaplong, cw)

###################
#For export
# 
# dvp1 <- dvp
# dvp2 <- dvp
# dvp2$year <- as.numeric(dvp2$year) + 1
# 
# tmp <- rbind(dvp1, dvp2)
# rm(dvp1, dvp2)
# 
# VAP_dist <- as.data.frame(VAP_dist)
# tmp <- as.data.frame(tmp)
# 
# tmp2 <- merge(VAP_dist, tmp, by=c("distid", "year"))
# 
# rm(tmp)
# 
# 
# save(tmp2, file="VotingPopulationAndPartisanship.rda")
# 

################################################################################

################################################################################

################################################################################
# Erratta
################################################################################
# LinInterp <- function(x, includeLast = NULL){
#   n <- length(x)
#   if(missing(includeLast)){
#     includeLast <- FALSE
#   }
#   if(includeLast == TRUE){
#     chg <- (x[n] - x[1]) / n
#     y <- x[1] + (chg * n)
#     
#   } else if(includeLast == FALSE){
#     chg <- (x[n-1] - x[1]) / n-1
#     y <- x[1] + (chg * n-1)
#     
#   }
#   
#   return(y)
# }



# 
# 
# 
# 
# #################################
# # Focus on lags 2
# 
# annlchg.tmp <- annlchg[annlchg$VAP_flag_rollup > 1 & !is.na(annlchg$VAP_flag_rollup), ]
# annlchg <- annlchg[annlchg$VAP_flag_rollup < 2, ]
# 
# annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7,9,11)], 1, psych::geometric.mean)
# 
# annlchg <- rbind(annlchg, annlchg.tmp)
# annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
# 
# 
# annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
# annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
# annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
# 
# annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
# annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
# annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
# annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
# annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
# annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
# 
# annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3
# table(annlchg$VAP_flag_rollup)
# 
# #################################
# # Focus on lags 1
# 
# annlchg.tmp <- annlchg[annlchg$VAP_flag_rollup > 0 & !is.na(annlchg$VAP_flag_rollup), ]
# annlchg <- annlchg[annlchg$VAP_flag_rollup < 1, ]
# 
# annlchg.tmp$VAP <- apply(annlchg.tmp[,c(7,9,11)], 1, psych::geometric.mean)
# 
# annlchg <- rbind(annlchg, annlchg.tmp)
# annlchg <- mylag(annlchg[, c(1, 2, 3, 4, 5, 6)])
# 
# annlchg$VAP_chg <- (annlchg$VAP - annlchg$VAP.lag1) / annlchg$VAP.lag1
# annlchg$VAP_chg2 <- (annlchg$VAP - annlchg$VAP.lag2) / annlchg$VAP.lag2
# annlchg$VAP_chg3 <- (annlchg$VAP - annlchg$VAP.lag3) / annlchg$VAP.lag3
# 
# annlchg$VAP_flag1 <- ifelse(annlchg$VAP_chg > .15 | annlchg$VAP_chg < -.15, 1, 0)
# annlchg$VAP_flag1[is.na(annlchg$VAP_flag1)] <- 0
# annlchg$VAP_flag2 <- ifelse(annlchg$VAP_chg2 > .15 | annlchg$VAP_chg2 < -.15, 1, 0)
# annlchg$VAP_flag2[is.na(annlchg$VAP_flag2)] <- 0
# annlchg$VAP_flag3 <- ifelse(annlchg$VAP_chg3 > .15 | annlchg$VAP_chg3 < -.15, 1, 0)
# annlchg$VAP_flag3[is.na(annlchg$VAP_flag3)] <- 0
# 
# annlchg$VAP_flag_rollup <- annlchg$VAP_flag1 + annlchg$VAP_flag2 + annlchg$VAP_flag3
# table(annlchg$VAP_flag_rollup)
# 
# 
# 
# 



# 
# VAPwide[, 4] <- apply(VAPwide[,c(2, 3, 4)], 1, function(x) tryCatch(LinInterp(x), error = 
#                                                                       function(e) NA))
# 
# VAPwide[, 4] <- apply(VAPwide[,c(2, 3, 4)], 1, psych::geometric.mean)
# VAPwide[, 5] <- apply(VAPwide[,c(2, 3, 4, 5)], 1, psych::geometric.mean)
# VAPwide[, 6] <- apply(VAPwide[,c(2, 3, 4, 5, 6)], 1, psych::geometric.mean)
# VAPwide[, 7] <- apply(VAPwide[,c(4, 5, 6, 7)], 1, psych::geometric.mean)
# VAPwide[, 8] <- apply(VAPwide[,c(4, 5, 6, 7, 8)], 1, psych::geometric.mean)
# VAPwide[, 9] <- apply(VAPwide[,c(5, 6, 7, 8, 9)], 1, psych::geometric.mean)
# VAPwide[, 10] <- apply(VAPwide[,c(5, 6, 7, 8, 9, 10)], 1, psych::geometric.mean)
# VAPwide[, 11] <- apply(VAPwide[,c(6, 7, 8, 9, 10, 11)], 1, psych::geometric.mean)
# VAPwide[, 12] <- apply(VAPwide[,c(7, 8, 9, 10, 11, 12)], 1, psych::geometric.mean)
# 
# VAPchk <- reshape(VAPwide, direction="long")
# 
# names(VAPchk) <- c("distid", "year", "VAP")
## Smooth only flags

#annlchg <- mylag(VAPchk)
