## Clean and reshape DPI R data

load("data/cache/KnowlesDissData092014.rda")

zeroInf <- function(x){
  x[!is.finite(x)] <- 0
}



AllSalary <- AllSalary[, c(1:23)]
AdminSalary <- AdminSalary[, c(1:23)]
TeachSalary <- TeachSalary[, c(1:23)]

keys <- names(AllSalary)[1:6]

zed <- merge(AllSalary, AdminSalary, by = keys, suffixes = c("_ALL", "_ADMIN"))
names(TeachSalary)[7:23] <- paste(names(TeachSalary)[7:23], "TEACH", sep = "_")
zed <- merge(zed, TeachSalary, by = keys, suffixes = c("", "_TEACH"))


rm(AllSalary, TeachSalary, AdminSalary)

Staffing <- zed; rm(zed)

keepVars <- c("ADW_KEY", "YEAR", "SCHOOL_YEAR", "DISTID", "TOTAL_POSITIONS_ALL", 
              "TOTAL_PEOPLE_ALL", "FTE_ALL", "SALARY_TOTAL_ALL", "FRINGE_TOTAL_ALL", 
              "ADJ_MEDIAN_SALARY_ALL", "FTE_ADMIN", "SALARY_TOTAL_ADMIN", "FRINGE_TOTAL_ADMIN", 
              "ADJ_MEDIAN_SALARY_ADMIN", "MEDIAN_AGE_ADMIN", "FTE_TEACH", "SALARY_TOTAL_TEACH", 
              "FRINGE_TOTAL_TEACH", "ADJ_MEDIAN_SALARY_TEACH", "ADJ_MEDIAN_FRINGE_TEACH", 
              "ADJ_90Q_SAL_TEACH", "ADJ_10Q_SAL_TEACH", "MEDIAN_AGE_TEACH")


Staffing <- Staffing[, keepVars]

histEnroll$NonWhitePublicPupilPer <- ((histEnroll$TOT_COUNT - histEnroll$W_COUNT) / histEnroll$TOT_COUNT)*100
histEnroll$NonPublicPupilPer <- (((histEnroll$TOT_COUNT + histEnroll$TOTAL_COUNT_PVT) -histEnroll$TOT_COUNT) / (histEnroll$TOT_COUNT + histEnroll$TOTAL_COUNT_PVT))*100
histEnroll$BlackPublicPupilPer <- (histEnroll$B_COUNT / histEnroll$TOT_COUNT)
histEnroll$HispPublicPupilPer <- (histEnroll$H_COUNT / histEnroll$TOT_COUNT)
histEnroll$AsianPublicPupilPer <- (histEnroll$A_COUNT / histEnroll$TOT_COUNT)
histEnroll$AmerIndPublicPupilPer <- (histEnroll$I_COUNT / histEnroll$TOT_COUNT)

keepVars <- c("ADW_KEY", "YEAR", "SCHOOL_YEAR", "DISTID", "N_PUB_SCHLS", "N_PVT_SCHLS", 
              "TOT_COUNT", "TOTAL_COUNT_PVT", "NonWhitePublicPupilPer", 
              "NonPublicPupilPer", "BlackPublicPupilPer", "HispPublicPupilPer", 
              "AsianPublicPupilPer", "AmerIndPublicPupilPer")

histEnroll <- histEnroll[, keepVars]

histEnroll.tmp <- histEnroll[histEnroll$YEAR == 2011,]
histEnroll.tmp$YEAR <- 2012
histEnroll.tmp$SCHOOL_YEAR <- "2011-12"

histEnroll <- rbind(histEnroll, histEnroll.tmp)

rm(histEnroll.tmp)

NEWSUP <- SupTurnover[, c("DISTID", "YEAR", "SCHOOL_YEAR", "CHANGE_IND_1", 
                          "CHANGE_IND_2")]

names(NEWSUP) <- c("DISTID", "YEAR", "SCHOOL_YEAR", "NEW_SUP", 
                   "SUP_TURNOVER_PRIOR_YEAR")
rm(SupTurnover)
Staffing$ADMIN_SHARE <- Staffing$SALARY_TOTAL_ADMIN / Staffing$SALARY_TOTAL_ALL
Staffing$TEACH_SHARE <- Staffing$SALARY_TOTAL_TEACH / Staffing$SALARY_TOTAL_ALL


OverAmounts$refInPlace <- apply(OverAmounts[, 3:8], 1, 
                                function(x) ifelse(any(x > 0), 1, 0))

OverAmounts <- OverAmounts[, c(1, 2, 9)]

load("data/cache/overrideRefs.rda")
rm(ReferendaVotes)

FORMATdistid <- function(x){
  if(class(x) != "character"){
    x <- as.character(x)
  }
  nchars <- sapply(x, nchar)
  x[nchars ==3] <- paste0("0", x[nchars==3])
  x[nchars ==2] <- paste0("00", x[nchars==2])
  x[nchars ==1] <- paste0("000", x[nchars==1])
  return(x)
}

yearVotes$DISTID <- FORMATdistid(yearVotes$DISTRICT_NMBR)

refIndicators <- merge(OverAmounts, yearVotes[, -1], by.x = c("DISTID", "YEAR"), 
                       by.y = c("DISTID", "FISCAL_YEAR"), all.x=TRUE)

refIndicators[is.na(refIndicators)] <- 0

rm(OverAmounts, yearVotes)


ADMIN <- merge(Staffing, NEWSUP, by = c("DISTID", "YEAR", "SCHOOL_YEAR"), all.x = TRUE)
ADMIN <- merge(ADMIN, histEnroll, by = c("ADW_KEY", "YEAR", "SCHOOL_YEAR", "DISTID"), 
               all.x=TRUE)
rm(NEWSUP, histEnroll, Staffing)
ADMIN <- merge(ADMIN, refIndicators, by = c("YEAR", "DISTID"), 
               all.x=TRUE)
rm(refIndicators, keepVars, keys)

