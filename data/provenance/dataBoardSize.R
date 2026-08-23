boardSize.tmp <- read.csv("data/cache/SchoolBoardRosterVerification.csv")

library(plyr)

boardSize <- ddply(boardSize.tmp, .(year, agency), summarize, 
                    servingMembers = length(last_name))

# Correction for boardSize in 2007

boardSize$servingMembers[boardSize$year == 2007] <- boardSize$servingMembers[boardSize$year == 2007] + 1

save(boardSize, file = "data/cache/boardSize.rda")
