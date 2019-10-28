library(shiny)
library(shinydashboard)
library(shinyTime)
library(leaflet)
library(shinydashboardPlus)
library(hms)
library(lubridate)
icon.glyphicon <- makeAwesomeIcon(icon= 'flag', markerColor = 'blue', iconColor = 'black')
ui <- dashboardPage(
  dashboardHeader(title = "Singapore Carpark Availability"),
  dashboardSidebar(
    textInput(inputId = 'address',
              label= "Where Are You Planning To Go?",
              value = "-"),
    radioButtons(inputId = "format",label="Carpark Availability",
                 choices = c("Green(>30 Lots)","Yellow (30-10 Lots)","Red (<10 Lots)")),
    checkboxGroupInput("cpchoice","Carpark Type:",choices = c("Sheltered","Open-Air"),selected = c("Sheltered","Open-Air")),
    actionButton('button', 'Find carparks')
  ),
  
  dashboardBody(
    leafletOutput("map")
  )
)

timeInput("Time","Time: ",value = Sys.time(),minute.steps = 30)