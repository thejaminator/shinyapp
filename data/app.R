library(jsonlite)
library(leaflet)
library(shinyFeedback)
library(data.table)
library(shiny)

range_lat <- c(1.28967-1,1.28967+1)
range_lng <- c(103.85007-1, 103.85007+1)
data <- read.csv('hdb_carpark_intersection.csv')

get_zoom_level <- function(postal_code) {
  url <- 'https://maps.googleapis.com/maps/api/geocode/json?key=AIzaSyAjKAKegmEpoOwDPBTq5D7PYlbsWXIYF_g&components=postal_code:'
  url_exact <- paste0(url, postal_code)
  details <- fromJSON(url_exact)
  lat_lon <- details$results$geometry$location
}

library(shiny)
ui <- fluidPage(
  useShinyFeedback(),
  
  headerPanel("Car Parks in Singapore"),
  sidebarPanel(
    numericInput(inputId = 'postal_code', 
              label= "Postal Code:",
              value = 0),
    actionButton('button', 'Zoom')
  ),
  
  mainPanel(
    leafletOutput('map')
  )
)

server <- function(input, output){
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% addMarkers(data = data, lng = ~lon, lat = ~lat)
  })
  
  observeEvent(input$button, {
    lat_lon <- get_zoom_level(input$postal_code)
    leafletProxy('map') %>% fitBounds(lng1 =lat_lon$lng+0.0025, lng2=lat_lon$lng-0.0025, lat1=lat_lon$lat+0.0025, lat2=lat_lon$lat-0.0025)
    if (is.null(lat_lon)) {
      feedbackDanger(
        inputId = 'postal_code',
        condition = is.null(lat_lon),
        text = 'Please provide valid Postal Code'
      ) 
    } else {
      feedbackWarning(
        inputId = 'postal_code',
        condition = !lat_lon$lat %between% range_lat | !lat_lon$lng %between%range_lng,
        text = "This location does not look like it's in Singapore!"
      )
    }
  })
}
    
    
shinyApp(ui=ui, server=server)
