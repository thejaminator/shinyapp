library(shiny)
library(shinydashboard)
library(shinyTime)
library(leaflet)
library(shinydashboardPlus)
library(hms)
library(lubridate)

ui <- dashboardPage(
  dashboardHeader(title = "Singapore Carpark Availability"),
  dashboardSidebar(
    textInput(inputId = 'address',
              label= "Where Are You Planning To Go?",
              value = "-"),
    radioButtons(inputId = "format",label="Carpark Availability",
                 choices = c("Green","Yellow","Red")),
    checkboxGroupInput("cpchoice","Carpark Type:",choices = c("Sheltered","Open-Air"),selected = c("Sheltered","Open-Air")),
    actionButton('button', 'Find carparks')
  ),
  
  dashboardBody(
    leafletOutput("map")
  )
)