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




# load module functions
source("modules/mongo.R")
source("modules/map_functions.R")


### Static variables ### Variables available to all sessions


#James stuff
fake<-TRUE #use fake=TRUE to avoid calling mongodb and use saved carpark data instead of realtime
### load carpark available dataset from mongo only when initialized
carparkAvail<-getAllCarparks(limit=500, fake=fake) 
uniqueCarparks <- unique(carparkAvail$carpark_name)
### load latest time from mongo
latestTime<-carparkAvail$time[[1]]
#End James stuff

#Phyllis stuff
range_lat <- c(1.28967-1,1.28967+1)
range_lng <- c(103.85007-1, 103.85007+1)
hdb_geo_info <- read.csv('data/hdb_available_query.csv') %>% arrange(car_park_no) 
#add lot availability for current time
hdb_geo_info$avail_lots <- get_avail_lots(index_df=hdb_geo_info,avail_df=carparkAvail,latest_time=latestTime)$avail_lots
#somehow there is n.a in the dataframe availability
hdb_geo_info <- hdb_geo_info %>% filter(!is.na(avail_lots))
#add icons
icons <- get_icons(hdb_geo_info, avail_lots=avail_lots)
#add map overlay
carpark_types = c('BASEMENT CAR PARK', 'MULTI-STOREY CAR PARK','SURFACE CAR PARK')


#End phyllis stuff


### End Static variables ###