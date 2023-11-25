library(shiny)
library(DT)
library(dplyr)
library(shinyBS)


# Define UI for application
ui <- fluidPage(
  # Application title
  titlePanel("Train Delay Estimator"),
  
  # Top bar layout with input definitions
  fluidRow(
    column(3, textInput("fromStation", "From:", value = "EDB")),  # Unique ID for 'from' station
    column(3, textInput("toStation", "To:", value = "KGX")),      # Unique ID for 'to' station
    column(3, dateInput("date", "Date:", value = Sys.Date())),
    column(3, 
           # Place elements inline
           div(style = "display: flex; align-items: center;",  # Use flexbox for alignment
               actionButton("infoBtn", label = icon("info-circle"), class = "btn-xs", style = "margin-left: 5px;"),
               bsTooltip("infoBtn", "This is information about Risk Appetite", "right", trigger = "click hover"),
               selectInput("selectInputID", "Risk Appetite", choices = c("I'm getting married", "Not too worried", "Get me there today"))

           )
    )
  ),
  
  # DataTable within the full-width column for alignment
  fluidRow(
    column(12, 
           DT::dataTableOutput("scheduleTable") # DataTable output
    )
  )
)

server <- function(input, output) {
  
  # Placeholder for actual data - need to fetch and process data based on the input
  data <- reactive({   # will re-run when input$fromStation, input$toStation, or input$date changes
    # Fetch data based on input$fromStation, input$toStation, and input$date
    # Convert the delay to a numeric value and add it to the dataframe
    df <- data.frame(
      ScheduledDepartureTime = c("18:00", "18:20", "18:45", "19:05", "19:20", "19:32", "19:55"),
      ScheduledArrivalTime = c("19:00", "19:20", "19:45", "20:05", "20:20", "20:32", "20:55"),
      EstDelay = c("2 mins", "3 mins", "20 mins", "15 mins", "6 mins", "7 mins", "15 mins"),
      DelayMins = c(2, 3, 20, 15, 6, 7, 15),  # Numeric values for the delays
      EstimatedArrivalTime = c("21:00", "21:30", "19:45", "20:05", "20:20", "20:32", "20:55"),
      stringsAsFactors = FALSE
    )
    # Create a bar
    df$DelayBar <- sapply(df$DelayMins, function(delay) {
      paste0('<div style="background-color:', 
             ifelse(delay <= 5, 'green', ifelse(delay <= 15, 'yellow', 'red')), 
             '; width:', delay * 5, 'px; height:20px;"></div>')
    })
    df
  })
  
  # Generate the schedule table with the delay bars
  output$scheduleTable <- DT::renderDataTable({
    df <- data() %>%
      select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar, EstimatedArrivalTime) # Reorder columns
    
    datatable(df, options = list(
      scrollY = '200px',
      scrollCollapse = TRUE,
      paging = FALSE,
      searching = FALSE # Disable the searchbar
    ), rownames = FALSE, escape = FALSE) %>% # Correct placement of escape = FALSE
    formatStyle('ScheduledDepartureTime', backgroundColor = 'lightblue', color = 'black') #%>% # Format the departure time column
  })
}

# Run the application
shinyApp(ui = ui, server = server)
