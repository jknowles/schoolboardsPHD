################################################################################
# Collapse datasets
# Combine them
################################################################################

library(data.table)

#source("data/dataAssemble.R")
#load("data/cache/VotingPopulation.rda")

VAP_dist <- as.data.frame(VAP_dist)
dvp$totpop <- NULL

MACROpart <- merge(VAP_dist, dvp, by=c("distid", "year"))

rm(dvp, VAP_dist, cw, vaplong, vptemp)


load("data/cache/AnalyticalSampleFeb2014.rda")
FINANCE <- newdat; rm(newdat)


SByear_gen <- as.data.table(dat[dat$electiontype==1,])[, 
                                list(candidates = length(unique(candidateid2)),
                                      winners = sum(winner, na.rm=T),
                                      totalvotes = sum(votes, na.rm=T),
                                      incdefeat = sum(incumbent[winner!=1]),
                                      minorcand = sum(minor, na.rm=T), 
                                      repeatcand = sum(repeater, na.rm=T)), 
                               by=c("distid", "year", "electiontype")]

SByear_prim <- as.data.table(dat[dat$electiontype==2,])[, 
                              list(candidates = length(unique(candidateid2)),
                              winners = sum(winner, na.rm=T),
                              totalvotes = sum(votes, na.rm=T),
                              incdefeat = sum(incumbent[winner!=1]),
                              minorcand = sum(minor, na.rm=T), 
                              repeatcand = sum(repeater, na.rm=T)), 
                                         by=c("distid", "year", "electiontype")]

################
# For now we just flag contested primaries as a dummy
###############

SByear_prim$contested <- ifelse(SByear_prim$incdefeat > 0 | 
                                  (SByear_prim$candidates - SByear_prim$minorcand) > 
                                  SByear_prim$winners, 1, 0)

SByear_gen <- as.data.frame(SByear_gen); SByear_prim <- as.data.frame(SByear_prim)

SBELEC <- merge(SByear_gen, SByear_prim[, c(1, 2, 10)], by = c("distid", "year"), 
                all.x=TRUE)

rm(SByear_gen, SByear_prim)

SBELEC$primary <- "None"
SBELEC$primary[SBELEC$contested == 0] <- "Uncontested"
SBELEC$primary[SBELEC$contested == 1] <- "Contested"
SBELEC$contested <- NULL
SBELEC$electiontype <- NULL

FINANCE <- FINANCE[, c(1:93, 110:263)]
FULLDAT <- merge(MACROpart, FINANCE, by = c("distid", "year"))


FULLDAT$sample <- 0
FULLDAT$sample[FULLDAT$distid %in% unique(SBELEC$distid)] <- 1


SBELEC <- merge(SBELEC, MACROpart, by = c("distid", "year"), all.x=TRUE)
rm(MACROpart)

SBELEC <- merge(SBELEC, FINANCE, by = c("distid", "year"), all.x=TRUE)
rm(FINANCE, dat, metadata)

#distyear <- as.data.frame(distyear)

