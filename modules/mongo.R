library(tidyr)
library(mongolite)
# load login variables
source("modules/login.R")
#login.R should have two variables
# user<-"username"
# pass<-"password"


#set up collection to query
availabilityCollection<-mongo(collection="carpark",db = "test_db",
               url=sprintf('mongodb+srv://%s:%s@james-cluster-bfs0h.gcp.mongodb.net',user,pass))

getCarpark<-function(mongo_collection=availabilityCollection, carpark_id, limit=100){
  fields<-sprintf('{"%s" : 1, "time" :1, "_id" :0}', carpark_id) #query the carpark_id
  mongo_collection$find('{}' , limit = limit, fields = fields, sort='{"time":-1}')
}

getAllCarparks<-function(mongo_collection=availabilityCollection, limit=100, fake = FALSE){
  if (fake == TRUE){
    return(readRDS("./data/backup"))
  }
  else {
    #get latest carpark from mongo
    df<-availabilityCollection$find('{}' , limit = limit, sort='{"time":-1}')
    #reshape into tidy
    df %>% gather(key=carpark_name,value = avail_lots, -time)
  }

}

#in case mongo does not work
# backup<-getAllCarparks(limit=1000)
# backup %>% saveRDS("./data/backup")

