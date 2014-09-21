################################################################################
# Collapse datasets
# Combine them
################################################################################

#source("data/dataAssemble.R")
#load("data/cache/VotingPopulation.rda")
load("data/cache/DataMergeVAP.rda")
VAP_dist <- as.data.frame(VAP_dist)
dvp$totpop <- NULL
MACROpart <- merge(VAP_dist, dvp, by=c("distid", "year"))
rm(VAP_dist, dvp)

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

FINANCE <- FINANCE[, unique(c("distid", "year", "fte_teachers", "ref_attp_flag", "attempts", 
                      "cum_attptsD", "enrollment", "white_count", "TotalPopulation", 
                      "PopWhiteAlone", "PCI", "total_levy", "genaid", "per65o",
                      "levy_chg", "Population18O", "ref_share", "median_income",
                      "PerBachelorOrAbove", "OOH_share", "millrate", "locale2", 
                      "balance_member_lag", "member_lag", "millrate_lag", "overlevy_ind_lag", 
                      "underlevy_ind_lag", "millrate_delta", "member_delta", 
                      "avg_salary", "average_fringe", "avg_total_exp", 
                      "total_attempts", "member", "econ_disadv_per",  "teacherpupil_ratio", 
                      "eqv_member"))]


FINANCE$per_white_students <- FINANCE$white_count / FINANCE$enrollment
FINANCE$per_white_all <- FINANCE$PopWhiteAlone / FINANCE$TotalPopulation

FULLDAT <- merge(MACROpart, FINANCE, by = c("distid", "year"))


FULLDAT$sample <- 0
FULLDAT$sample[FULLDAT$distid %in% unique(SBELEC$distid)] <- 1


SBELEC <- merge(SBELEC, MACROpart, by = c("distid", "year"), all.x=TRUE)
rm(MACROpart)

presTurn$presTwoPartyVote <- presTurn$presDemVotes + presTurn$presRepVotes
presTurn$presTwoPartyShareDem <- presTurn$presDemVotes / presTurn$presTwoPartyVote

govTurn$govTwoPartyVote <- govTurn$govDemVotes + govTurn$govRepVotes
govTurn$govTwoPartyShareDem <- govTurn$govDemVotes / govTurn$govTwoPartyVote


# turnout over the prior presidential election
SBELEC <- merge(SBELEC, presTurn, by = c("distid", "year"), all.x=TRUE)
SBELEC <- merge(SBELEC, govTurn, by = c("distid", "year"), all.x=TRUE)

SBELEC$fallTurnout <- (SBELEC$topGovTurnoutPrior + SBELEC$topPresTurnoutPrior) / 2
SBELEC$fallTwoPartyShareDem <- (SBELEC$govTwoPartyShareDem + SBELEC$presTwoPartyShareDem) /2

SBELEC <- merge(SBELEC, FINANCE, by = c("distid", "year"), all.x=TRUE)
rm(FINANCE, metadata)

#distyear <- as.data.frame(distyear)


asinh_trans <- function(){
  trans_new(name = 'asinh', transform = function(x) asinh(x * 2), 
            inverse = function(x) sinh(x)/2)
}

distnames <- read.csv("data/cache/districtadmin0211.csv")
distnames <- distnames[, c("district", "district_name", "legal_name")]
distnames <- distnames[!duplicated(distnames),]
FULLDAT <- merge(FULLDAT, distnames, by.x = "distid", by.y = "district")
rm(distnames)



SBELEC$contested <- ifelse(SBELEC$candidates > SBELEC$winners, 1, 0)
SBELEC$contested2 <- ifelse((SBELEC$candidates - SBELEC$minorcand) > SBELEC$winners, 1, 0)
# Ratio
SBELEC$contested3 <-  (SBELEC$candidates - SBELEC$minorcand) / SBELEC$winners
# Check data issue with - values
SBELEC$contested3 <- ifelse(SBELEC$contested3 > -.01, SBELEC$contested3, 1)
SBELEC$contested3 <- ifelse(is.finite(SBELEC$contested3), SBELEC$contested3, 0)



# Walker recall
load("data/cache/WalkerRecall.rda")


distvotes12r <- merge(distvotes12r, SBELEC[, c(1,2, 14)], 
                      by = c("distid", "year"), all.x = TRUE)

distvotes12r <- distvotes12r[, -2]
distvotes12r$GovTwoPartyShareDem <- distvotes12r$GOVDEM / (distvotes12r$GOVDEM + 
                                                             distvotes12r$GOVREP)

distvotes12r$GovTurnout <- distvotes12r$RECTOT / distvotes12r$VAP_adj 


names(distvotes12r) <- paste(names(distvotes12r), "recall", sep ="_")

SBELEC <- merge(SBELEC, distvotes12r, by.x = "distid", 
                   by.y = "distid_recall")


rm(distvotes12r)

SBELEC$primary2 <- ifelse(SBELEC$primary == "None", "None", "Primary")
SBELEC$politicaldivide <- abs(SBELEC$toprepshare - .5)
SBELEC$log_politicaldivide <- log(SBELEC$politicaldivide)

SBELEC$RecallPolarization <- abs(SBELEC$GovTwoPartyShareDem_recall - 0.5)

