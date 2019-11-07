library(shiny)
library(ggplot2)
library(plotly)
library(leaflet)
library(shinyFeedback)
library(dplyr)
library(data.table)
library(shinydashboardPlus)
library(shinydashboard)
library(data.table)
library(htmltools)
library(ggthemes)
library(scales)
#for debug library(profvis)


# load module functions
source("modules/mongo.R")
source("modules/map_functions.R")
source("modules/create_arima.R")



### Static variables ### Variables available to all sessions

#James stuff
fake<-TRUE #use fake=TRUE to avoid calling mongodb and use saved carpark data instead of realtime
Sys.setenv(TZ="Asia/Singapore") #to avoid mongo messing up the timezone
TIME_INTERVAL<-5 #5 minutes, used for prediction intervals
#End James stuff

# Load dataset which is run ech time user visits, so that it will be refreshed


### run ONLY ONCE SO WE HAVE DEFAULT TIME VALUE
latestTime<<-getAllCarparks(limit=1, fake=fake)$time[[1]]

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