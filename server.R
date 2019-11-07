source("global_stuff.R", local=FALSE)
server <- function(input, output, session, ...) {
  
  # Load dataset which is run ech time user visits, so that it will be refreshed
  ### load carpark available dataset from mongo only when initialized
  carparkAvail<-getAllCarparks(limit=288, fake=TRUE)
  uniqueCarparks <- unique(carparkAvail$carpark_name)
  ### load latest time from mongo
  latestTime<-carparkAvail$time[[1]]
  
  ### get predicted carpark info
  prediction<-get_prediction_historical_2(latestTime=latestTime, carparkAvail=carparkAvail,
                                        historical_data=readRDS("./data/backup"))
                                        

  #reactive time chosen based on sidebar for predictions
  chosen_time <- reactive({
    input$chosen_time
  })
  

  #Make reactive hdb_geo_info
  hdb_geo_info_reactive <- reactive({
    cat("Debug: updating carpark availability based on chosen time\n")
    #add lot availability for chosen time
    hdb_geo_info$avail_lots <- get_avail_lots(index_df=hdb_geo_info,avail_df=prediction,latest_time=chosen_time())$avail_lots
    #somehow there is n.a in the dataframe availability
    hdb_geo_info <- hdb_geo_info %>% filter(!is.na(avail_lots))
    #add info of whether carpark should be green, orange, red for use in sidebar filter
    hdb_geo_info$lot_avail_colour <- hdb_geo_info$avail_lots %>% sapply(get_colour)
    return(hdb_geo_info)
  })

  
  #Make reactive filtered dataset based on inputs in sidebar
  carpark_info_reactive <- reactive({
    cat("Debug: updating carpark filter\n")
    cat(input$chosen_avail)
    hdb_geo_info_reactive() %>%
      filter(car_park_type %in% input$chosen_carparks) %>%
      filter(lot_avail_colour %in% input$chosen_avail) #filter based on colour
  })
  
  # need to recalculate icons based on filters
  icons_reactive <- reactive({
    cat("Debug: getting icons\n")
    get_icons(carpark_info_reactive())
  })
  
  #this is only rendered only once
  output$map <- renderLeaflet({
      map <- leaflet() %>% addTiles(options = tileOptions(useCache = TRUE, crossOrigin = TRUE)) %>% 
        setView(lng = 103.7499, lat =1.350867, zoom  = 12) 
    }) 
  
  #James to make markers work
  observe({
    data<-carpark_info_reactive()
    leafletProxy('map', data = data) %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      {if (nrow(data) > 0)
        addAwesomeMarkers(map =. ,lng = ~lon, lat = ~lat, 
                          clusterOptions = markerClusterOptions(disableClusteringAtZoom = 16), 
                          icon=icons_reactive(),
                          layerId =~car_park_no,label = ~htmlEscape(paste(avail_lots)),
                          labelOptions = labelOptions(noHide = T, direction = "bottom", 
                                                      className = "leaflet-label"))
        else cat("nothing to display. This if else statement exists to prevent crash\n")}
  
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
  
  #Stuff that happens when u click on marker
  observeEvent(input$map_marker_click, {
    #filter out data not in checkbox
    
    specific_carpark_data <- carpark_info_reactive()[carpark_info_reactive()$car_park_no==input$map_marker_click$id,]
    carpark_table <- specific_carpark_data[,c(1:7)]
    colnames(carpark_table) <- c('Car Park No.', 'Address', 'Car Park Type', 'Type of Parking System','Short-Term Parking', 'Free Parking', 'Night Parking')
    output$table <- renderTable(gather(carpark_table,'',''))
    
    
    #add link
    carpark_link <- specific_carpark_data[,c(11:12)]
    output$link <-renderText(paste0("<a target='_blank', 
                                    href = https://www.google.com/maps?daddr=", carpark_link$lat,",", carpark_link$lon,"> Go to Google Maps for Directions </a>"))
  
    
    ## Weather data stuff
    url3 <- "https://api.openweathermap.org/data/2.5/weather?"
    lat <- paste0("lat=", carpark_link$lat)
    lon <- paste0("&lon=",carpark_link$lon)
    appID<- "&APPID=a1e683f48fd044a44af31c3849470646"
    units <- "&units=metric"
    url_comp <-paste0(url3,lat,lon,appID,units)
    weather_data <- fromJSON(url_comp)
    output$temp <- renderText(paste0("Temperature: ",weather_data$main$temp," Degree Celcius"))
    output$weather <- renderText(paste0("Weather: ", weather_data$weather$main))
    
    
    plot_data <- prediction %>% 
            filter(carpark_name == paste0(input$map_marker_click$id,"_C"))   %>% 
            filter(time > latestTime - as.difftime(1, unit="days")) %>%
            filter(time < latestTime + as.difftime(1, unit="days"))# get one day before and one day after forecast
    output$plot <- renderPlotly({
      p <- ggplot(data = plot_data) + geom_line(aes(time, avail_lots, colour=is_pred), size = 0.5) + 
        xlab("Time") + 
        ylab("Lots Available") + theme_stata() + scale_x_datetime(breaks = "3 hour", labels = date_format("%H:%M")) 
      height <- session$clientData$output_p_height
      width <- session$clientData$output_p_width
      ggplotly(p, height = height, width = width)
    })
  })
  
  
}