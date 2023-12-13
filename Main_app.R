library(shiny)  # Web application framework for R
library(DT) # R interface to the Javascript library DataTables
library(dplyr)  # Grammar of data manipulation
library(shinyBS)  # Adds Bootsrap components to Shiny

getTrainData <- function(from_station, to_station, date, risk_appetite){
  # Data retrieval code goes here
}

train_data <- read.csv("C:/Users/thoma/OneDrive - Imperial College London/Des Eng Y4/Data2Product/Git/Data2Product/LookupTable_FAKE.csv")
#train_data <- read.csv("LookupTable_FAKE.csv")
# "C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Git\Data2Product\LookupTable_FAKE.csv"

# Define UI for application
ui <- fluidPage(
  # Application title
  titlePanel("Train Delay Estimator"),
  
  # Top bar layout with input definitions
  fluidRow(
    column(3, textInput("fromStation", "From:", value = "")),  # Unique ID for 'from' station
    column(3, selectInput("toStation", "To:", choices = NULL, selectize = TRUE)),
    column(3, dateInput("date", "Date:", value = Sys.Date())),
    column(3, 
           # A container with CSS flexbox styling for alignment
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

server <- function(input, output, session) {
  # Define a vector of all supported stations
  all_stations <- c("EDB", "KGX", "LST", "PAD", "VIC", "WAT", "CTK", "Other station codes...")

  # Observer to update the 'To' station input based on user typing
  observe({
    search_term <- isolate(input$toStation)
    
    # If the search term is NULL or empty, set the choices to all stations
    if (is.null(search_term) || search_term == "") {
      updateSelectInput(session, "toStation", choices = all_stations)
    } else {
      # Filter the stations based on the search term
      filtered_stations <- all_stations[grepl(paste0("^", search_term), all_stations, ignore.case = TRUE)]
      # Update the 'To' station choices
      updateSelectInput(session, "toStation", choices = filtered_stations)
    }
  })
  
  # Placeholder for actual data - need to fetch and process data based on the input
  data <- reactive({   # will re-run when input$fromStation, input$toStation, or input$date changes

    # Validate the station inputs
    validate(
      need(input$fromStation %in% c("EDB", "KGX", "ADD_SUPPORTED_STATIONS_HERE"), "The 'From' station is not supported."),
      need(input$toStation %in% c("EDB", "KGX", "ADD_SUPPORTED_STATIONS_HERE"), "The 'To' station is not supported.")
    )
    # Fetch data based on input$fromStation, input$toStation, and input$date
    # Convert the delay to a numeric value and add it to the dataframe
    print(format(input$date,"%d/%m/%Y"))
    filtered_data <- train_data %>% 
      filter(Date == format(input$date,"%d/%m/%Y"))
    #print(filtered_data)

    # Placeholder data
    # df <- data.frame(
    #   ScheduledDepartureTime = c("18:00", "18:20", "18:45", "19:05", "19:20", "19:32", "19:55"),
    #   ScheduledArrivalTime = c("19:00", "19:20", "19:45", "20:05", "20:20", "20:32", "20:55"),
    #   EstDelay = c("2 mins", "3 mins", "20 mins", "15 mins", "6 mins", "7 mins", "15 mins"),
    #   DelayMins = c(2, 3, 20, 15, 6, 7, 15),  # Numeric values for the delays
    #   EstimatedArrivalTime = c("21:00", "21:30", "19:45", "20:05", "20:20", "20:32", "20:55"),
    #   stringsAsFactors = FALSE
    # )

    df <- data.frame(
      ScheduledDepartureTime = filtered_data$Departure.Time,
      ScheduledArrivalTime = filtered_data$Arrival.Time,
      EstDelay = filtered_data$Delay,
      Delay_Low = filtered_data$Delay_Low,
      Delay_Arrival_Low = filtered_data$Delayed.Arrival.Time_Low,
      Delay_Medium = filtered_data$Delay_Medium,
      Delay_Arrival_Medium = filtered_data$Delayed.Arrival.Time_Medium,
      Delay_High = filtered_data$Delay_High,
      Delay_Arrival_High = filtered_data$Delayed.Arrival.Time_High
    )
    print(df)
    # Create a bar
    # need to change based on risk appetite

    

    df$DelayBar <- sapply(df$EstDelay, function(delay) {
      paste0('<div style="background-color:', 
             ifelse(delay <= 5, 'green', ifelse(delay <= 15, 'yellow', 'red')), 
             '; width:', delay * 5, 'px; height:20px;"></div>')
    })
    df
  })
  
  # Generate the schedule table with the delay bars
  output$scheduleTable <- DT::renderDataTable({
    df <- data() %>%
      select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar) # Reorder columns
    # select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar,
    #          if (input$selectInputID == "I'm getting married") Delay_Arrival_Low
    #          else if (input$selectInputID == "Not too worried") Delay_Arrival_Medium
    #          else if (input$selectInputID == "Get me there today") Delay_Arrival_High
    #   ) # Reorder columns
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
