
source("global_stuff.R", local=FALSE)
server <- function(input, output, session, ...) {
  #Make reactive input
  # carpark_info_selected <- reactive({
  #   hdb_geo_info %>%
  #     filter(car_park_type %in% input$chosen_carparks)
  # })
  
  output$map <- renderLeaflet({
      map <- leaflet() %>% addTiles()
      # %>% addAwesomeMarkers(data = hdb_geo_info, icon = icons,
      #                             lng = ~lon, lat = ~lat, label = ~htmlEscape(paste(avail_lots)),
      #                             labelOptions = labelOptions(noHide = T), clusterOptions = markerClusterOptions(disableClusteringAtZoom = 16))
      map <- addAwesomeMarkers(map, data = hdb_geo_info, lng = ~lon, lat = ~lat, layerId =~car_park_no, label = ~htmlEscape(paste(avail_lots)), icon=icons,
                                 labelOptions = labelOptions(noHide = T), clusterOptions = markerClusterOptions(disableClusteringAtZoom = 16))
    }) #logic in map_functions

  observeEvent(input$chosen_carparks,{
    #THis doesbn't work LOL
    # cat((hdb_geo_info[!hdb_geo_info$car_park_type %in% input$chosen_carparks,]$car_park_no) %>% as.character)
    # leafletProxy('map') %>% removeMarker(hdb_geo_info$car_park_no %>% as.character)
    leafletProxy('map') %>% removeMarker(layerId = (hdb_geo_info[!hdb_geo_info$car_park_type %in% c('BASEMENT CAR PARK'),])$car_park_no %>% as.character)
    # leafletProxy('map') %>% removeMarker(layerId = hdb_geo_info[!hdb_geo_info$car_park_type %in% input$chosen_carparks, 'car_park_no'])
  })
  
  # hdb_geo_info[hdb_geo_info$car_park_type %in% c('BASEMENT CAR PARK'), "car_park_no"]
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
  
  #for map filter
  observeEvent(input$map_marker_click, {
    carpark_link <- hdb_geo_info[hdb_geo_info$car_park_no==input$map_marker_click$id,]
    output$link <- renderText(paste0("<a href = https://www.google.com/maps?daddr=", carpark_link$lat,",", carpark_link$lon,"> Go there now </a>"))
    output$plot <- renderPlotly({
      # req(input$map_marker_click$id)
      # if (identical(input$chosenCarparks, "")) return(NULL)
      #multiple plots
      plot_data <- carparkAvail %>% filter(carpark_name == paste0(input$map_marker_click$id,"_C"))
      p <- ggplot(data = plot_data) + 
        geom_line(aes(time, avail_lots))
      height <- session$clientData$output_p_height
      width <- session$clientData$output_p_width
      ggplotly(p, height = height, width = width)
    })
  })
  
}