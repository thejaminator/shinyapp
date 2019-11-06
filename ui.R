library(shiny)
library(shinydashboard)
library(shinyTime)
library(leaflet)
library(shinydashboardPlus)
library(hms)
library(lubridate)
library(plotly)

source("global_stuff.R", local=FALSE)

ui <- dashboardPage(
  dashboardHeader(title = "Singapore Carpark Availability"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Current", tabName = 'current' ),
      menuItem("Predicted Availability", tabName = 'predict'),
      id = 'tabselected'
    ),
    textInput(inputId = 'address',
              label= "Postal Code/Address",
              value = "-"
    ),
    fluidRow(column(12, offset = 1,
                                     timeInput(inputId = 'chosen_time',"Time: ",value = Sys.time(), minute.steps = 30))
                     ),
    checkboxGroupInput(inputId = 'chosen_carparks', "Carpark Type:",carpark_types, selected = carpark_types),
    radioButtons(inputId = "format",label="Carpark Availability",
                 choices = c("Green","Yellow","Red")),
    actionButton('button', 'Show carparks')
  ),
  
  dashboardBody(
    # tags$head(tags$link(rel="stylesheet", type = "text/css", href = "custom.css")),
    
    useShinyFeedback(),
    tabItems(
      tabItem(tabName='current', leafletOutput('map'), 
              fluidRow(
                column(5, plotlyOutput(outputId = "plot")), 
                column (5, tableOutput('table'), htmlOutput('link')),
                column(2, textOutput('weather'), textOutput('temp'))
              )),
      tabItem(tabName='predict', h2('output another map'))
    )
  )
)