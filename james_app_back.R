library(shiny)
library(ggplot2)
library(plotly)

ui <- fluidPage(
  ### Side bar Panel
  sidebarPanel(
    #dropdown to select carparks
    selectizeInput(
      inputId = "chosenCarparks", 
      label = NULL,
      # placeholder is enabled when 1st choice is an empty string
      choices = c("Please choose a carpark" = "", uniqueCarparks), 
      multiple = TRUE
    ),
    # Output: HTML table with requested number of observations ----
    tableOutput(outputId ="avail_table")
  ),
  
  ### Main Panel ###
  ### Plot ###
  mainPanel(
    plotlyOutput(outputId = "plot")
    
  )
)


server <- function(input, output, session, ...) {
  ### Reactive variable set up ###
  ## Fetch relevant carpark data as chosen in input$uniqueCarparks ##
  avail_react <- reactive({
    carparkAvail %>%
      filter(carpark_name %in% input$chosenCarparks)
  })
  carpark_attr_react <- reactive({
    carparkAvail %>%
      filter(carpark_name %in% input$chosenCarparks)
  })
  
  ### End reactive variable set up ###
  
  # Show the number of availability and maximum number of lots##
  output$avail_table<- renderTable({
    req(input$chosenCarparks)
    df<-avail_react() %>% filter(time == latestTime) %>% select(carpark_name, avail_lots)
    head(df)
  })
  
  ## Plot the graph of availability ###
  output$plot <- renderPlotly({
    req(input$chosenCarparks)
    if (identical(input$chosenCarparks, "")) return(NULL)
    #multiple plots
    p <- ggplot(data = avail_react()) + 
      geom_line(aes(time, avail_lots, group = carpark_name))
    height <- session$clientData$output_p_height
    width <- session$clientData$output_p_width
    ggplotly(p, height = height, width = width)
  })
  
}