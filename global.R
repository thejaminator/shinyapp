library(shiny)
library(shinydashboardPlus)
library(shinydashboard)
library(shinyFeedback)
library(ggplot2)
library(plotly)
library(leaflet)
library(dplyr)
library(data.table)
library(htmltools)
library(ggthemes)
library(scales)
library(ggridges)
#for debug library(profvis)


# load module functions
source("modules/mongo.R")
source("modules/map_functions.R")
source("modules/create_arima.R")



### Static variables ### Variables available to all sessions

#James stuff
fake<-FALSE #use fake=TRUE to avoid calling mongodb and use saved carpark data instead of realtime
Sys.setenv(TZ="Asia/Singapore") #to avoid mongo messing up the timezone
TIME_INTERVAL<-5 #5 minutes, used for prediction intervals

#initially query carpark and store on server
### get predicted carpark info
### run ONLY ONCE SO WE HAVE DEFAULT TIME VALUE
latestTime<-getAllCarparks(limit=1, fake=fake)$time[[1]]

if (fake){
prediction<-get_prediction_historical(latestTime=latestTime, carparkAvail=getAllCarparks(limit=288, fake=fake),
                                        historical_data=readRDS("./data/backup"))
}else {
prediction<-get_prediction_historical_3(latestTime=latestTime, carparkAvail=getAllCarparks(limit=288, fake=fake),
historical_data=readRDS("./data/backup"))
}

#End James stuff

# Load dataset which is run ech time user visits, so that it will be refreshed



### load latest time from mongo and set it for all sessions
# uniqueCarparks <- unique(getAllCarparks(limit=1, fake=fake)$carpark_name)

#Phyllis stuff
range_lat <- c(1.28967-1,1.28967+1)
range_lng <- c(103.85007-1, 103.85007+1)
hdb_geo_info <- read.csv('data/hdb_available_query.csv') %>% arrange(car_park_no) 

#add map overlay
carpark_types = c('BASEMENT CAR PARK', 'MULTI-STOREY CAR PARK','SURFACE CAR PARK')
#End phyllis stuff


#Nicholas weather
data_area <- read.csv("data/weather_area.csv")