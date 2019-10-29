
source("global_stuff.R", local=FALSE)
server <- function(input, output, session, ...) {
  #Make reactive dataset based on inputs in sidebar
  carpark_info_reactive <- reactive({
    cat("Debug: updating carpark filter\n")
    hdb_geo_info %>%
      filter(car_park_type %in% input$chosen_carparks)
  })
  
  icons_reactive <- reactive({
    cat("Debug: getting icons\n")
    get_icons(carpark_info_reactive(), avail_lots=avail_lots)
  })
  
  output$map <- renderLeaflet({
      map <- leaflet() %>% addTiles() %>% setView(lng = 103.7499, lat =1.350867, zoom  = 12)
    }) 
  
  #James try to make markers work
  observe({
    data<-carpark_info_reactive()
    leafletProxy('map', data = data) %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      {if (nrow(data) > 0)
        addAwesomeMarkers(map =. ,lng = ~lon, lat = ~lat, clusterOptions = markerClusterOptions(disableClusteringAtZoom = 16), icon=icons_reactive(),
                          layerId =~car_park_no,label = ~htmlEscape(paste(avail_lots)), labelOptions = labelOptions(noHide = T))
        else cat("nothing to display. This if else statement exists to prevent crash\n")}
  
    
    # leafletProxy("map") %>% clearMarkers()
  })
  

  
  #Handles search input and zooms to coords
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