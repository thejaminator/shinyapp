library(data.table)

source("global_stuff.R", local=FALSE)
server <- function(input, output, session, ...) {
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% addMarkers(data = hdb_geo_info, lng = ~lon, lat = ~lat)
  })
  
  observeEvent(input$button, {
    lat_lon <- get_zoom_level(input$address)
    leafletProxy('map') %>% fitBounds(lng1 =lat_lon$lng+0.0025, lng2=lat_lon$lng-0.0025, lat1=lat_lon$lat+0.0025, lat2=lat_lon$lat-0.0025)
    if (is.null(lat_lon)) {
      feedbackDanger(
        inputId = 'address',
        condition = is.null(lat_lon),
        text = 'Please provide valid Address/Postal Code'
      ) 
    } else {
      feedbackWarning(
        inputId = 'address',
        condition = !lat_lon$lat %between% range_lat | !lat_lon$lng %between%range_lng,
        text = "This location does not look like it's in Singapore!"
      )
    }
  })
  
}