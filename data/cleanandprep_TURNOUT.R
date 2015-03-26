################################################################################
# Collapse datasets
# Combine them
################################################################################

source("data/dataAssemble.R")
load("data/cache/DataMergeVAP.rda")
load("data/cache/fullDataSep2014.rda")


distAttr <- tmp[, c("distid", "year", "TotalPopulation", "NonSDMill", "AdjPopulation",
                    "PopWhiteAlone", "median_income", "total_levy", "genaid", "per65o", 
                    "PerBachelorOrAbove", "OOH_share", "millrate", 
                    "COUNTY", "CESA", "ATHLETIC_CONF_NUMBER", "eqv_member", 
                    "nonwhitePupilPercentPublic",
                    "balance_lag", "member_aidyear", "member_delta", "millrate_delta", 
                    "locale2", "member_lag", "ref_share")]

distAttr$per_white_all <- distAttr$PopWhiteAlone / distAttr$TotalPopulation
distAttr$white_count <- NULL
distAttr$PopWhiteAlone <- NULL
distAttr$TotalPopulation <- NULL

#------------------------------------------------------------
races <- as.data.frame(races)
races.tmp <- merge(races, VAP_dist, by = c("distid", "year"))

presTurn$presTwoPartyVote <- presTurn$presDemVotes + presTurn$presRepVotes
presTurn$presTwoPartyShareDem <- presTurn$presDemVotes / presTurn$presTwoPartyVote

govTurn$govTwoPartyVote <- govTurn$govDemVotes + govTurn$govRepVotes
govTurn$govTwoPartyShareDem <- govTurn$govDemVotes / govTurn$govTwoPartyVote


# turnout over the prior presidential election
races.tmp <- merge(races.tmp, presTurn, by = c("distid", "year"), all.x=TRUE)
races.tmp <- merge(races.tmp, govTurn, by = c("distid", "year"), all.x=TRUE)

races.tmp <- subset(races.tmp, select = c("distid", "year", "raceid2", "ncand", 
                                          "nrealcand", "nwins", "ninc", "raceid",
                                          "nminor", "votes", "districtwide", 
                                          "electiontype", "VAP", "VAP_adj", "nincDefInd", 
                                          "topPresVotesPrior", "presTwoPartyShareDem", 
                                          "topGovVotesPrior", "govTwoPartyShareDem"))

races.tmp <- subset(races.tmp, raceid!=0)
# look at general
races.tmp <- subset(races.tmp, electiontype == 1)

# Look at districtwide only
races.tmp <- subset(races.tmp, districtwide == 1)
races.tmp <- subset(races.tmp, nrealcand > 0)
races.tmp <- subset(races.tmp, nwins > 0)

races.tmp <- races.tmp[!is.na(races.tmp$distid),]
races.tmp$voters <- races.tmp$votes / races.tmp$nwins
races.tmp$turnout <- races.tmp$voters/races.tmp$VAP_adj
## Convert to district average somehow

dist_turn <- ddply(races.tmp, .(distid, year), summarise, 
                   ncand = sum(ncand), nrealcand = sum(nrealcand), 
                   nwins = sum(nwins), ninc = sum(ninc), 
                   nminor = sum(nminor), votes = sum(votes), 
                   VAP_adj = statamode(VAP_adj), 
                   incDefeats = sum(nincDefInd),
                   nraces = length(distid))

dist_turn$districtwide <- 1
############
# Non district-wide
############
races <- as.data.frame(races)
races.tmp <- merge(races, VAP_dist, by = c("distid", "year"))

races.tmp <- subset(races.tmp, select = c("distid", "year", "raceid2", "ncand", 
                                          "nrealcand", "nwins", "ninc", "raceid",
                                          "nminor", "votes", "districtwide", "nincDefInd",
                                          "electiontype", "VAP_adj"))

races.tmp <- subset(races.tmp, raceid!=0)
# look at general
races.tmp <- subset(races.tmp, electiontype == 1)
# Look at non-districtwide only
races.tmp <- subset(races.tmp, districtwide == 0)
races.tmp <- subset(races.tmp, nrealcand > 0)
races.tmp <- races.tmp[!is.na(races.tmp$distid),]

# collapse to the district level

dist.tmp <- ddply(races.tmp, .(distid, year), summarise, 
                  ncand = sum(ncand), nrealcand = sum(nrealcand), 
                  nwins = sum(nwins), ninc = sum(ninc), 
                  nminor = sum(nminor), votes = sum(votes), 
                  VAP_adj = statamode(VAP_adj), 
                  incDefeats = sum(nincDefInd),
                  nraces = length(distid))

dist.tmp$districtwide <- 0
dist.tmp$districtwide <- 0

dist_turn <- rbind(dist_turn, dist.tmp)

row_counts <- ddply(dist_turn, .(distid, year), nrow)
dist_turn <- merge(dist_turn, row_counts, all.x=TRUE)
dist_turn$recs <- dist_turn$V1; dist_turn$V1 <- NULL

# Have to collapse down to district level thoughtfully now

