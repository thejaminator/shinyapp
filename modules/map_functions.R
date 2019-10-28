library(jsonlite)

get_zoom_level <- function(address) {
  url <- "https://maps.googleapis.com/maps/api/geocode/json?address="
  url_2 <- ",+SG&key=AIzaSyAjKAKegmEpoOwDPBTq5D7PYlbsWXIYF_g"
  address_url <- gsub(' ', '+', address)
  url_exact <- paste0(url, address_url, url_2)
  details <- fromJSON(url_exact)
  lat_lon <- details$results$geometry$location
}
