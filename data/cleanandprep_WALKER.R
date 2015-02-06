
source("data/dataAssemble.R")
load("data/cache/DataMergeVAP.rda")
load("data/cache/fullDataSep2014.rda")


distAttr <- tmp[, c("distid", "year", "TotalPopulation", "NonSDMill", 
                    "AdjPopulation",
                    "PopWhiteAlone", "total_levy", "genaid", "per65o", 
                    "PerBachelorOrAbove", "OOH_share", "millrate", "median_income", 
                    "COUNTY", "CESA", "ATHLETIC_CONF_NUMBER", "eqv_member", 
                    "balance_lag", "member_datayear", "member_delta", 
                    "millrate_delta", "locale2", "member_datayear_lag", 
                    "ref_share", "member_aidyear", "total_cat_aids_member",  
                    "tax_price", "totalincome_count", "eqv_adj_tifout", 
                    "econ_disadv_per")]

distAttr$balance_member_lag <- distAttr$balance_lag / distAttr$member_datayear
distAttr$member_delta_per <- distAttr$member_delta / distAttr$member_datayear


rm(tmp)

distAttr$per_white_all <- distAttr$PopWhiteAlone / distAttr$TotalPopulation

## reshape school district by year
# How to calculate total votes in elections with multiple winners...

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
                                          "electiontype", "VAP", "VAP_adj", 
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
                   nraces = length(distid))

dist_turn$districtwide <- 1
############
# Non district-wide
############
races <- as.data.frame(races)
races.tmp <- merge(races, VAP_dist, by = c("distid", "year"))

