## Union strength

wercDat <- read.csv("../Data/WERCdata/WERC Election Data/WERC_Results.csv")


teachContract <- read.csv("../Data/contractChoices/teachcontract.csv")


wercDat$notes <- NULL
wercDat <- na.omit(wercDat)

wercDat$turnout <- wercDat$votes / wercDat$eligiblevoters

wercDat$stafftype <- as.character(wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "secretaries", "clerical", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "building", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "electricians", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "custodial", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "engineer", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "transit", "bus", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "plumbers", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "carpenters", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "subteachs", "subteachers", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "subteachers", "subteachers", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "substitute", "subteachers", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "paraprof", "support", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "security", "support", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "profess", "support", 
                            wercDat$stafftype)

wercDat$abst_union <- wercDat$eligiblevoters - wercDat$votes

wercDat$margin1 <- wercDat$yes_union / wercDat$votes
wercDat$margin2 <- wercDat$yes_union / wercDat$eligiblevoters

wercDat$win <- ifelse(wercDat$margin2 > 0.5, 1, 0)


## Roll it up
library(plyr)

wercDatTeachers <- ddply(wercDat[wercDat$stafftype == "teachers",], .(distid), summarise, 
                        eligvoters = mean(eligiblevoters), 
                        voters = mean(votes),
                        turnout_overall = sum(votes) / sum(eligiblevoters),
                        tries = length(distid), 
                        wins = sum(win),
                        loss = length(distid) - sum(win),
                        yes_votes_tot = sum(yes_union), 
                        no_votes_tot = sum(no_union), 
                        abst_votes_tot = sum(abst_union), 
                        yes_votes_avg = weighted.mean(yes_union, eligiblevoters), 
                        no_votes_avg = weighted.mean(no_union, eligiblevoters), 
                        abst_votes_avg = weighted.mean(abst_union, eligiblevoters),
                        best_margin = max(margin2), 
                        worst_margin = min(margin2))


wercDatALL <- ddply(wercDat, .(distid), summarise, 
                    eligvoters = mean(eligiblevoters), 
                    voters = mean(votes),
                    turnout_overall = sum(votes) / sum(eligiblevoters), 
                    tries = length(distid), 
                    wins = sum(win),
                    loss = length(distid) - sum(win),
                    yes_votes_tot = sum(yes_union), 
                    no_votes_tot = sum(no_union), 
                    abst_votes_tot = sum(abst_union), 
                    yes_votes_avg = weighted.mean(yes_union, eligiblevoters), 
                    no_votes_avg = weighted.mean(no_union, eligiblevoters), 
                    abst_votes_avg = weighted.mean(abst_union, eligiblevoters),
                    best_margin = max(margin2), 
                    worst_margin = min(margin2))

save(wercDatALL, wercDatTeachers, file = "data/cache/WERC.rda")