dist_turn <- ddply(dist_turn, .(distid, year), summarize, 
                   ncand = sum(ncand), nrealcand = sum(nrealcand), 
                   nwins = sum(nwins), ninc = sum(ninc), 
                   nminor = sum(nminor), votes = sum(votes), 
                   VAP_adj = ceiling(as.numeric(VAP_adj)[1]), 
                   incDefeats = sum(incDefeats),
                   nraces = sum(nraces), 
                   districtwide = max(districtwide), 
                   distWidemix = max(recs))
# dist_turn1 <- dist_turn[dist_turn$recs >= 1 & dist_turn$districtwide > 0,]
# dist_turn2 <- dist_turn[dist_turn$recs == 1 & dist_turn$districtwide == 0,]
# dist_turn <- rbind(dist_turn1, dist_turn2)
# dist_turn$recs <- NULL
## Clean up metrics
# turnout over the prior presidential election
## Clean up metrics
# turnout over the prior presidential election
dist_turn <- merge(dist_turn, presTurn, by = c("distid", "year"), all.x=TRUE)
dist_turn <- merge(dist_turn, govTurn, by = c("distid", "year"), all.x=TRUE)
dist_turn$VAP_adj <- as.numeric(dist_turn$VAP_adj)
dist_turn$voters <- dist_turn$votes / dist_turn$nwins
dist_turn$turnout <- dist_turn$voters / dist_turn$VAP_adj
# Fall turnout 
dist_turn$fallTurnout <- (dist_turn$topGovTurnoutPrior + dist_turn$topPresTurnoutPrior) / 2
dist_turn$fallTwoPartyShareDem <- (dist_turn$govTwoPartyShareDem + dist_turn$presTwoPartyShareDem) /2

rm(races.tmp, row_counts, dist.tmp)

dist_turn$contest <- "Uncontested"
dist_turn$contest[dist_turn$nrealcand > dist_turn$nwins & dist_turn$ninc > 0] <- "Incumbent Contested"
dist_turn$contest[dist_turn$nrealcand > dist_turn$nwins & dist_turn$ninc ==0] <- "Open Contested"

lg  <- function(x) c(NA, x[1:length(x)-1])
lg2 <- function(x) c(NA, NA, x[2:length(x) -2])

dist_turn$year <- as.numeric(dist_turn$year)
dist_turn.tmp <- dist_turn[, c("distid", "year", "voters", "turnout")]

dist_turn.tmp <- dist_turn.tmp[order(dist_turn.tmp$distid, dist_turn.tmp$year),]

dist_turn.tmp <- as.data.table(dist_turn.tmp)[, votersLag1:= lg(voters), by = "distid"]
dist_turn.tmp <- as.data.table(dist_turn.tmp)[, votersLag2:= lg2(voters), by = "distid"]
dist_turn.tmp <- as.data.table(dist_turn.tmp)[, turnoutLag1:= lg(turnout), by = "distid"]
dist_turn.tmp <- as.data.table(dist_turn.tmp)[, turnoutLag2:= lg2(turnout), by = "distid"]
dist_turn.tmp$voters <- NULL
dist_turn.tmp$turnout <- NULL
dist_turn.tmp <- as.data.frame(dist_turn.tmp)
dist_turn <- merge(dist_turn, dist_turn.tmp)
rm(dist_turn.tmp)
dist_turn <- merge(dist_turn, distAttr, by = c("distid", "year"))

cand.tmp <- dat[dat$candidateid!=99 & dat$electiontype==1, ]
votes.tmp <- merge(cand.tmp, as.data.frame(races)[races$nwins >0, c("raceid2", "votes", 
                                                                    "districtwide", "ninc",
                                                                    "nminor","nwins", "ncand",
                                                                    "nrealcand")], 
                   by = c("raceid2"), suffixes = c(".cand", ".race"))

votes.tmp$vote_share <- votes.tmp$votes.cand / votes.tmp$votes.race
votes.tmp$vote_share[is.na(votes.tmp$vote_share)] <- 0
plotdf2 <- as.data.table(votes.tmp)[, list(cand = .N, 
                                           distid = distid[1],
                                           year = year[1],
                                           winners = sum(winner),
                                           votescast = sum(votes.cand),
                                           winshare = sum(vote_share[winner ==1]),
                                           winmargin = sum(vote_share[winner == 1]) - sum(vote_share[winner == 0]),
                                           winmargin2 = mean(vote_share[winner==1]) - mean(vote_share[winner == 0])), 
                                    by = c("raceid2")]
plotdf2$winmargin3 <- plotdf2$winshare - (1/plotdf2$cand * plotdf2$winners)
plotdf2$winmargin3[plotdf2$cand == plotdf2$winners] <- .5

plotdf2$closeRace <- 0
plotdf2$closeRace[plotdf2$winmargin2 < .15] <- 1

errors <- subset(plotdf2, winmargin < 0)

plot.tmp <- ddply(plotdf2, .(distid, year), summarise, 
                  races = length(distid), 
                  closeRaces = sum(closeRace))


