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






