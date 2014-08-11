# Load packages

# libraries
# library(eeptools)
# library(ROCR)
# library(coefplot)
# library(eeptools); library(gridExtra)
# library(ROCR); library(lme4)
# library(arm)
# library(coefplot)
# library(scales); 
# library(stargazer)
apsrtableSummary.rms <- function(x) {
  s <- summary.lm(x)
  newCoef <- coef(s)
  ## which columns have z scores? (two of them in robust case)
  zcols <- grep("value",colnames(newCoef))
  newCoef[,zcols] <- pt(abs(newCoef[,zcols]),df=s$df[2], lower.tail=FALSE)
  colnames(newCoef)[zcols] <- "Pr(z)"
  s$coefficients <- newCoef
  ## put the robust se in $se so that notefunction works automatically
  ## the se checker will overwrite [,4] with pt, but this doesn't matter
  ## because the last column Pr(z) is used by apsrstars() anyway
  ## and the se are pulled from $se.
  if("orig.var"%in% objects(x)==TRUE) {
    s$se <- sqrt(diag(x$var))
  }
  return(s)
}

# apsrtableSummary.gls <- function(x) {
#   s <- cbind(coef(x),sqrt(diag(x$varBeta)))
#   newCoef <- coef(s)
#   ## which columns have z scores? (two of them in robust case)
#   zcols <- grep("value",colnames(newCoef))
#   newCoef[,zcols] <- pt(abs(newCoef[,zcols]),df=s$df, lower.tail=FALSE)
#   colnames(newCoef)[zcols] <- "Pr(z)"
#   s$coefficients <- newCoef
#   ## put the robust se in $se so that notefunction works automatically
#   ## the se checker will overwrite [,4] with pt, but this doesn't matter
#   ## because the last column Pr(z) is used by apsrstars() anyway
#   ## and the se are pulled from $se.
#   if("orig.var"%in% objects(x)==TRUE) {
#     s$se <- sqrt(diag(x$var))
#   }
#   return(s)
# }

# s<-cbind(coef(gls1),sqrt(diag(gls1$varBeta)))
# 
# 
# 
# objects(apsrtableSummary(robust1a))
# 
# summary.lm(robust1a)
# apsrtableSummary.
# 
# apsrtable(robust1a,robust2a,se=c("robust"))
# apsrtable(robust1a)
# 
# 
# subst_eff_plot<-function(x){
#   c<-coef(x)
#   mod_mean<-apply(x$x,2,mean)
#   mod_sd<-apply(x$x,2,sd)
#   sig<-as.data.frame(confint.default(x))
#   sig$sig<-"no"
#   sig$sig[sign(sig[,1])==sign(sig[,2])]<-"yes"
#   effect<-data.frame(var=row.names(sig),mean_eff=c*mod_mean,
#                      low_eff=c*mod_mean-c*mod_sd,
#                      high_eff=c*mod_mean+c*mod_sd,sig=sig[,3])
#   effect<-subset(effect,var!="Intercept")
#   
#   ggplot(effect,(aes(x=var,y=mean_eff,ymin=low_eff,ymax=high_eff,
#                      color=sig)))+
#     geom_pointrange()+theme_dpi()+theme(axis.text.x=element_text(angle=30,size=8))+
#     geom_hline(yintercept=-sd(x$y))+geom_hline(yintercept=sd(x$y))
#   
# }

# 
# # Plot regression effects
# 
# c<-coef(robust1)
# mod_mean<-apply(robust1$x,2,mean)
# mod_sd<-apply(robust1$x,2,sd)
# sig<-as.data.frame(confint.default(robust1))
# sig$sig<-"no"
# sig$sig[sign(sig[,1])==sign(sig[,2])]<-"yes"
# 
# effect<-data.frame(mean_eff=c*mod_mean,low_eff=c*mod_mean-c*mod_sd,
#                    high_eff=c*mod_mean+c*mod_sd,sig=sig[,3])
# 
# effect<-subset(effect,row.names(effect)!="Intercept")
# 
# ggplot(effect,(aes(x=row.names(effect),y=mean_eff,ymin=low_eff,ymax=high_eff,
#                    color=sig)))+
#   geom_pointrange()+theme_dpi()+theme(axis.text.x=element_text(angle=30,size=8))+
#   geom_hline(yintercept=-6.266)+geom_hline(yintercept=6.266)
