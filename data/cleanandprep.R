################################################################################
# Collapse datasets
# Combine them
################################################################################

source("data/dataAssemble.R")
load("data/cache/VotingPopulation.rda")

VAP_dist <- as.data.frame(VAP_dist)


test <- merge(VAP_dist, dvp, by=c("distid", "year"))

library(data.table)
library(ggplot2)


## reshape school district by year


# How to calculate total votes in elections with multiple winners...

distyear <- as.data.table(dat[dat$electiontype==1,])[, 
                                list(candidates = length(unique(candidateid2)),
                                      winners = sum(winner, na.rm=T),
                                      totalvotes = sum(votes, na.rm=T),
                                      incdefeat = sum(incumbent[winner!=1]),
                                      minorcand = sum(minor, na.rm=T), 
                                      repeatcand = sum(repeater, na.rm=T)), 
                               by=c("distid", "year", "electiontype")]


distyear <- as.data.frame(distyear)

distyear$totalvotes2 <- distyear$totalvotes / ifelse(distyear$winners < 2, 1, distyear$winners)
zed <- merge(VAP_dist, distyear)

zed$turnout1 <- zed$totalvotes/zed$VAP
zed$turnout2 <- zed$totalvotes2/zed$VAP

nrow(zed[zed$turnout1 > 1,])
nrow(zed[zed$turnout2 > 1,])

head(zed[zed$turnout1 > 1,], 20)


qplot(LastCensusPop, totalvotes2/VAP, data=zed[zed$totalvotes/zed$VAP < 1,]) + 
  scale_x_sqrt() + scale_y_log10()


distyearPRIMARY <- as.data.table(dat[dat$electiontype==2,])[, list(candidates = length(unique(candidateid2)),
                                                            winners = sum(winner),
                                                            totalvotes = sum(votes),
                                                            incdefeat = sum(incumbent[winner!=1]),
                                                            minorcand = sum(minor), 
                                                            repeatcand = sum(repeater)), 
                                                     by=c("distid", "year", "electiontype")]

distyearSPECIAL <- as.data.table(dat[dat$electiontype==3,])[, list(candidates = length(unique(candidateid2)),
                                                                   winners = sum(winner),
                                                                   totalvotes = sum(votes),
                                                                   incdefeat = sum(incumbent[winner!=1]),
                                                                   minorcand = sum(minor), 
                                                                   repeatcand = sum(repeater)), 
                                                            by=c("distid", "year", "electiontype")]
