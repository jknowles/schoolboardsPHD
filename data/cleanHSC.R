#---------------
setwd("C:/Users/Jared/Dropbox/Dissertation/Data/Raw Files/HSC")


myList <- list.files()

dat <- as.data.frame(NA)
for(i in 1:length(myList)){
  dat.tmp <- read.csv(myList[i], stringsAsFactors = FALSE)
  dat.tmp$year <- 2000 + i + 1
  dat <- plyr::rbind.fill(dat.tmp, dat)
  rm(dat.tmp)
}

# drop it all out
dat <- dat[dat$school_type == "Summary",]
dat <- dat[dat$race_ethnicity == "All Groups Combined", ]
dat <- dat[dat$race_ethnicity == "All Groups Combined", ]
dat <- dat[dat$gender == "Both Groups Combined", ]
dat <- dat[dat$disability_status == "Both Groups Combined", ]
dat <- dat[dat$economic_status == "Both Groups Combined", ]
dat <- dat[dat$english_proficiency_status == "Both Groups Combined", ]


vars <- c("year", "district_number", "total_enrollment_grade_12", 
          "regular_count", "completers_combined_count",
          "total_expected_to_complete_high_school_count", 
          "regular_diplomas_percent", "combined_percent")

dat <- dat[, vars]
dat <- dat[!is.na(dat$district_number), ]

dat[, 3] <- as.numeric(dat[, 3])
dat[, 4] <- as.numeric(dat[, 4])
dat[, 5] <- as.numeric(dat[, 5])
dat[, 6] <- as.numeric(dat[, 6])
dat[, 7] <- as.numeric(dat[, 7])
dat[, 8] <- as.numeric(dat[, 8])

names(dat) <- c("year", "distid", "grade12enroll", "grade12diploma", 
                "grade12completers", "expectedGrads", "gradRate", "completerRate")
hsc <- dat
rm(dat)
save(hsc,file = "HSC.rda")


