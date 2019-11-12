library(shiny)
library(shinydashboard)
library(shinyTime)
library(leaflet)
library(shinydashboardPlus)
library(hms)
library(lubridate)
library(plotly)
library(shinyFeedback)



ui <- fluidPage(
  #allows search by enter button
  tags$script(HTML(
  '$(document).keyup(function(e) {
      if (e.key == "Enter") {
        $("#button").click();
      }});'
  )),
  tags$head(
  #set up css
  tags$link(rel = "stylesheet", 
            type = "text/css", 
            href = "custom.css"),
  tags$link(rel="stylesheet",
            href="https://fonts.googleapis.com/css?family=Josefin+Sans&display=swap"),
  tags$link(rel="stylesheet",
            href="https://fonts.googleapis.com/css?family=Muli&display=swap"),
  tags$style(".fa-sun-o {color:#7e97a6}")
),

dashboardPage(
  dashboardHeader(
    dropdownMenuOutput('weather_menu'),
    title = "parkwhere.sg"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("carpark lot availability", tabName = 'current' )
    ),
    tagAppendAttributes(textInput(inputId = 'address',
              label= "Postal Code/Address",
              value = "bugis"),`data-proxy-click` = "button"
    ),
    actionButton('button', 'Search carparks'),
    uiOutput("time_control"),
    #time to park car
    uiOutput("carpark_duration_control"),
    htmlOutput('carpark_price'),
    checkboxGroupInput(inputId = 'chosen_carparks', 
                       label = "Carpark Type:", 
                       choices = carpark_types, 
                       selected = carpark_types),
    checkboxGroupInput(inputId = "chosen_avail",label="Carpark Availability",
                       choiceNames = c("Green > 50","Orange > 20","Red < 20"), choiceValues = c("green", "orange", "red"), 
                       selected = c("green","orange","red"))

  ),
  
  dashboardBody(
    useShinyFeedback(),
    tabItems(
      tabItem(tabName='current', leafletOutput('map'), 
              fluidRow(
                column(5, plotlyOutput(outputId = "plot")), 
                column(4, tableOutput('table')),
                column(2, tableOutput('weather'))
              ))
    )
  )
)
)
