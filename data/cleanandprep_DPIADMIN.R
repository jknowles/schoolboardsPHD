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

#Patch MPS data
if(histEnroll$TOT_COUNT[histEnroll$YEAR == 2008 & histEnroll$DISTID == 3619] > 170000){
  histEnroll$TOT_COUNT[histEnroll$YEAR == 2008] <- histEnroll$TOT_COUNT[histEnroll$YEAR == 2008] /2
  histEnroll$MAL_COUNT[histEnroll$YEAR == 2008] <- histEnroll$MAL_COUNT[histEnroll$YEAR == 2008] /2
  histEnroll$FEM_COUNT[histEnroll$YEAR == 2008] <- histEnroll$FEM_COUNT[histEnroll$YEAR == 2008] /2
}

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

histEnroll <- histEnroll[order(histEnroll$ADW_KEY, histEnroll$YEAR),]
lg  <- function(x) c(NA, x[1:length(x)-1])
lg2 <- function(x) c(NA, NA, x[2:length(x) -2])
histEnroll <- as.data.table(histEnroll)[, enrollLag:= lg(TOT_COUNT), by = "ADW_KEY"]
histEnroll$enrollDelta <- histEnroll$TOT_COUNT - histEnroll$enrollLag
histEnroll <- as.data.table(histEnroll)[, enrollLagPVT:= lg(TOTAL_COUNT_PVT), by = "ADW_KEY"]
histEnroll$enrollDeltaPvt <- histEnroll$TOTAL_COUNT_PVT - histEnroll$enrollLagPVT


# Interpolate enrollment
for(i in unique(histEnroll$DISTID)){
  histEnroll$TOT_COUNT[histEnroll$YEAR == 2012 & histEnroll$DISTID == i] <- 
    (histEnroll$TOT_COUNT[histEnroll$YEAR == 2011 & histEnroll$DISTID == i] + 
        mean(histEnroll$enrollDelta[(histEnroll$YEAR > 2000 & histEnroll$YEAR < 2012) & histEnroll$DISTID == i], na.rm=TRUE))
  histEnroll$TOTAL_COUNT_PVT[histEnroll$YEAR == 2012 & histEnroll$DISTID == i] <- 
    (histEnroll$TOTAL_COUNT_PVT[histEnroll$YEAR == 2011 & histEnroll$DISTID == i] + 
       mean(histEnroll$enrollDeltaPvt[(histEnroll$YEAR > 2000 & histEnroll$YEAR < 2012) & histEnroll$TOTAL_COUNT_PVT > 1 &  histEnroll$DISTID == i], na.rm=TRUE))
}

histEnroll$enrollDeltaPub <- histEnroll$enrollDelta
histEnroll$enrollDelta <- NULL
histEnroll$enrollLag <- NULL
histEnroll$enrollDeltaPvt <- histEnroll$enrollDeltaPvt
histEnroll$enrollLagPVT <- NULL
histEnroll$TOT_COUNT <- round(histEnroll$TOT_COUNT)
histEnroll$TOTAL_COUNT_PVT <- round(histEnroll$TOTAL_COUNT_PVT)

NEWSUP <- SupTurnover[, c("ADW_KEY", "YEAR", "CHANGE_IND1", 
                          "CHANGE_IND2", "LocExp", "NSups")]

names(NEWSUP) <- c("ADW_KEY", "YEAR", "NEW_SUP", 
                   "SUP_TURNOVER_PRIOR_YEAR", "SUP_EXPERIENCE", "SUP_COUNT")
rm(SupTurnover)
Staffing$ADMIN_SHARE <- Staffing$SALARY_TOTAL_ADMIN / Staffing$SALARY_TOTAL_ALL
Staffing$TEACH_SHARE <- Staffing$SALARY_TOTAL_TEACH / Staffing$SALARY_TOTAL_ALL


OverAmounts$refInPlace <- apply(OverAmounts[, 3:8], 1, 
                                function(x) ifelse(any(x > 0), 1, 0))

OverAmounts <- OverAmounts[, c(1, 2, 9)]

load("data/cache/overrideRefs.rda")
# rm(ReferendaVotes)

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


ADMIN <- merge(Staffing, NEWSUP, by = c("ADW_KEY", "YEAR"), all.x = TRUE)
ADMIN <- merge(ADMIN, histEnroll, by = c("ADW_KEY", "YEAR", "SCHOOL_YEAR", "DISTID"), 
               all.x=TRUE)
rm(NEWSUP, histEnroll, Staffing)
ADMIN <- merge(ADMIN, refIndicators, by = c("YEAR", "DISTID"), 
               all.x=TRUE)
rm(refIndicators, keepVars, keys)

# Clean vars

