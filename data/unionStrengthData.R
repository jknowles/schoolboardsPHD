## Union strength

wercDat <- read.csv("../Data/WERCdata/WERC Election Data/WERC_Results.csv")


teachContract <- read.csv("../Data/contractChoices/teachcontract.csv")


wercDat$notes <- NULL
wercDat <- na.omit(wercDat)

wercDat$turnout <- wercDat$votes / wercDat$eligiblevoters

wercDat$margin1 <- wercDat$yes_union / wercDat$votes
wercDat$margin2 <- wercDat$yes_union / wercDat$eligiblevoters

wercDat$stafftype <- as.character(wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "secretaries", "clerical", 
                            wercDat$stafftype)

wercDat$stafftype <- ifelse(wercDat$stafftype == "building", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "electricians", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "custodial", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "plumbers", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "carpenters", "maintenance", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "subteachs", "subteachers", 
                            wercDat$stafftype)
wercDat$stafftype <- ifelse(wercDat$stafftype == "subteachs", "subteachers", 
                            wercDat$stafftype)


## Roll it up
library(plyr)




