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

iNum <- function(x){prettyNum(as.character(x), big.mark = ",", small.mark = ".", 
                              digits = 3)}

iNum2 <- function(x){prettyNum(x, big.mark = ",", small.mark = ".", 
                              digits = 3)}
iPer <- function(x){paste0(as.character(prettyNum(x, big.mark = ",", 
                                                  digits = 3)),"\\%")}
iPer2 <- function(x){paste0(as.character(prettyNum(x, big.mark = ",", 
                                                   digits = 3)),"%")}

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
  
  # NA
  cluster <- as.character(cluster)
  
  #calculate degree of freedom adjustment
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- model$rank
  dfc <- (M/(M-1))*((N-1)/(N-K))
  
  #calculate the uj's
  uj  <- apply(estfun(model), 2, function(x) tapply(x, cluster, sum))
  
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
  require(ROCR, quietly = TRUE)
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
  roc$type <- class(model)[1]
  return(roc)
}

printPB <- function(pbobj, names=NULL, label = NULL){
  require(xtable, quietly = TRUE)
  if(missing(names)){
    names <- c("model 1", "model 2")
  }
  mycap <- paste0("Parametric bootstrap specification test results for ", 
                  label, " using ", pbobj$samples[[1]], 
                  " simulations. Between ", names[1], " and ", names[2], ".")
  print(xtable(pbobj$test, caption = mycap), include.rownames=TRUE)
}


phtest_glmer <- function (glmerMod, glmMod, ...)  {  ## changed function call
  coef.wi <- coef(glmMod)
  coef.re <- fixef(glmerMod)  ## changed coef() to fixef() for glmer
  vcov.wi <- vcov(glmMod)
  vcov.re <- vcov(glmerMod)
  names.wi <- names(coef.wi)
  names.re <- names(coef.re)
  coef.h <- names.re[names.re %in% names.wi]
  dbeta <- coef.wi[coef.h] - coef.re[coef.h]
  df <- length(dbeta)
  dvcov <- vcov.re[coef.h, coef.h] - vcov.wi[coef.h, coef.h]
  stat <- abs(t(dbeta) %*% as.matrix(solve(dvcov)) %*% dbeta)  ## added as.matrix()
  pval <- pchisq(stat, df = df, lower.tail = FALSE)
  names(stat) <- "chisq"
  parameter <- df
  names(parameter) <- "df"
  alternative <- "one model is inconsistent"
  res <- list(statistic = stat, p.value = pval, parameter = parameter, 
              method = "Hausman Test",  alternative = alternative,
              data.name=deparse(glmerMod@call$data))  ## changed
  class(res) <- "htest"
  return(res)
}


REextract <- function(mod){
  out <- ranef(mod, condVar = TRUE)
  out.se <- plyr::adply(attr(out[[1]], which = "postVar"), c(3), 
                        function(x) sqrt(diag(x)))
  out.pt <- out[[1]]
  names(out.se)[-1] <- paste0(names(out.pt), "_se")
  newout <- cbind(out.pt, out.se[, -1])
  return(newout)
}


# Use the Gelman sim technique to build empirical Bayes estimates
# Uses the sim function in the arm package
REsim <- function(x, nsims){
  mysim <- sim(x, n.sims = nsims)
  reDims <- length(mysim@ranef)
  tmp.out <- vector("list", reDims)
  for(i in c(1:reDims)){
    tmp.out[[i]] <- plyr::adply(mysim@ranef[[i]], c(2, 3), plyr::each(c(mean, median, sd)))
    tmp.out[[i]]$level <- paste0("Level ", i)
    tmp.out[[i]]$level <- as.character(tmp.out[[i]]$level)
    tmp.out[[i]]$X1 <- as.character(tmp.out[[i]]$X1)
    tmp.out[[i]]$X2 <- as.character(tmp.out[[i]]$X2)
  }
  dat <- do.call(rbind, tmp.out)
  return(dat)
}


FEsim <- function(x, nsims){
  mysim <- sim(x, n.sims = nsims)
  means <- apply(mysim@fixef, MARGIN = 2, mean)
  medians <- apply(mysim@fixef, MARGIN = 2, median)
  sds <- apply(mysim@fixef, MARGIN =2, sd)
  dat <- data.frame(variable = names(means), meanEff = means, medEff = medians, 
                    sdEff = sds, row.names=NULL)
  return(dat)
}

