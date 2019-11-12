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


get_icons <- function(df){
  awesomeIcons(
  # icon = 'ios-close',
  # iconColor = 'black',
  # library = 'ion',
    icon = 'car',
    iconColor = 'black',
    library = 'fa',
  markerColor = sapply(df$avail_lots, get_colour)
)
}


get_carpark_price <- function(x,y){
  T1 <- strftime(x, format="%H:%M:%S")
  T2 <- strftime(y, format="%H:%M:%S")
  A <- isWeekday(x, wday =1:6)
  B <- isWeekday(y, wday =1:6)
  if(T1 < "07:00:00" & A == 'FALSE'){A = "TRUE"} else if(T1 < "07:00:00" & A == "TRUE"){A = "TRUE"}
  if(T2 < "07:00:00" & B == 'FALSE'){B = "TRUE"} else if(T2 < "07:00:00" & B == "TRUE"){B = "TRUE"}
  G <- ifelse(T1 > "07:00:00" & T1 < "22:30:00", "Day", "Night") 
  H <- ifelse(T2 > "07:00:00" & T2 < "22:30:00", "Day", "Night") 
  if(A == 'TRUE' & B =='TRUE' & G =="Day" & H =="Day"){
    abs(as.numeric(difftime(x,y,units="hours")))*1.2
  } else if(A == 'TRUE' & B == 'TRUE' & G =="Day" & H =="Night"){
    pmin(abs(as.numeric(difftime(x,y,units="hours")))*1.2,5)
  } else if(A == 'TRUE' & B == 'TRUE' & G =="Night" & H =="Day"){
    pmin(abs(as.numeric(difftime(x,y,units="hours")))*1.2,5)
  } else if(A == 'TRUE' & B == 'TRUE' & G =="Night" & H =="Night"){
    pmin(abs(as.numeric(difftime(x,y,units="hours")))*1.2,5)
  } else if(A == 'TRUE' & B =='FALSE'){
    P <- as.Date(y)
    New <- lubridate::ymd_hm(paste(P, "6:30 AM"))
    New <- as.POSIXct(as.numeric(New), origin=as.POSIXct("1970-01-01", tz="Asia/Singapore"), tz="Asia/Singapore")
    pmin(abs(as.numeric(difftime(x,New,units="hours")))*1.2,5)
  } else if(A == 'FALSE' & B == 'TRUE' & H == "Day"){
    P <- as.Date(y)
    New <- lubridate::ymd_hm(paste(P, "6:30 AM"))
    New <- as.POSIXct(as.numeric(New), origin=as.POSIXct("1970-01-01", tz="Asia/Singapore"), tz="Asia/Singapore")
    abs(as.numeric(difftime(y,New,units="hours")))*1.2
  } else if(A == 'FALSE' & B == 'TRUE' & T2 < "07:00:00"){
    "0"
  } else if(A == 'FALSE' & B == 'TRUE' & T2 > "22:30:00"){
    P <- as.Date(y)
    New <- lubridate::ymd_hm(paste(P, "6:30 AM"))
    New <- as.POSIXct(as.numeric(New), origin=as.POSIXct("1970-01-01", tz="Asia/Singapore"), tz="Asia/Singapore")
    pmin(abs(as.numeric(difftime(New,y,units="hours")))*1.2,5)
  }else{"0"}
}