dist_turn <- merge(dist_turn, plot.tmp, all.x=TRUE)
rm(plot.tmp, plotdf2, votes.tmp, cand.tmp)

dist_turn$CLOSE <- factor(ifelse(dist_turn$closeRaces >0, "Competitive", "Not Competitive"))

source("data/cleanandprep_DPIADMIN.R")

dist_turn$DISTID <- FORMATdistid(dist_turn$distid)

dist_turn <- merge(dist_turn, ADMIN, by.x = c("DISTID", "year"), 
                   by.y =c("DISTID", "YEAR"))

dist_turn$teachShareofVoters <- round(dist_turn$FTE_TEACH,0) / round(dist_turn$VAP_adj,0)
# add lagged turnout measure here too
rm(ADMIN)

#-------------------
# clean up some

dist_turn <- as.data.table(dist_turn)[, teachShareofVotersLag1:= lg(teachShareofVoters), 
                                       by = "distid"]
dist_turn <- as.data.table(dist_turn)[, teachShareofVotersLag2:= lg2(teachShareofVoters), 
                                       by = "distid"]
dist_turn <- as.data.frame(dist_turn)


#---------- 
# Competitiveness

cand.tmp <- dat[dat$candidateid!=99 & dat$electiontype==1, ]
votes.tmp <- merge(cand.tmp, 
                   as.data.frame(races)[races$nwins >0, 
                                        c("raceid2", "votes", "districtwide", "ninc",
                                          "nminor","nwins", "ncand", "nrealcand")], 
                   by = c("raceid2"), suffixes = c(".cand", ".race"))

votes.tmp$vote_share <- votes.tmp$votes.cand / votes.tmp$votes.race
votes.tmp$vote_share[is.na(votes.tmp$vote_share)] <- 0
votes.tmp$hareQuota <- votes.tmp$votes.race / (votes.tmp$nwins + 1)

plotdf2 <- as.data.table(votes.tmp)[, list(cand = length(winner), 
                                           distid = distid[1],
                                           year = year[1],
                                           winners = sum(winner),
                                           votescast = sum(votes.cand, na.rm=TRUE),
                                           minWinVotes = min(votes.cand[winner == 1], na.rm=TRUE),
                                           maxLoseVotes = max(votes.cand[winner == 0], na.rm=TRUE),
                                           winnerVotes = sum(votes.cand[winner == 1], na.rm=TRUE),
                                           winshare = sum(vote_share[winner ==1], na.rm=TRUE),
                                           totalvoteshare = sum(vote_share, na.rm=TRUE), 
                                           hareQuotaDeltaWinners = mean(votes.cand[winner ==1] - hareQuota[winner==1])),
                                     by = c("raceid2")]

plotdf2$minWinVotes[!is.finite(plotdf2$minWinVotes)] <- 0
plotdf2$maxLoseVotes[!is.finite(plotdf2$maxLoseVotes)] <- 0
plotdf2$voteMargin <- plotdf2$minWinVotes - plotdf2$maxLoseVotes
plotdf2$blaisLago <- 100 * (plotdf2$voteMargin / plotdf2$votescast / plotdf2$winners)
plotdf2$hareQuota <- plotdf2$votescast / (plotdf2$winners + 1)
plotdf2$hareQuotaDelta2 <- plotdf2$winnerVotes - (plotdf2$hareQuota * plotdf2$winners)

plotdf2$closeRace <- 0
plotdf2$closeRace[plotdf2$blaisLago < 
                    quantile(plotdf2$blaisLago[plotdf2$blaisLago >0], 
                             breaks = c(0.25), na.rm=TRUE)] <- 1

errors <- subset(plotdf2, blaisLago < 0)

plot.tmp <- ddply(plotdf2, .(distid, year), summarise, 
                  races = length(distid), 
                  minBlaisLago = min(blaisLago, na.rm=TRUE), 
                  avgBlaisLago = mean(blaisLago, na.rm=TRUE),
                  minHareQuotaDelta = min(hareQuotaDelta2, na.rm=TRUE),
                  avgHareQuotaDelta = mean(hareQuotaDelta2, na.rm=TRUE),
                  closeRaces = sum(closeRace))

plot.tmp$minBlaisLago[!is.finite(plot.tmp$minBlaisLago)] <- 100
plot.tmp$avgBlaisLago[!is.finite(plot.tmp$avgBlaisLago)] <- 100
plot.tmp$minHareQuotaDelta[!is.finite(plot.tmp$minHareQuotaDelta)] <- NA
plot.tmp$avgHareQuotaDelta[!is.finite(plot.tmp$avgHareQuotaDelta)] <- NA
dist_turn <- merge(dist_turn, plot.tmp, all.x=TRUE)
rm(plot.tmp, plotdf2, votes.tmp, cand.tmp)

dist_turn$CLOSE <- factor(ifelse(dist_turn$closeRaces >0, "Competitive", "Not Competitive"))
dist_turn$median_incomeLOG <- log(dist_turn$median_income)
dist_turn$VAP_adjLOG <- log(dist_turn$VAP_adj)