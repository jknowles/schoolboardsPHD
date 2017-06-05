# Data export for Stefane Lavertu election project Ohio State
# 2017-06-02
# Jared E. Knowles

source("data/dataAssemble.R")

library(dplyr)
races <- as.data.frame(races)
cand <- as.data.frame(cand)
results <- as.data.frame(dat)
out <- left_join(results, races[, c("raceid2", "ncand", 
                                    "nrealcand", "nwins", 
                                    "ninc", "nincDef", 
                                    "nminor", "votes",  
                                    "scatterVotes", "nincDefInd")], 
                 by = "raceid2")
out$candidate_votes <- out$votes.x; out$votes.x <- NULL
out$total_votes <- out$votes.y; out$votes.y <- NULL


load("data/cache/fullDataSep2014.rda")
distAttr <- tmp[, c("distid", "year", "DISTRICT_NAME", 
                    "SCHOOL_YEAR", "FULL_NCES_CODE", 
                    "COUNTY", "CESA")]
rm(tmp)

# impute distattribute backward and forward
tmp <- distAttr[distAttr$year == 2002,]
tmp$year <- 2001
tmp$SCHOOL_YEAR <- "2000-01"
distAttr <- bind_rows(tmp, distAttr)
tmp <- distAttr[distAttr$year == 2001,]
tmp$year <- 2000
tmp$SCHOOL_YEAR <- "1999-00"
distAttr <- bind_rows(tmp, distAttr)
tmp <- distAttr[distAttr$year == 2012,]
tmp$year <- 2013
tmp$SCHOOL_YEAR <- "2012-13"
distAttr <- bind_rows(distAttr, tmp)

out <- merge(out, distAttr, by = c("distid", "year"), all.x=TRUE)
out <- out %>% select(distid, year, DISTRICT_NAME, SCHOOL_YEAR, FULL_NCES_CODE, 
                      COUNTY, everything()) %>% as.data.frame()
write.csv(out, file = "Wisconsin_SB_election_export_06042017.csv", 
          row.names = FALSE)

