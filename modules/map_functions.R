library(jsonlite)



get_avail_lots<-function(index_df, avail_df, latest_time){
  "Returns df of available lots."
  latest_available <- avail_df %>% filter(time == latest_time) %>% select(car_park_no = carpark_name, avail_lots)
  index <- index_df %>% 
    select(car_park_no) %>%
    mutate(car_park_no = paste0(car_park_no,"_C")) %>%
    select(car_park_no)
  result <- merge (x=index, y=latest_available, by="car_park_no", all.x = TRUE) %>% arrange(car_park_no)
  result$car_park_no <-result$car_park_no %>% gsub("_C","",.)
  return(result)
}



get_zoom_level <- function(address) {
  url <- "https://maps.googleapis.com/maps/api/geocode/json?address="
  url_2 <- ",+SG&key=AIzaSyAjKAKegmEpoOwDPBTq5D7PYlbsWXIYF_g"
  address_url <- gsub(' ', '+', address)
  url_exact <- paste0(url, address_url, url_2)
  details <- fromJSON(url_exact)
  lat_lon <- details$results$geometry$location
}


# Label colour logic

get_colour <- function(avail_lots) {
    if(avail_lots >= 40) {
      return("green")
    } else if(avail_lots >= 10) {
      return("orange")
    } else {
      return("red")
    }
}


get_icons <- function(df, avail_lots){
  awesomeIcons(
  icon = 'ios-close',
  iconColor = 'black',
  library = 'ion',
  markerColor = sapply(df$avail_lots, get_colour)
)
}



# 
# leaflet(df.20) %>% addTiles() %>%
#   addAwesomeMarkers(~long, ~lat, icon=icons, label=~as.character(mag))
# 