ADMIN$debtPass <- ifelse(ADMIN$debtPass >= 1, 1, 0)
ADMIN$debtQues <- ifelse(ADMIN$debtQues >= 1, 1, 0)
ADMIN$overridePass <- ifelse(ADMIN$overridePass >= 1, 1, 0)
ADMIN$overrideQues <- ifelse(ADMIN$overrideQues >= 1, 1, 0)
# Calculate override failure
ADMIN$overrideFail <- ifelse(ADMIN$overrideQues > 0 & ADMIN$overridePass < 1, 1, 0)
ADMIN$debtFail <- ifelse(ADMIN$debtQues > 0 & ADMIN$debtPass < 1, 1, 0)
ADMIN$elecFail <- ifelse(ADMIN$overrideFail > 0 | ADMIN$debtFail > 0, 1, 0)
RefIndicators$OVERRIDE_ATTEMPT_CUMUL93 <- RefIndicators$NONRECUR_ATTEMPT_CUMUL93 + 
  RefIndicators$RECUR_ATTEMPT_CUMUL93
RefIndicators$OVERRIDE_PASS_CUMUL93 <- RefIndicators$NONRECUR_PASS_CUMUL93 + 
  RefIndicators$RECUR_PASS_CUMUL93

RefIndicators <- RefIndicators[, c("DISTID", "YEAR", "SCHOOL_YEAR", 
                                   "DEBT_ATTEMPT_CUMUL93",
                                   "DEBT_PASS_CUMUL93", 
                                   "OVERRIDE_ATTEMPT_CUMUL93", 
                                   "OVERRIDE_PASS_CUMUL93")]

ADMIN <- merge(ADMIN, RefIndicators, by = c("DISTID", "YEAR", "SCHOOL_YEAR"), all.x=TRUE)
rm(RefIndicators)
ADMIN$ADW_KEY <- NULL
compCost$ADW_KEY <- NULL
compRev$ADW_KEY <- NULL
compCost$SCHID <- NULL
compRev$SCHID <- NULL
compCost$AGENCY_KEY_EDSTIX <- NULL
compRev$AGENCY_KEY_EDSTIX <- NULL
compRev$MEMBERSHIP <- NULL

compFunds <- merge(compCost, compRev, by = c("DISTID", "YEAR", "SCHOOL_YEAR"))
rm(compCost, compRev)

ADMIN <- merge(ADMIN, compFunds, by = c("DISTID", "YEAR", "SCHOOL_YEAR"), all.x=TRUE)
sparsity <- subset(sparsity, select = c("DISTID", "AREA_SQ_MILES"))

ADMIN <- merge(ADMIN, sparsity, by = c("DISTID"))

# Clean up WSAS

WSAS <- subset(WSAS, select = c("DISTID", "YEAR", "SCHOOL_YEAR", "PUPIL_TESTED_COUNT", 
                                "READ_PROFADV_PER", "MATH_PROFADV_PER", "KCE_TESTED_COUNT_M", 
                                "KCE_TESTED_COUNT_R"))

ADMIN <- merge(ADMIN, WSAS, by = c("DISTID", "YEAR", "SCHOOL_YEAR"), all.x = TRUE)

rm(WSAS, compFunds, sparsity)

zeroNA <- function(x){
  x[is.na(x)] <- 0
  return(x)
}

ADMIN[, 55] <- zeroNA(ADMIN[, 55])
ADMIN[, 56] <- zeroNA(ADMIN[, 56])
ADMIN[, 57] <- zeroNA(ADMIN[, 57])
ADMIN[, 58] <- zeroNA(ADMIN[, 58])
ADMIN$NonPublicPupilPer <- zeroNA(ADMIN$NonPublicPupilPer)


# Create some membership data

ADMIN$TEC_MEMBER <- ADMIN$TEC / ADMIN$MEMBERSHIP
ADMIN$TCEC_MEMBER <- ADMIN$TCEC / ADMIN$MEMBERSHIP
ADMIN$TDC_MEMBER <- ADMIN$TDC / ADMIN$MEMBERSHIP
ADMIN$PROPERTYTAX_REV_MEMBER <- ADMIN$PROPERTYTAX_REV / ADMIN$MEMBERSHIP
ADMIN$STATE_REV_MEMBER <- ADMIN$STATE_REV / ADMIN$MEMBERSHIP
ADMIN$FED_REV_MEMBER <- ADMIN$FED_REV / ADMIN$MEMBERSHIP
ADMIN$TOTAL_REV_MEMBER <- ADMIN$TOTAL_REV / ADMIN$MEMBERSHIP
ADMIN$STATE_REV_SHARE <- ADMIN$STATE_REV / ADMIN$TOTAL_REV
ADMIN$FED_REV_SHARE <- ADMIN$FED_REV / ADMIN$TOTAL_REV
ADMIN$PROPERTYTAX_REV_SHARE <- ADMIN$PROPERTYTAX_REV / ADMIN$TOTAL_REV