# Dat is the result of FEsim
# scale is the multiplier for the width of the confidence intervals
# var is a character of the name ("mean" or "median")
# sd is a character of the name for the confidence interval
# sigmaScale is a scalar to transfrm the random effects by
# oddsRatio --> logical, should oddsRatios be calculated
# labs -> custom X axis label
plotMCMCfe <- function(dat, scale, var, sd, sigmaScale = NULL, oddsRatio = FALSE) {
  if(!missing(sigmaScale)){
    dat[, sd] <- dat[, sd] / sigmaScale
    dat[, var] <- dat[, var] / sigmaScale
  }
  dat[, sd] <- dat[, sd] * scale
  dat[, "ymax"] <- dat[, var] + dat[, sd] 
  dat[, "ymin"] <- dat[, var] - dat[, sd]
  hlineInt <- 0
  if(oddsRatio == TRUE){
    dat[, "ymax"] <- exp(dat[, "ymax"])
    dat[, var] <- exp(dat[, var])
    dat[, "ymin"] <- exp(dat[, "ymin"])
    hlineInt <- 1
  }
   xvar <- "variable"
  dat$variable <- as.character(dat$variable)
  dat$variable <- factor(dat$variable , levels = dat[order(dat[, var]), 1])
  ggplot(aes_string(x = xvar, y = var, ymax = "ymax", 
             ymin = "ymin"), 
         data = dat) + geom_point(size=I(3)) +
    geom_errorbar(width = 0.2) + geom_hline(yintercept = hlineInt, color = I("red")) + 
    coord_flip() + 
    theme_dpi()
}


dimNA <- function(df){
  dims <- dim(df)[1] * dim(df)[2]
  propNA <- apply(df, 2, vecNAsearch)
  countNA <- propNA * dim(df)[1]
  total <- sum(countNA)
  totalP <- total / dims
  return(list("TotalCells" = dims, "MissingbyColumn" = countNA, 
              "TotalMissing" = total, "TotalProportionMissing" = totalP))
  
}

vecNAsearch <- function(x){
  l <- length(x)
  lNA <- length(x[is.na(x)])
  return(lNA / l)
}


zeroInf <- function(x){
  x[!is.finite(x)] <- 0
}

zeroNA <- function(x){
  x[is.na(x)] <- 0
  return(x)
}


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

lg  <- function(x) c(NA, x[1:length(x)-1])
lg2 <- function(x) c(NA, NA, x[2:length(x) -2])

# http://stats.stackexchange.com/questions/56525/standard-deviation-of-random-effect-is-0
# http://stat.columbia.edu/~jcliu/paper/HierarchicalPrior.pdf
# http://www.stat.columbia.edu/~radon/paper/paper.pdf (example)

# Dat is the result of REsim
# scale is the multiplier for the width of the confidence intervals
# var is a character of the name ("mean" or "median")
# sd is a character of the name for the confidence interval
# sigmaScale is a scalar to transfrm the random effects by
# oddsRatio --> logical, should oddsRatios be calculated
# labs -> custom X axis label

plotMCMCre <- function(dat, scale, var, sd, sigmaScale = NULL, oddsRatio = FALSE, 
                       labs = NULL){
  if(!missing(sigmaScale)){
    dat[, sd] <- dat[, sd] / sigmaScale
    dat[, var] <- dat[, var] / sigmaScale
  }
  dat[, sd] <- dat[, sd] * scale
  dat[, "ymax"] <- dat[, var] + dat[, sd] 
  dat[, "ymin"] <- dat[, var] - dat[, sd]
  hlineInt <- 0
  if(oddsRatio == TRUE){
    dat[, "ymax"] <- exp(dat[, "ymax"])
    dat[, var] <- exp(dat[, var])
    dat[, "ymin"] <- exp(dat[, "ymin"])
    hlineInt <- 1
  }
  if(!missing(labs)){
    xlabs.tmp <- element_text(face = "bold")
    xvar <- labs
  } else {
    xlabs.tmp <- element_blank()
    xvar <- "id"
  }
  
  dat[order(dat[, var]), "id"] <- c(1:nrow(dat))
  ggplot(dat, aes_string(x = xvar, y = var, ymax = "ymax", 
                         ymin = "ymin")) + 
    geom_pointrange(alpha = I(0.4)) + theme_dpi() + geom_point() +
    labs(x = "Group", y = "Effect Range", title = "Effect Ranges") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          axis.text.x = xlabs.tmp, axis.ticks.x = element_blank()) + 
    geom_hline(yintercept = hlineInt, color = I("red"), size = I(1.1))
}


