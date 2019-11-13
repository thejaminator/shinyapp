library(tidyr)
library(mongolite)
# load login variables

#login.R should have two variables
# user<-"username"
# pass<-"password"


#set up collection to query
get_collection <- function(collection="carpark",db = "test_db"){
  source("modules/login.R", local= TRUE)
  mongo(collection=collection,db = db,
        url=sprintf('mongodb://%s:%s@james-cluster-shard-00-00-bfs0h.gcp.mongodb.net:27017,james-cluster-shard-00-01-bfs0h.gcp.mongodb.net:27017,james-cluster-shard-00-02-bfs0h.gcp.mongodb.net:27017/test?ssl=true&replicaSet=james-cluster-shard-0&authSource=admin&retryWrites=true&w=majority',user,pass)
  )
        # url=sprintf('mongodb+srv://%s:%s@james-cluster-bfs0h.gcp.mongodb.net',user,pass))
}


getCarpark<-function(mongo_collection=get_collection(), carpark_id, limit=100){
  fields<-sprintf('{"%s" : 1, "time" :1, "_id" :0}', carpark_id) #query the carpark_id
  df<-mongo_collection$find('{}' , limit = limit, fields = fields, sort='{"time":-1}')
  #for some reason, time is offset by 8 hours
  seconds_offset <- 8 * 60 * 60
  df$time <- df$time - seconds_offset
  df
}

# get_carpark_hourly<-function(mongo_collection=get_collection(), carpark_id, limit=100){
#   fields<-sprintf('{"%s" : 1, "time" :1, "_id" :0}', carpark_id) #query the carpark_id
#   df<-mongo_collection$find('{}' , limit = limit, fields = fields, sort='{"time":-1}')
#   #for some reason, time is offset by 8 hours
#   seconds_offset <- 8 * 60 * 60
#   df$time <- df$time - seconds_offset
#   df
# }

getAllCarparks<-function(mongo_collection=get_collection(), limit=1000, fake = FALSE){
  if (fake == TRUE){
    return(readRDS("./data/backup"))
  }
  else {
    #get latest carpark from mongo
    df<-mongo_collection$find('{}' , limit = limit, sort='{"time":-1}')
    cat("Debug: Mongo data retrieval success!\n")
    #for some reason, time is offset by 8 hours
    seconds_offset <- 8 * 60 * 60
    df$time <- df$time - seconds_offset
    
    #reshape into tidy
    df %>% gather(key=carpark_name,value = avail_lots, -time)
  }
}


get_6_days_ago<-function(mongo_collection=get_collection(), limit=288, fake = FALSE){
  if (fake == TRUE){
    return(readRDS("./data/backup"))
  }
  else {
    #1 day worht of data = 288. 6 days ago means skip 6* 288
    df<-mongo_collection$find('{}' , limit = limit, sort='{"time":-1}',skip=1728)
    cat("Debug: Mongo data retrieval success!\n")
    #for some reason, time is offset by 8 hours
    seconds_offset <- 8 * 60 * 60
    df$time <- df$time - seconds_offset
    
    #reshape into tidy
    df %>% gather(key=carpark_name,value = avail_lots, -time)
  }
}
# # in case mongo does not work
# carparkAvail<-getAllCarparks(limit=2016)
# write.csv(carparkAvail,file="2weeks_carpark.csv")
# carparkAvail %>% saveRDS("./data/backup")
