server <- function(input, output, session, ...) {
  
  ###### START SETUP OF SESSION VARIABLES ########
  
  
  # Load dataset which is run ech time user visits, so that it will be refreshed
  ### load carpark available dataset from mongo only when initialized
  # carparkAvail<-getAllCarparks(limit=288, fake=fake)
  ### load latest time from mongo
  mongo_time<-getAllCarparks(limit=1, fake=fake, mongo_collection=mongo_collection)$time[[1]]
  cat(paste(mongo_time, "is the latest mongo time\n"))
  cat(paste(latestTime, "is the latest dataframe time\n"))
  
  #if latest time from mongo is not the latest time on the server, we need to query mongo and update the dataset
  # latestTime <- mongo_time - as.difftime(0.5, unit="days")
  num_update<-(difftime(mongo_time, latestTime, units='min') / TIME_INTERVAL)%>%as.numeric
  
  update_current_prediction<-function(num_update = num_update){
    current_lots<-getAllCarparks(limit=num_update, fake=fake, mongo_collection=mongo_collection)
    current_lots$is_pred<-FALSE
    prediction_lots<-get_6_days_ago(limit=num_update, mongo_collection=mongo_collection)
    prediction_lots$is_pred<-TRUE
    return(rbind(current_lots,prediction_lots))
  }

  if (num_update > 0) {
    cat("Trying to update availability...")
    
    #update prediction and take out the old predictions
    prediction<<-prediction  %>%
      filter( ((time>mongo_time) & (is_pred==TRUE)) | is_pred == FALSE ) %>%
      rbind (update_current_prediction(num_update = num_update),.)
    
    latestTime<<-prediction%>% filter(is_pred==FALSE) %>% .$time %>% .[1]

    cat("succesfully updated predictions and current available")
    cat(paste(latestTime, "updated the latest dataframe time\n"))
  } else{
    cat(paste(mongo_time, "is the same as the server latest dataframe no need to update dataframe\n"))
  }

  
  #set up chosen time dynamic ui
  output$time_control<- renderUI({
    sliderInput(inputId = 'chosen_time',
              label = 'when are you parking?',
              value = as.POSIXct(latestTime),
              min = as.POSIXct(latestTime),
              max = as.POSIXct(latestTime) + 24*60*60,
              step = 30*60,
              ticks = FALSE,
              timeFormat = "%m/%d/%Y %I:%M %p")})
  
  #set up the ui to get the carpark price to pay
  output$carpark_duration_control<- renderUI({
    sliderInput(inputId = 'chosen_carpark_time',
                label = 'when are you parking until?',
                value = as.POSIXct(latestTime),
                min = as.POSIXct(latestTime) +1*60*60,
                max = as.POSIXct(latestTime) + 24*60*60,
                step = 30*60,
                ticks = FALSE,
                timeFormat = "%m/%d/%Y %I:%M %p")})
  
  
  #reactive time chosen based on sidebar for predictions
  chosen_time <- reactive({
    cat("Debug: The chosen time was requested\n")
    if (is.null(input$chosen_time)) { 
      return(latestTime)#prevent crash as ui for choosing time is only updated later on
    }
    return(input$chosen_time)
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
    cat("Debug: Successfully updated carpark availability based on chosen time\n")
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
                                                      className = "leaflet-label"),
                          popup = paste0("<a target='_blank' class = 'gmaps-icon' href = https://www.google.com/maps?daddr=", data$lat,",", data$lon,"><img src='https://image.flaticon.com/icons/svg/355/355980.svg'>
                                         </a>"), popupOptions = popupOptions(closeButton = FALSE)
                          )
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
    carpark_table2<-gather(carpark_table,'','')
    names(carpark_table2) <-c("Carpark Information"," ")
    output$table <- renderTable(carpark_table2, align = "l")
    
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
    weather_table <- data.frame('Weather' = weather_data$weather$main, 'Temperature' = paste(weather_data$main$temp, '\u00B0C'))
    icon_table <- gather(weather_table,'','')
    names(icon_table) <- c("Weather"," ")
    link <- as.character(tags$a(tags$img(src="https://image.flaticon.com/icons/svg/355/355980.svg",height=50,width=50),href=gmaps_link))
    icon_table2 <- data.frame("Directions" = link)
    
    
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
  
    icon_table[,1] <- c((as.character(images)),as.character(tags$img(src="https://image.flaticon.com/icons/svg/1164/1164915.svg",height=30,width=30)))
    output$weather <- renderTable(icon_table, sanitize.text.function = function(x) x)
    # output$Directions <- renderTable(icon_table2,align = "r",sanitize.text.function = function(x) x)

    #calculate carpark price
    output$carpark_price <-renderUI({
      price<-get_carpark_price(input$chosen_time, input$chosen_carpark_time) %>% format(nsmall = 2)
      HTML(sprintf("<thead><tr><th>Price to Park</th><th>  </th></thead>
           <tbody><tr><td><img class = 'dollar-sign' src='https://image.flaticon.com/icons/svg/211/211738.svg'>
          </td><td> $%s </td></tr></tbody>
          ", price))
      
    })    
    
    
    plot_data <- prediction %>% 
      filter(carpark_name == paste0(input$map_marker_click$id,"_C"))   %>% 
      filter(time > latestTime - as.difftime(1, unit="days")) %>%
      filter(time < latestTime + as.difftime(1, unit="days"))# get one day before and one day after forecast
    #plot the graph
    output$plot <- renderPlotly({
      p <- ggplot(data = plot_data, aes(x = time, y = avail_lots, ymax = avail_lots, ymin=0, group = is_pred, text = paste0("Available Lots: ", avail_lots, "\nTime: ", time))) + 
              geom_line(aes(color=is_pred)) +
              geom_ribbon(aes(fill=is_pred),alpha=0.5) + 
               xlab("Time") +
            ylab("Lots Available") + theme_stata() + scale_x_datetime(breaks = "4 hour",
                                    labels = date_format("%l %p", tz = "Asia/Singapore")) + 
      theme(text = element_text(family= "Muli"), legend.position = "none", axis.text.x = element_text(angle=60), 
            panel.background = element_blank(), panel.grid.major = element_blank())
      height <- session$clientData$output_p_height
      width <- session$clientData$output_p_width
      gg <- ggplotly(p, tooltip = "text", height = height, width = width)
      gg %>% layout(xaxis=list(fixedrange=TRUE)) %>%  
            layout(yaxis=list(fixedrange=TRUE)) %>%#fix the range of plotly
            layout(paper_bgcolor='transparent', plot_bgcolor='transparent') %>% config(displayModeBar = F)#transparent
      #controlling the style
      # gg <- style(gg, line= list(width = 1.5))
    })
  })
  
}