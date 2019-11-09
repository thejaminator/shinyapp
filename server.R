source("global.R", local=TRUE)
server <- function(input, output, session, ...) {
  
  ###### START SETUP OF SESSION VARIABLES ########
  
  
  # Load dataset which is run ech time user visits, so that it will be refreshed
  ### load carpark available dataset from mongo only when initialized
  # carparkAvail<-getAllCarparks(limit=288, fake=fake)
  ### load latest time from mongo and set it for all sessions
  latestTime<<-getAllCarparks(limit=1, fake=fake)$time[[1]]
  
  ### get predicted carpark info
  if (fake){
    prediction<-get_prediction_historical(latestTime=latestTime, carparkAvail=getAllCarparks(limit=288, fake=fake),
                                            historical_data=readRDS("./data/backup"))
  }
  else {
    prediction<-get_prediction_historical_3(latestTime=latestTime, carparkAvail=getAllCarparks(limit=288, fake=fake),
                                            historical_data=readRDS("./data/backup"))
  }

    
  
  
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
      map <- leaflet() %>% leaflet.extras::enableTileCaching() %>%
        addTiles(options = tileOptions(useCache = TRUE, crossOrigin = TRUE)) %>% 
        setView(lng = 103.8198, lat =1.3521, zoom  = 12) %>%
        addEasyButton(easyButton(
          icon="fa-crosshairs", title="Locate Me",
          onClick=JS("function(btn, map){ map.locate({setView: true}); }")))
      
    }) 
  
  
  
  # More weather stuff
  weather_data <- data.frame("Area"= data_area[c(1:5),2],"Weather" = c(1:5),"Temperature" = c(1:5))
  for (i in 1:nrow(data_area)) {
    url3 <- "https://api.openweathermap.org/data/2.5/weather?"
    lat <- paste0("lat=",as.character(data_area$label_location.latitude[i]))
    lon <- paste0("&lon=",as.character(data_area$label_location.longitude[i]))
    appID<- "&APPID=a1e683f48fd044a44af31c3849470646"
    units <- "&units=metric"
    url_comp <-paste0(url3,lat,lon,appID,units)
    data_loop<-fromJSON(url_comp)
    weather_data$Temperature[i] <- data_loop$main$temp
    weather_data$Weather[i] <- data_loop$weather$main
  }
  
  output$weather_menu <- renderMenu({
    items <- lapply(1:5, function(i){
      notificationItem(paste0(weather_data$Area[i],": ", weather_data$Weather[i]),
                       icon = icon('sun-o')) 
    })
    dropdownMenu(type = "notification", 
                 icon = icon("cloud"), 
                 headerText = "Current Weather Updates",
                 .list = items
    )
  })
  
  
  ###### END SETUP OF SESSION VARIABLES ########
  
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
    
    # create link for google maps directions
    carpark_link <- specific_carpark_data[,c(11:12)]
    gmaps_link <- paste0("https://www.google.com/maps?daddr=", carpark_link$lat,",", carpark_link$lon)
    
    #get weather information regarding the selected marker and display it
    url3 <- "https://api.openweathermap.org/data/2.5/weather?"
    lat <- paste0("lat=", carpark_link$lat)
    lon <- paste0("&lon=",carpark_link$lon)
    appID<- "&APPID=a1e683f48fd044a44af31c3849470646"
    units <- "&units=metric"
    url_comp <-paste0(url3,lat,lon,appID,units)
    weather_data <- fromJSON(url_comp)
    weather_table <- data.frame('Weather' = weather_data$weather$main, 'Temperature' = paste(weather_data$main$temp, '\u00B0C'), 'Directions' = "Click Me for Directions!")
    icon_table <- gather(weather_table,'','')
    
    ##Respective Weather images as icons for weather description. 
    images<- if (weather_data$weather$id == 800) { # Clear Sky
      tags$img(height=30,width=30,src= "http://openweathermap.org/img/wn/01d@2x.png")
    } else if (between(weather_data$weather$id,200,299) == T) { #Thunderstorm
      tags$img(height=30,width=30, src = "http://openweathermap.org/img/wn/11d@2x.png")
    } else if (between(weather_data$weather$id,300,399) == T) { #Drizzle
      tags$img(height=30,width=30, src = "http://openweathermap.org/img/wn/09d@2x.png")
    } else if (between(weather_data$weather$id,500,599) == T) { #Rain
      tags$img(height=30,width=30, src = "http://openweathermap.org/img/wn/10d@2x.png")
    } else if (between(weather_data$weather$id,600,699) == T) { #Snow
      tags$img(height=30,width=30, src = "http://openweathermap.org/img/wn/13d@2x.png")
    } else if (between(weather_data$weather$id,700,799) == T) { #Mist, Haze etc.
      tags$img(height=30,width=30, src = "http://openweathermap.org/img/wn/50d@2x.png")
    } else if (between(weather_data$weather$id, 801, 899) == T) {
      tags$img(height=30,width=30, src = "https://image.flaticon.com/icons/svg/1163/1163726.svg")
    }
  
    icon_table[,1] <- c((as.character(images)),as.character(icon('thermometer-2')),
                        as.character(tags$a(tags$img(src="https://image.flaticon.com/icons/svg/355/355980.svg",height=30,width=30),href=gmaps_link)))
    output$weather <- renderTable(icon_table, sanitize.text.function = function(x) x)
    

    
    
    
    plot_data <- prediction %>% 
      filter(carpark_name == paste0(input$map_marker_click$id,"_C"))   %>% 
      filter(time > latestTime - as.difftime(1, unit="days")) %>%
      filter(time < latestTime + as.difftime(1, unit="days"))# get one day before and one day after forecast
    #plot the graph
    output$plot <- renderPlotly({
      p <- ggplot(data = plot_data, aes(x = time, y = avail_lots, ymax = avail_lots, ymin=0, group = is_pred, text = paste0("Available Lots: ", avail_lots, "\nTime: ", time))) + 
              geom_line(aes(linetype=is_pred, color=is_pred)) +
              geom_ribbon(aes(fill=is_pred),alpha=0.5) + xlab("Time") +
            ylab("Lots Available") + theme_stata() + scale_x_datetime(breaks = "4 hour",
            labels = date_format("%l %p")) + 
      theme(text = element_text(family= "Muli"), legend.position = "none", axis.text.x = element_text(angle=60), panel.background = element_blank())
      height <- session$clientData$output_p_height
      width <- session$clientData$output_p_width
      gg <- ggplotly(p, tooltip = "text", height = height, width = width)
      gg %>% layout(xaxis=list(fixedrange=TRUE)) %>%  layout(yaxis=list(fixedrange=TRUE)) #fix the range of plotly
      #controlling the style
      # gg <- style(gg, line= list(width = 1.5))
    })
  })
  
}