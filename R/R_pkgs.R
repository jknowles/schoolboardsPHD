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
# apsrtableSummary.rms <- function(x) {
#   s <- summary.lm(x)
#   newCoef <- coef(s)
#   ## which columns have z scores? (two of them in robust case)
#   zcols <- grep("value",colnames(newCoef))
#   newCoef[,zcols] <- pt(abs(newCoef[,zcols]),df=s$df[2], lower.tail=FALSE)
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

glmCorrHeatMap <- function(mod){
  # find numeric data
  require(reshape2)
  require(ggplot2)
  dat <- mod$model
  nums <- sapply(dat, is.numeric)
  cormat <- melt(round(cor(dat[, nums], use = "pairwise"), 3))
  cormat$value2 <- cut(cormat$value, 
                       breaks=c(-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1), 
                       include.lowest=TRUE, 
                       label=c("(-0.75,-1)","(-0.5,-0.75)","(-0.25,-0.5)","(0,-0.25)",
                               "(0,0.25)","(0.25,0.5)","(0.5,0.75)","(0.75,1)")) 
  plot <- qplot(x=Var1, y=Var2, data=cormat, fill=value2, geom="tile", color = I("gray40")) + 
    scale_fill_brewer(palette = "RdYlGn",name="Correlation", 
                      breaks = levels(cormat$value2), drop =FALSE)+
    geom_text(aes(label = value)) + labs(x = "", y = "") +
    theme(panel.background=element_blank(),
          panel.grid.minor=element_blank(),
          panel.grid.major=element_blank(),
          axis.text.x = element_text(angle = -90, hjust = 0), 
          axis.text = element_text(colour = "black"))
  print(plot)
}

get_CL_vcov<-function(model, cluster){
  # cluster is an actual vector of clusters from data passed to model
  # from: http://rforpublichealth.blogspot.com/2014/10/easy-clustered-standard-errors-in-r.html
  require(sandwich, quietly = TRUE)
  require(lmtest, quietly = TRUE)
  
  #calculate degree of freedom adjustment
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- model$rank
  dfc <- (M/(M-1))*((N-1)/(N-K))
  
  #calculate the uj's
  uj  <- apply(estfun(model),2, function(x) tapply(x, cluster, sum))
  
  #use sandwich to get the var-covar matrix
  vcovCL <- dfc*sandwich(model, meat=crossprod(uj)/N)
  return(vcovCL)
}


confusionMatrixTmp <- function(data, model) {
  prediction <- ifelse(predict(model, data, type='response') > 0.5, TRUE, FALSE)
  if(class(model)[1] %in% c("lmerMod", "glmerMod")){
    confusion  <- table(prediction, as.logical(model@frame[, 1]))
  } else{
    confusion  <- table(prediction, as.logical(model$y))
  }
  confusion  <-   confusion  <- cbind(confusion, 
                                      c(1 - confusion[1,1]/(confusion[1,1]+ 
                                                              confusion[2,1]), 
                                        1 - confusion[2,2]/(confusion[2,2]+confusion[1,2])))
  confusion  <- as.data.frame(confusion)
  names(confusion) <- c('FALSE', 'TRUE', 'class.error')
  confusion
}

makeROCdf <- function(model, name){
  predicted <- predict(model)
  if(class(model)[1] %in% c("lmerMod", "glmerMod")){
    prob <- prediction(predicted, model@frame[, 1])
  } else{
    prob <- prediction(predicted, model$model[, 1])
  }
  tprfpr <- performance(prob, "tpr", "fpr")
  tpr <- unlist(slot(tprfpr, "y.values"))
  fpr <- unlist(slot(tprfpr, "x.values"))
  roc <- data.frame(tpr, fpr)
  roc$mod <- name
  return(roc)
}

printPB <- function(pbobj, names=NULL){
  # print results of a parametric bootstrap from PBmodcomp in the pbkrtest package
  require(xtable)
  if(missing(names)){
    names <- c("model 1", "model 2")
  }
  mycap <- paste0("Parametric bootstrap specification test results using ", pbobj$samples[[1]], 
                  " simulations. Between ", names[1], " and ", names[2], ".")
  print(xtable(modTestDemog1$test, caption = mycap), include.rownames=TRUE)
}

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
