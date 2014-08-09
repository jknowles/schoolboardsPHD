################################################################################
# Collapse datasets
# Combine them
################################################################################

library(data.table)

#source("data/dataAssemble.R")
#load("data/cache/VotingPopulation.rda")

VAP_dist <- as.data.frame(VAP_dist)
dvp$totpop <- NULL

MACROpart <- merge(VAP_dist, dvp, by=c("distid", "year"))

rm(dvp, VAP_dist, cw, vaplong, vptemp)


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

FINANCE <- FINANCE[, c(1:93, 110:263)]
FULLDAT <- merge(MACROpart, FINANCE, by = c("distid", "year"))


FULLDAT$sample <- 0
FULLDAT$sample[FULLDAT$distid %in% unique(SBELEC$distid)] <- 1


SBELEC <- merge(SBELEC, MACROpart, by = c("distid", "year"), all.x=TRUE)
rm(MACROpart)

SBELEC <- merge(SBELEC, FINANCE, by = c("distid", "year"), all.x=TRUE)
rm(FINANCE, dat, metadata)

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

############################################################
# District administrators
# ############################################################
# # 
# da0212<-read.csv('cache/districtadmin0211.csv',colClasses='character')
# da0212[,1]<-as.numeric(da0212[,1])
# da0212[,2]<-as.factor(da0212[,2])
# da0212[,3]<-as.factor(da0212[,3])
# da0212[,31]<-as.factor(da0212[,31])
# 
# da0212$district<-as.character(da0212$district)
# da0212$district<-as.numeric(da0212$district)
# da0212$year<-as.character(da0212$year)
# da0212$year<-as.numeric(da0212$year)
# 
# sub<-subset(da0212,select=c('year','district','contact_name','district_name'))
# 
# admintenure<-ddply(sub,.(contact_name,district,district_name),summarise,start=min(year,na.rm=T),
#                    end=max(year,na.rm=T),.progress='text')
# 
# admintenure$turnover <- 0 
# admintenure$turnover[admintenure$start > 2002] <- 1
# 
# adminsperdistrict<-ddply(admintenure,.(district),summarise,change=length(start))
# 



rm(da0212,sub)