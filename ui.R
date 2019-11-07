library(shiny)
library(shinydashboard)
library(shinyTime)
library(leaflet)
library(shinydashboardPlus)
library(hms)
library(lubridate)
library(plotly)
library(shinyFeedback)

## get latest time. Making it a function makes the ui check for latest time every time a page is requested
get_latest_time <- function(){
  latestTime
}

ui_time<-get_latest_time()

ui <- fluidPage(tags$head(
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
      menuItem("Current", tabName = 'current' )
    ),
    textInput(inputId = 'address',
              label= "Postal Code/Address",
              value = "-"
    ),

    sliderInput(inputId = 'chosen_time', 
                                 label = 'time to predict', 
                                 value = as.POSIXct(ui_time), 
                                 min = as.POSIXct(ui_time), 
                                 max = as.POSIXct(ui_time) + 24*60*60, 
                                 step = 30*60, 
                                 ticks = FALSE,
                                 timeFormat = "%m/%d/%Y %I:%M %p"),
    checkboxGroupInput(inputId = 'chosen_carparks', 
                       label = "Carpark Type:", 
                       choices = carpark_types, 
                       selected = carpark_types),
    checkboxGroupInput(inputId = "chosen_avail",label="Carpark Availability",
                       choiceNames = c("Green > 50","Orange > 20","Red < 20"), choiceValues = c("green", "orange", "red"), 
                       selected = c("green","orange","red")),
    actionButton('button', 'Show carparks')
  ),
  
  dashboardBody(
    useShinyFeedback(),
    tabItems(
      tabItem(tabName='current', leafletOutput('map'), 
              fluidRow(
                column(5, plotlyOutput(outputId = "plot")), 
                column (5, tableOutput('table'), htmlOutput('link')),
                column(2, tableOutput('weather'), textOutput("temp"), uiOutput("img"))
              ))
    )
  )
)
)
# 
# 
# 
# ui <- dashboardPage(
#   dashboardHeader(title = "Singapore Carpark Availability"),
#   dashboardSidebar(
#     sidebarMenu(
#       menuItem("Current", tabName = 'current' ),
#       menuItem("Predicted Availability", tabName = 'predict'),
#       id = 'tabselected'
#     ),
#     textInput(inputId = 'address',
#               label= "Postal Code/Address",
#               value = "-"
#     ),
#     fluidRow(column(12, offset = 1,
#                                      timeInput(inputId = 'chosen_time',"Time: ",value = Sys.time(), minute.steps = 30))
#                      ),
#     checkboxGroupInput(inputId = 'chosen_carparks', "Carpark Type:",carpark_types, selected = carpark_types),
#     checkboxGroupInput(inputId = "chosen_avail",label="Carpark Availability",
#                        choiceNames = c("Green > 50","Orange > 20","Red < 20"), choiceValues = c("green", "orange", "red"), 
#                        selected = c("green","orange","red")),
#     actionButton('button', 'Show carparks')
#   ),
#   
#   dashboardBody(
#     tags$head(tags$link(rel="stylesheet", type = "text/css", href = "custom.css")),
#     
#     useShinyFeedback(),
#     tabItems(
#       tabItem(tabName='current', leafletOutput('map'), 
#               fluidRow(
#                 column(5, plotlyOutput(outputId = "plot")), 
#                 column (5, tableOutput('table'), htmlOutput('link')),
#                 column(2, textOutput('weather'), textOutput('temp'))
#               )
#               ),
#       tabItem(tabName='predict', h2('output another map'))
#     )
#   )
# )