library(tidyverse)
library(magrittr)
library(raster)
library(lubridate)
library(arm)

# Ice Retreat Data --------------------------------------------------------

sample_ras <- raster('data/Ice Concentration/N_197901_concentration_v3.0.tif')

source('get_covariates_probs.R')
covars <- get.covariates(sample_ras=sample_ras)

# Monthly Sept extent
flist <- list.files('data/SeptMonthlyExtent',
                    full.names = TRUE)
minimum_extents <- stack(flist)
minimum_extents[minimum_extents>=200] <- NA

area_data <- as.vector(t(readRDS('data/area_data.RDS')))

mo = month(Sys.Date()) - 1
filenames2 <- list.files('data/Ice Concentration/',
                         pattern=paste0('0',mo,'_'),
                         full.names = TRUE)

ice_conc <- stack(filenames2)
conc_values <- getValues(ice_conc)
conc_values <- conc_values/10
conc_values <- scale(t(conc_values))
conc_values <- t(conc_values)

covar_x <- lapply(covars,getValues)

h500pc <- covar_x$gph
index <- complete.cases(h500pc)
h500pc <- h500pc[index,]
h500pc <- scale(prcomp(t(h500pc))$x[,1])

atlpc <- covar_x$atl
index <- complete.cases(atlpc)
atlpc <- atlpc[index,]
atlpc <- scale(prcomp(t(atlpc))$x[,1])

pacpc <- covar_x$pac
index <- complete.cases(pacpc)
pacpc <- pacpc[index,]
pacpc <- scale(prcomp(t(pacpc))$x[,1])

min_vals <- getValues(minimum_extents)

predras <- raster(minimum_extents,layer=1)

sat_x <- covar_x$t2m
lwgdn_x <- covar_x$lwdwn
conc_x <- conc_values
h500_x <- h500pc
atl_x <- atlpc
pac_x <- pacpc
ytrain <- min_vals

lat <- readRDS('data/psn_lat.RDS')
lon <- readRDS('data/psn_lon.RDS')

k = dim(sat_x)[2]
sat_train <- sat_x[,-k]
h500_train <- h500_x[-k,1]
atl_train <- atl_x[-k,1]
pac_train <- pac_x[-k,1]
lwgdn_train <- lwgdn_x[,-k]
sat_test <- sat_x[,k]
h500_test <- h500_x[k,1]
atl_test <- atl_x[k,1]
pac_test <- pac_x[k,1]
lwgdn_test <- lwgdn_x[,k]
conc_train <- conc_values[,-k]
conc_test <- conc_values[,k]
ytrain <- min_vals[,-k]

ypred <- rep(NA,dim(ytrain)[1])

begin <- Sys.time()
for(j in 1:dim(ytrain)[1]){
  if(length(unique(ytrain[j,]))==1){
    ypred[j]=ytrain[j,1]
  } else if(lat[j]<60){
    ypred[j]=NA
  } else if(all(is.na(conc_train[j,]))){
    ypred[j]=NA
  } else {
    mydata <- as.data.frame(cbind(ytrain[j,],
                                  sat_train[j,],
                                  h500_train,
                                  atl_train,
                                  pac_train,
                                  lwgdn_train[j,],
                                  conc_train[j,]))
    colnames(mydata) <- c('Y','SAT','H500','ATL',
                          'PAC','LWGDN','Conc')
    
    zz = bayesglm(Y ~ .,data=mydata, family='binomial',
                  control = list(maxit = 5000),na.action='na.omit')
    
    xtest <- data.frame(Y=1,SAT=sat_test[j],
                        H500=h500_test,
                        ATL=atl_test,
                        PAC=pac_test,
                        LWGDN=lwgdn_test[j],
                        Conc=conc_test[j])
    
    out <- sim(zz,10000)@coef
    
    z <- out%*%as.numeric(xtest[1,])
    
    zz1 <- exp(z)/(1+exp(z))
    ztemp1 <- rep(NA,1000)
    for(i in 1:1000){
      ztemp <- sample(zz1,1,replace=T)
      ztemp1[i] <- rbinom(1,100,ztemp)
    }
    ztemp1 <- ztemp1/100
    zz2 <- median(ztemp1)
    
    ypred[j] <- zz2
  }
  
}
ice_cells <- ypred
ice_cells[ice_cells<0.7] <- 0
ice_cells[is.na(ice_cells)] <- 0
ice_cells[ice_cells>=0.7] <- 1
pred_extent <- sum(ice_cells*area_data)/10^6
full_ras <- setValues(predras, ypred)
end <- Sys.time()
print(end-begin)

yr <- year(Sys.Date())
mo = month(Sys.Date(), label=T, abbr=F)

# On EASE2.0 Grid
ease_ras <- projectRaster(full_ras,crs=CRS("+proj=laea +lat_0=90 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m"))

lat <- raster('data/EASE2_N25km.geolocation.v0.9.nc',
              varname = 'latitude')
lon <- raster('data/EASE2_N25km.geolocation.v0.9.nc',
              varname = 'longitude')

ease_ras <- resample(ease_ras,lat)
names(ease_ras) <- 'Probabilistic.Minimum.Sea.Ice.Cover'

writeRaster(ease_ras,
            str_c(yr, '/', yr, '_Min_Probability_Forecast_Made_In_', mo, '.nc'),
            format='CDF')

pred_extent_df = tibble(mo, pred_extent) %>%
  set_colnames(c('ForecastMonth','PredExtent'))
if (file.exists(str_c(yr, '/PredExtent.csv'))){
  df <- read_csv(str_c(yr, '/PredExtent.csv')) %>%
    bind_rows(pred_extent_df)
} else{
  df <- pred_extent_df
}
write_csv(df, str_c(yr, '/PredExtent.csv'))
