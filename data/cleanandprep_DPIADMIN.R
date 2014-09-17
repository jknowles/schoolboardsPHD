## Clean and reshape DPI R data

load("data/cache/KnowlesDissData092014.rda")

zeroInf <- function(x){
  x[!is.finite(x)] <- 0
}


AllSalary <- AllSalary[, c(1:11)]
AdminSalary <- AdminSalary[, c(1:11)]
TeachSalary <- TeachSalary[, c(1:11)]

keys <- names(AllSalary)[1:6]

zed <- merge(AllSalary, AdminSalary, by = keys, suffixes = c("_ALL", "_ADMIN"))
names(TeachSalary)[7:11] <- paste(names(TeachSalary)[7:11], "TEACH", sep = "_")
zed <- merge(zed, TeachSalary, by = keys, suffixes = c("", "_TEACH"))

NEWSUP <- SupTurnover[, c("DISTID", "YEAR", "SCHOOL_YEAR", "CHANGE_IND_1", 
                          "CHANGE_IND_2")]

names(NEWSUP) <- c("DISTID", "YEAR", "SCHOOL_YEAR", "NEW_SUP", 
                   "SUP_TURNOVER_PRIOR_YEAR")

rm(SupTurnover)

library(eeptools)
zed$ADMIN_SHARE <- zed$SALARY_TOTAL_ADMIN / zed$SALARY_TOTAL_ALL
zed$TEACH_SHARE <- zed$SALARY_TOTAL_TEACH / zed$SALARY_TOTAL_ALL
qplot(factor(YEAR), ADMIN_SHARE, data = zed, geom = 'boxplot')
qplot(factor(YEAR), TEACH_SHARE, data = zed, geom = 'boxplot')