asinh_trans <- function(){
  trans_new(name = 'asinh', transform = function(x) asinh(x * 2), 
            inverse = function(x) sinh(x)/2)
}

####################
# WTF
###################

load("data/cache/DataMergeVAP.rda")
load("data/cache/AnalyticalSampleFeb2014.rda")

distAttr <- newdat[, c("distid", "year", "fte_teachers", "ref_attp_flag", "attempts", 
                       "cum_attptsD", "enrollment", "white_count", "TotalPopulation", 
                       "PopWhiteAlone", "PCI", "total_levy", "genaid", "per65o", 
                       "PerBachelorOrAbove", "OOH_share", "millrate", 
                       "cum_attptsD", "millrate", "overlevy_ind_lag", 
                       "perwhite", "levy_chg", "ref_share", "balance_member_lag", 
                       "avg_salary", "average_fringe", "avg_total_exp", 
                       "dv_r", "member_delta", "total_attempts", 
                       "median_income", "locale2", "member_lag", 
                       "millrate_lag", "overlevy_ind_lag", 
                       "underlevy_ind_lag", "millrate_delta", "total_attempts")]



#winshare_lag1, attemptsD_lag1

rm(newdat)

distAttr$per_white_students <- distAttr$white_count / distAttr$enrollment
distAttr$per_white_all <- distAttr$PopWhiteAlone / distAttr$TotalPopulation
distAttr$white_count <- NULL
distAttr$PopWhiteAlone <- NULL
distAttr$TotalPopulation <- NULL

iNum <- function(x) prettyNum(x, big.mark = ",", digits = 3)
iPer <- function(x){paste0(prettyNum(x, big.mark = ",", digits = 1),"\\%")}

## Races
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

dist_turn <- merge(dist_turn, distAttr, by = c("year", "distid"))
rm(distAttr, newdat)
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
dist_turn$teachShareofVoters <- round(dist_turn$fte_teachers,0) / dist_turn$votersLag2
dist_turn$teachShareofVoters[!is.finite(dist_turn$teachShareofVoters)] <- 0
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
dist_turn$contest <- "Uncontested"
dist_turn$contest[dist_turn$nrealcand > dist_turn$nwins & dist_turn$ninc > 0] <- "Incumbent Contested"
dist_turn$contest[dist_turn$nrealcand > dist_turn$nwins & dist_turn$ninc ==0] <- "Open Contested"


SBELEC$treatment <- 0
SBELEC$treatment[SBELEC$year == 2011] <- 1
SBELEC$treatment[SBELEC$year == 2012] <- 1

# Create lags
# SBELEC$total_wins <- SBELEC$wins; SBELEC$wins <- NULL

# SBELEC$total_attempts <- ifelse(is.na(SBELEC$total_attempts), 0, 
#                                 SBELEC$total_attempts)

# 
# lagvars <- c("contested", "contested2", "contested3", "primary2", "totalvotes", 
#              "VAP", "attemptsD", "total_attempts", "total_wins")
# 
# SBELEC <- lag_data(SBELEC, group = "distid", time = "year", periods = c(1), 
#                    values = lagvars)
# 
# 
# SBELEC$time <- SBELEC$year - 2010
# SBELEC$winshare.lag1 <- SBELEC$total_wins.lag1/ SBELEC$total_attempts.lag1
# 
# SBELEC$winshare.lag1 <- ifelse(is.na(SBELEC$winshare.lag1), 0, SBELEC$winshare.lag1)


SBELEC$fyear <- factor(SBELEC$year)


lg  <- function(x) c(NA, x[1:length(x)-1])
lg2 <- function(x) c(NA, NA, x[2:length(x) -2])

SBELEC$year <- as.numeric(SBELEC$year)
SBELEC.tmp <- SBELEC[, c("distid", "year", "fallTurnout", "fallTwoPartyShareDem", 
                         "contested", "contested2", "contested3", "primary2")]

SBELEC.tmp <- SBELEC.tmp[order(SBELEC.tmp$distid, SBELEC.tmp$year),]

SBELEC.tmp <- as.data.table(SBELEC.tmp)[, fallTurnoutLag1:= lg(fallTurnout), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, fallTurnoutLag2:= lg2(fallTurnout), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, fallTwoPartyShareDemLag1:= lg(fallTwoPartyShareDem), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, fallTwoPartyShareDemLag2:= lg2(fallTwoPartyShareDem), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contestedLag1:= lg(contested), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contestedLag2:= lg2(contested), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contested2Lag1:= lg(contested2), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contested2Lag2:= lg2(contested2), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contested3Lag1:= lg(contested3), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, contested3Lag2:= lg2(contested3), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, primary2Lag1:= lg(primary2), by = "distid"]
SBELEC.tmp <- as.data.table(SBELEC.tmp)[, primary2Lag2:= lg2(primary2), by = "distid"]
SBELEC.tmp$fallTurnout <- NULL
SBELEC.tmp$fallTwoPartyShareDem <- NULL
SBELEC.tmp$contested <- NULL
SBELEC.tmp$contested2 <- NULL
SBELEC.tmp$contested3 <- NULL
SBELEC.tmp$primary2 <- NULL
SBELEC.tmp <- as.data.frame(SBELEC.tmp)
SBELEC <- merge(SBELEC, SBELEC.tmp)
rm(SBELEC.tmp)