races.tmp <- subset(races.tmp, select = c("distid", "year", "raceid2", "ncand", 
                                          "nrealcand", "nwins", "ninc", "raceid",
                                          "nminor", "votes", "districtwide", 
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
                  nraces = length(distid))

dist.tmp$districtwide <- 0

dist_turn <- rbind(dist_turn, dist.tmp)

row_counts <- ddply(dist_turn, .(distid, year), nrow)
dist_turn <- merge(dist_turn, row_counts, all.x=TRUE)
dist_turn$recs <- dist_turn$V1; dist_turn$V1 <- NULL
dist_turn1 <- dist_turn[dist_turn$recs >= 1 & dist_turn$districtwide > 0,]
dist_turn2 <- dist_turn[dist_turn$recs == 1 & dist_turn$districtwide == 0,]

dist_turn <- rbind(dist_turn1, dist_turn2)
dist_turn$recs <- NULL

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

rm(dist_turn1, dist_turn2, races.tmp, row_counts)


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

source("data/cleanandprep_DPIADMIN.R")

dist_turn$DISTID <- FORMATdistid(dist_turn$distid)

dist_turn <- merge(dist_turn, ADMIN, by.x = c("DISTID", "year"), 
                   by.y =c("DISTID", "YEAR"))

dist_turn$teachShareofVoters <- round(dist_turn$FTE_TEACH,0) / round(dist_turn$VAP_adj,0)

rm(ADMIN)


################################################################################
# Read in WERC data and clean it
################################################################################

# All WERC union certification elections as of July 2013

load("data/cache/WERC.rda")
# load("data/cache/WERC.rda")
names(wercDatTeachers) <- paste(names(wercDatTeachers), "werc", sep = "_")

dist_turn <- merge(dist_turn, wercDatTeachers, by.x = "distid", by.y = "distid_werc", 
                   all.x = TRUE)

NAzero <- function(x){
  x <- as.numeric(x)
  x[is.na(x)] <- 0 
  return(x)
}

dist_turn$WERC_elec <- ifelse(is.na(dist_turn$eligvoters_werc), 0, 1)
dist_turn$eligvoters_werc <- NAzero(dist_turn$eligvoters_werc)
dist_turn$voters_werc <- NAzero(dist_turn$voters_werc)
dist_turn$turnout_overall_werc <- NAzero(dist_turn$turnout_overall_werc)
dist_turn$tries_werc <- NAzero(dist_turn$tries_werc)
dist_turn$wins_werc <- NAzero(dist_turn$wins_werc)
dist_turn$loss_werc <- NAzero(dist_turn$loss_werc)
dist_turn$yes_votes_tot_werc <- NAzero(dist_turn$yes_votes_tot_werc)
dist_turn$no_votes_tot_werc <- NAzero(dist_turn$no_votes_tot_werc)
dist_turn$abst_votes_tot_werc <- NAzero(dist_turn$abst_votes_tot_werc)
dist_turn$yes_votes_avg_werc <- NAzero(dist_turn$yes_votes_avg_werc)
dist_turn$no_votes_avg_werc <- NAzero(dist_turn$no_votes_avg_werc)
dist_turn$abst_votes_avg_werc <- NAzero(dist_turn$abst_votes_avg_werc)
dist_turn$best_margin_werc <- NAzero(dist_turn$best_margin_werc)
dist_turn$worst_margin_werc <- NAzero(dist_turn$worst_margin_werc)



load("data/cache/WalkerRecall.rda")
# load("data/cache/WalkerRecall.rda")
## Bolt them on
distvotes12r <- distvotes12r[, -2]
distvotes12r$GovTwoPartyShareDem <- distvotes12r$GOVDEM / (distvotes12r$GOVDEM + 
                                                             distvotes12r$GOVREP)
distvotes12r$GovTwoPartyShareRep <- distvotes12r$GOVREP / (distvotes12r$GOVDEM + 
                                                             distvotes12r$GOVREP)

names(distvotes12r) <- paste(names(distvotes12r), "recall", sep ="_")

dist_turn <- merge(dist_turn, distvotes12r, by.x = "distid", 
                   by.y = "distid_recall")
dist_turn$GovTurnout_recall <- dist_turn$RECTOT_recall / dist_turn$VAP_adj 



dist_turn$ADMIN_SHARE_COMP <- (dist_turn$SALARY_TOTAL_ADMIN + dist_turn$FRINGE_TOTAL_ADMIN) / 
  (dist_turn$FRINGE_TOTAL_ALL + dist_turn$SALARY_TOTAL_ALL)
dist_turn$ADMIN_SHARE_FTE <- (dist_turn$FTE_ADMIN / dist_turn$FTE_ALL)

# habit
dist_turn$contestMinor <- 0
dist_turn$contestMinor[dist_turn$nrealcand > dist_turn$nwins] <- 1
dist_turn$contestSer <- 0
dist_turn$contestSer[(dist_turn$nrealcand - dist_turn$nminor) > dist_turn$nwins] <- 1

# log of dollar variables
dist_turn$VAP_adjLOG <- log(dist_turn$VAP_adj)
dist_turn$median_incomeLOG <- log(dist_turn$median_income) 
dist_turn$balance_member_lagLOG <- ifelse(dist_turn$balance_member_lag > 0, log(dist_turn$balance_member_lag), 0) 
dist_turn$eqv_adj_tifoutLOG <- log(dist_turn$eqv_adj_tifout) 
dist_turn$ADJ_MEDIAN_FRINGE_TEACH[dist_turn$ADJ_MEDIAN_FRINGE_TEACH == 0] <- 1
dist_turn$ADJ_MEDIAN_FRINGE_TEACHlog <- log(dist_turn$ADJ_MEDIAN_FRINGE_TEACH)
dist_turn$ADJ_MEDIAN_SALARY_TEACHlog <- log(dist_turn$ADJ_MEDIAN_SALARY_TEACH)
#TODO: Fix this
dist_turn$partyDivision <- abs(0.5 - dist_turn$fallTwoPartyShareDem)
dist_turn$overrideYesPer <- dist_turn$yesVotes / dist_turn$VAP_adj
dist_turn$incumRun <- ifelse(dist_turn$ninc > 0, 1, 0)
dist_turn$incumShare <- dist_turn$ninc / (dist_turn$nrealcand)

dist_turn$teachSalDiff <- dist_turn$ADJ_MEDIAN_SALARY_TEACHlog - 
  dist_turn$median_incomeLOG

dist_turn <- as.data.table(dist_turn)[, contestMinorLag:= lg(contestMinor), by = "distid"]
dist_turn <- as.data.table(dist_turn)[, contestSerLag:= lg(contestSer), by = "distid"]
dist_turn <- as.data.table(dist_turn)[, contestMinorLag2:= lg2(contestMinor), by = "distid"]
dist_turn <- as.data.table(dist_turn)[, contestSerLag2:= lg2(contestSer), by = "distid"]

dist_turn <- as.data.frame(dist_turn)

rm(distAttr, distvotes12r, dvp, govTurn, presTurn, wercDatALL, wercDatTeachers)
# load("../../data/cache/springElectionVotes.rda")
load("data/cache/springElectionVotes.rda")
springVotes$votesTopTicketSpring <- springVotes$VotesCast
springVotes$VotesCast <- NULL
dist_turn <- merge(dist_turn, springVotes, by = c("distid", "year"))
dist_turn$topTicketTurnoutSpring <- dist_turn$votesTopTicketSpring / dist_turn$VAP_adj
dist_turn$turnoutDiff <- dist_turn$topTicketTurnoutSpring - dist_turn$turnout

################################################################################
# Read in contract extension data
################################################################################

# cont <- read.csv("../Data/contractChoices/teachcontract.csv")
# table(cont$contract112)
# table(cont$contract1213)
# table(cont$recert)

################################################################################
# Read in achievement data
################################################################################