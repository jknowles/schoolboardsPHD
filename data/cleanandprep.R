################################################################################
# Collapse datasets
# Combine them
################################################################################

source("data/dataAssemble.R")
library(data.table)


## reshape school district by year

distyear <- as.data.table(dat[dat$electiontype==1,])[, list(candidates = length(unique(candidateid2)),
                                      winners = sum(winner),
                                      totalvotes = sum(votes),
                                      incdefeat = sum(incumbent[winner!=1]),
                                      minorcand = sum(minor), 
                                      repeatcand = sum(repeater)), 
                               by=c("distid", "year", "electiontype")]


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
