library(dplyr)
library(ggplot2)
library(forecast)
library(xts)
library(stats)
source("modules/mongo.R")

#get past one week data


df<-getCarpark(carpark_id="BM29_C",limit=3000)

hourly<-df %>% filter(grepl(":00:00",.$time))

#beause the values can 
#daily = 288 periods, weekly = 2016
# test<-df$BM29_C %>% msts(seasonal.periods=c(288))





#hourly is 24
test<-hourly$BM29_C %>% msts(seasonal.periods=c(24,168))
# ggplot(data= test, aes(x=time, y=BM29_C)) + geom_line()

# transform to bounds
transform <-function(timeseries) {
  correction<-0.00001 #to prevent -inf and inf
  lower<-0
  upper<-max(timeseries)
  log((timeseries+correction-lower) / (upper+correction-timeseries))
}

transform_back <-function(fc, original_timeseries) {
  correction<-0.00001 #to prevent -inf and inf
  lower<-0
  upper<-max(original_timeseries)
  fc$mean <- (upper-lower)*exp(fc$mean)/(1+exp(fc$mean)) + lower
  fc$lower <- (upper-lower)*exp(fc$lower)/(1+exp(fc$lower)) + lower
  fc$upper <- (upper-lower)*exp(fc$upper)/(1+exp(fc$upper)) + lower
  fc$x <- original_timeseries
  fc
}

test %>% transform


#lambda is 0 for log transformation
fit <- auto.arima(test %>% transform)

forecast(fit, h=24) %>% transform_back(test)
# test<-resample_xts(ts, 5/60)
# plot(test)
# ggplot(data= test, aes(x=time, y=V1)) + geom_line()

plot(forecast(fit, h=100)%>% transform_back(test))
autoplot(ts)

my_fit <- arima(test , order = c(1L, 0, 0), seasonal=c(1L,0,0))
amy_fit


plot(forecast(my_fit, h=500))

test %>% diff(lag=288) %>% ggtsdisplay()
test
