library(dplyr)
library(ggplot2)
library(forecast)
library(xts)
library(stats)
source("modules/mongo.R")

##this file handles prediction logic


get_prediction <- function(carparkAvail,latestTime){
  #get past one week data as carparkAvail
  #predict by taking t-7days
  #requires one week of data to be pulled from mongo so deprecated inplace for get_prediction_historical
  #which alligns the data and time with historical data and gets the availability
  prediction<-carparkAvail  %>% subset(time > (latestTime - as.difftime(7, unit="days")))
  prediction$time <- prediction$time + as.difftime(7, unit="days")
  #add is_pred column for ggplot
  carparkAvail$is_pred<-FALSE
  prediction$is_pred<-TRUE
  prediction<-rbind(prediction,carparkAvail)
  return(prediction)
}

extrapolate_7days <- function(historical_data){
  #returns dataframe extrapolated by 7 days
  #Get subset of last 7 days
  last_7_days <- historical_data  %>% subset(time > (historical_data$time[[1]] - as.difftime(7, unit="days")))
  historical_data_copy<-last_7_days
  #Extrapolate 7 days
  historical_data_copy$time <- historical_data_copy$time + as.difftime(7, unit="days")
  #return 14 days which includes the previous 7 days and the forward 7 days
  return(rbind(historical_data_copy,historical_data))
}


get_prediction_historical <- function(latestTime, carparkAvail, historical_data ){
  #alligns the data and time with historical data and gets the availability
  #depends on global latestTime
  while (latestTime > historical_data$time[[1]] - as.difftime(1, unit="days")){ #need at least 1 day in advance data
    historical_data<-extrapolate_7days(historical_data)
  }
  #add is_pred column for ggplot
  carparkAvail$is_pred<-FALSE
  historical_data$is_pred<-TRUE
  #drop extrapolated data before the current date
  historical_data<- historical_data %>% subset(time >latestTime)
  prediction<-rbind(historical_data,carparkAvail)
  return (prediction)
}



## Use this to update historical_data
# historical_data<-getAllCarparks(limit=2016)
# historical_data %>% saveRDS("./data/backup")


#make predictions and historical data into prediction dataframe
#


# hourly<-df %>% filter(grepl(":00:00",.$time))

#beause the values can
#daily = 288 periods, weekly = 2016install.packages("readxl")




# 
# #hourly is 24
# test<-hourly$BM29_C %>% msts(seasonal.periods=c(24,168))
# # ggplot(data= test, aes(x=time, y=BM29_C)) + geom_line()
# 
# # transform to bounds
# transform <-function(timeseries) {
#   correction<-0.00001 #to prevent -inf and inf
#   lower<-0
#   upper<-max(timeseries)
#   log((timeseries+correction-lower) / (upper+correction-timeseries))
# }
# 
# transform_back <-function(fc, original_timeseries) {
#   correction<-0.00001 #to prevent -inf and inf
#   lower<-0
#   upper<-max(original_timeseries)
#   fc$mean <- (upper-lower)*exp(fc$mean)/(1+exp(fc$mean)) + lower
#   fc$lower <- (upper-lower)*exp(fc$lower)/(1+exp(fc$lower)) + lower
#   fc$upper <- (upper-lower)*exp(fc$upper)/(1+exp(fc$upper)) + lower
#   fc$x <- original_timeseries
#   fc
# }
# 
# test %>% transform
# 
# 
# #lambda is 0 for log transformation
# fit <- auto.arima(test %>% transform)
# 
# forecast(fit, h=24) %>% transform_back(test)
# # test<-resample_xts(ts, 5/60)
# # plot(test)
# # ggplot(data= test, aes(x=time, y=V1)) + geom_line()
# 
# plot(forecast(fit, h=100)%>% transform_back(test))
# autoplot(ts)
# 
# my_fit <- arima(test , order = c(1L, 0, 0), seasonal=c(1L,0,0))
# amy_fit
# 
# 
# plot(forecast(my_fit, h=500))
# 
# test %>% diff(lag=288) %>% ggtsdisplay()
# test