RMSE.loess <- function(m){
  sqrt(sum(m$residuals^2)/length(m$residuals))
}

substEffSimFE <- function(mod, var, ncases, unscale = NULL, ...){
  # var should be a character, name of variable in model
  # ncases is integer
  # mod is a merMod
  cases <- mod@frame[sample(1:nrow(mod@frame), ncases),]
  cases$caseID <- 1:nrow(cases)
  varLength <- length(unique(mod@frame[, var]))
  if(varLength < 30){
    jitters <- unique(mod@frame[, var])
  } else {
    jitters <- quantile(mod@frame[, var], probs=seq(0,1, by =0.05))
  }
  simvals <- expand.grid(caseID = unique(cases$caseID), newvar = jitters)
  plotdf <- merge(cases, simvals)
  plotdf$oldvar <- plotdf[, var]
  plotdf[, var] <- plotdf$newvar
  plotdf$newvar <- NULL
  plotdf <- cbind(plotdf, easyPredCI(mod, newdata=plotdf, ...))
  if(missing(unscale)){
    return(plotdf)
  } else {
    stopifnot(class(unscale) == "matrix")
    plotdf$newvarUnscale <- (plotdf[, var] * 2 * unscale[var, 2]) + unscale[var, 1]
    return(plotdf)
  }
}


substEffSimRE <- function(mod, var, ncases, ...){
  # var should be a character, name of variable in model
  # ncases is integer
  # mod is a merMod
  cases <- mod@frame[sample(1:nrow(mod@frame), ncases),]
  cases$caseID <- 1:nrow(cases)
  varLength <- length(unique(mod@frame[, var]))
  jitters <- unique(mod@frame[, var])
  simvals <- expand.grid(caseID = unique(cases$caseID), newvar = jitters)
  plotdf <- merge(cases, simvals)
  plotdf$oldvar <- plotdf[, var]
  plotdf[, var] <- plotdf$newvar
  plotdf <- cbind(plotdf, easyPredCI(mod, newdata=plotdf, re = TRUE, ...))
  return(plotdf)
}


easyPredCI <- function(model, newdata, alpha=0.05, re = NULL) {
  # From https://rpubs.com/bbolker/glmmchapter
  ## baseline prediction, on the linear predictor (logit) scale:
  if(missing(re)){
    pred0 <- predict(model, re.form = NA, newdata=newdata)
  } else{
    pred0 <- predict(model, newdata=newdata)
  }
  ## fixed-effects model matrix for new data
  X <- model.matrix(formula(model,fixed.only=TRUE)[-2],
                    newdata)
  beta <- fixef(model) ## fixed-effects coefficients
  V <- vcov(model)     ## variance-covariance matrix of beta
  pred.se <- sqrt(diag(X %*% V %*% t(X))) ## std errors of predictions
  
  if(class(model) == "lmerMod"){
    linkinv <- identity
  } else if(class(model) == "glmerMod"){
    ## inverse-link (logistic) function: could also use plogis()
    linkinv <- model@resp$family$linkinv
  }
  ## construct 95% Normal CIs on the link scale and
  ##  transform back to the response (probability) scale:
  crit <- -qnorm(alpha/2)
  linkinv(cbind(lwr = pred0 - crit * pred.se,
                upr = pred0 + crit * pred.se, 
                yhat = pred0))
}

### Boot CI for merMod
# set.seed(101)
# bb <- bootMer(fullmodMMni,
#               FUN=function(x)
#               predict(x,re.form=NA,newdata=seplotdf,type="response"),
#               nsim=5)
# 
# cpredboot1.CI <- t(sapply(1:4,
#        function(i)
#          boot.ci(bb,type="perc",index=i)$percent[4:5]))

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
