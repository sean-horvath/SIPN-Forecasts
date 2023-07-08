get.covariates <- function(sample_ras=sample_ras){
  require(raster);require(maptools); require(tidync)
  ret_list <- list()
  
  myvalue <- tidync('data/single_level/temp.nc') %>%
    hyper_tibble(force=TRUE)
  myvalue$longitude[which(myvalue$longitude >180)] <- (360-myvalue$longitude[which(myvalue$longitude >180)])*(-1)
  
  # t2m
  t2m <- myvalue %>%
    dplyr::select(t2m,longitude,latitude,time) %>%
    filter(latitude>=60) %>%
    arrange(time) %>%
    pivot_wider(id_cols=c(longitude,latitude),
                names_from=time,
                values_from=t2m)
  tmp <- t(scale(t(t2m[,3:dim(t2m)[2]])))
  t2m[,3:dim(t2m)[2]] <- tmp
  coordinates(t2m)=~longitude+latitude
  gridded(t2m) <- TRUE
  t2m <- stack(t2m)
  crs(t2m) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0'
  t2m <- projectRaster(t2m,
                       crs='+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs')
  t2m <- resample(t2m, sample_ras, method='bilinear')
  
  ret_list[[1]] <- t2m
  
  # lwdwn
  lwdwn <- myvalue %>%
    dplyr::select(msdwlwrf,longitude,latitude,time) %>%
    filter(latitude>=60) %>%
    arrange(time) %>%
    pivot_wider(id_cols=c(longitude,latitude),
                names_from=time,
                values_from=msdwlwrf)
  tmp <- t(scale(t(lwdwn[,3:dim(lwdwn)[2]])))
  lwdwn[,3:dim(lwdwn)[2]] <- tmp
  coordinates(lwdwn)=~longitude+latitude
  gridded(lwdwn) <- TRUE
  lwdwn <- stack(lwdwn)
  crs(lwdwn) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0'
  lwdwn <- projectRaster(lwdwn,
                       crs='+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs')
  lwdwn <- resample(lwdwn, sample_ras, method='bilinear')
  
  ret_list[[2]] <- lwdwn

  # sst
  sst <- myvalue %>%
    dplyr::select(sst,longitude,latitude,time) %>%
    arrange(time) %>%
    pivot_wider(id_cols=c(longitude,latitude),
                names_from=time,
                values_from=sst)
  latlon <- sst %>%
    dplyr::select(longitude,latitude)
  # Atlantic, North of the Equator
  box1 <- which(latlon[,1]<=45 & latlon[,1]>=30 & latlon[,2]>=31 & latlon[,2]<=60)
  box2 <- which(latlon[,1]<=30 & latlon[,1]>=20 & latlon[,2]>=31 & latlon[,2]<=65)
  box3 <- which(latlon[,1]<=20 & latlon[,1]>=-65 & latlon[,2]>=0 & latlon[,2]<=65)
  box4 <- which(latlon[,1]<=-65 & latlon[,1]>=-70 & latlon[,2]>=0 & latlon[,2]<=55)
  box5 <- which(latlon[,1]<=-70 & latlon[,1]>=-75 & latlon[,2]>=0 & latlon[,2]<=55)
  box6 <- which(latlon[,1]<=-75 & latlon[,1]>=-84 & latlon[,2]>=9 & latlon[,2]<=40)
  box7 <- which(latlon[,1]<=-84 & latlon[,1]>=-90 & latlon[,2]>=14 & latlon[,2]<=40)
  box8 <- which(latlon[,1]<=-90 & latlon[,1]>=-100 & latlon[,2]>=18 & latlon[,2]<=40)
  
  atlantic_index <- c(box1,box2,box3,box4,box5,box6,box7,box8)
  atlantic_sst <- sst[atlantic_index,]
  
  tmp <- t(scale(t(atlantic_sst[,3:dim(atlantic_sst)[2]])))
  atlantic_sst[,3:dim(atlantic_sst)[2]] <- tmp
  coordinates(atlantic_sst)=~longitude+latitude
  gridded(atlantic_sst) <- TRUE
  atlantic_sst <- stack(atlantic_sst)
  crs(atlantic_sst) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0'

  ret_list[[3]] <- atlantic_sst
  
  # Pacific, north of Equator
  box1 <- which(latlon[,1]<=-70 & latlon[,1]>=-80 & latlon[,2]>=0 & latlon[,2]<=9)
  box2 <- which(latlon[,1]<=-80 & latlon[,1]>=-84 & latlon[,2]>=0 & latlon[,2]<=9)
  box3 <- which(latlon[,1]<=-84 & latlon[,1]>=-90 & latlon[,2]>=0 & latlon[,2]<=14)
  box4 <- which(latlon[,1]<=-90 & latlon[,1]>=-100 & latlon[,2]>=0 & latlon[,2]<=18)
  box5 <- which(latlon[,1]<=-100 & latlon[,1]>=-145 & latlon[,2]>=0 & latlon[,2]<=66)
  box6 <- which(latlon[,1]<=145 & latlon[,1]>=100 & latlon[,2]>=0 & latlon[,2]<=66)
  box7 <- which(latlon[,1]<=-145 & latlon[,2]>=0 & latlon[,2]<=66)
  box8 <- which(latlon[,1]>=145 & latlon[,2]>=0 & latlon[,2]<=66)
  
  pacific_index <- c(box1,box2,box3,box4,box5,box6,box7,box8)
  pacific_sst <- sst[pacific_index,]
  
  tmp <- t(scale(t(pacific_sst[,3:dim(pacific_sst)[2]])))
  pacific_sst[,3:dim(pacific_sst)[2]] <- tmp
  coordinates(pacific_sst)=~longitude+latitude
  gridded(pacific_sst) <- TRUE
  pacific_sst <- stack(pacific_sst)
  crs(pacific_sst) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0'
  
  ret_list[[4]] <- pacific_sst
  
  
  # gph
  rm(myvalue)
  myvalue <- tidync('data/pressure_level/temp.nc') %>%
    hyper_tibble(force=TRUE)
  myvalue$longitude[which(myvalue$longitude >180)] <- (360-myvalue$longitude[which(myvalue$longitude >180)])*(-1)
  
  gph <- myvalue %>%
    dplyr::select(z,longitude,latitude,time) %>%
    filter(latitude>=60) %>%
    arrange(time) %>%
    pivot_wider(id_cols=c(longitude,latitude),
                names_from=time,
                values_from=z)
  tmp <- t(scale(t(gph[,3:dim(gph)[2]])))
  gph[,3:dim(gph)[2]] <- tmp
  coordinates(gph)=~longitude+latitude
  gridded(gph) <- TRUE
  gph <- stack(gph)
  crs(gph) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0'
  gph <- projectRaster(gph,
                       crs='+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs')
  gph <- resample(gph, sample_ras, method='bilinear')
  
  ret_list[[5]] <- gph
  
  names(ret_list) <- c('t2m','lwdwn','atl','pac','gph')
  return(ret_list)
}

