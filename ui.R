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
    conditionalPanel("input.tabselected == 'predict'",
                     fluidRow(column(12, offset = 1,
                                     timeInput("Time","Time: ",value = Sys.time(), minute.steps = 30))
                     )),
    checkboxGroupInput(inputId = 'chosen_carparks', "Carpark Type:",carpark_types, selected = carpark_types),
    radioButtons(inputId = "format",label="Carpark Availability",
                 choices = c("Green","Yellow","Red")),
    actionButton('button', 'Show carparks')
  ),
  
  dashboardBody(
    useShinyFeedback(),
    tabItems(
      tabItem(tabName='current', leafletOutput('map'), plotlyOutput(outputId = "plot"), htmlOutput('link')),
      tabItem(tabName='predict', h2('output another map'))
    )
  )
)