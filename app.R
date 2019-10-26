#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(plotly)

# load module functions
source("modules/mongo.R")


### load carpark dataset from mongo only when initialized
carparkAvail<-getAllCarparks(limit=500, fake=TRUE) #use fake=TRUE to avoid calling mongodb and use bakcup
uniqueCarparks <- unique(carparkAvail$carpark_name)
### load latest time from mongo
latestTime<-carparkAvail$time[[1]]

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
    ## Fetch relevant carpark data as chosen in input$uniqueCarparks ##
    datasetInput <- reactive({
        carparkAvail %>%
            filter(carpark_name %in% input$chosenCarparks)
    })
    
    # Show the number of availability and maximum number of lots##
    output$avail_table<- renderTable({
        df<-datasetInput() %>% filter(time == latestTime) %>% select(carpark_name, avail_lots)
        head(df)
    })

    ## Plot the graph of availability ###
    output$plot <- renderPlotly({
        req(input$chosenCarparks)
        if (identical(input$chosenCarparks, "")) return(NULL)
        #multiple plots
        p <- ggplot(data = datasetInput()) + 
            geom_line(aes(time, avail_lots, group = carpark_name))
        height <- session$clientData$output_p_height
        width <- session$clientData$output_p_width
        ggplotly(p, height = height, width = width)
    })
    
}

shinyApp(ui, server)