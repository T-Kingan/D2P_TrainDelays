library(shiny)  # Web application framework for R
library(DT) # R interface to the Javascript library DataTables
library(dplyr)  # Grammar of data manipulation
library(shinyBS)  # Adds Bootsrap components to Shiny
library(shinyjs)

# Construct relative file path for the CSV file
csvFilePath <- "LookupTable_FAKE.csv"

# Read CSV data using the relative file path
train_data <- read.csv(csvFilePath)

loginUI <- fluidPage(
  useShinyjs(),  # Initialize shinyjs
  div(id = "login",
      wellPanel(
        textInput("username", "Username", value = ""),
        passwordInput("password", "Password", value = ""),
        actionButton("loginBtn", "Log in")
      )
  )
)

# Define UI for application
ui <- fluidPage(
  loginUI,
  # Use shinyjs to hide the main UI until the user logs in
  conditionalPanel(
    condition = "window.loggedIn === true", #
      # Application title
    titlePanel("Train Delay Estimator"),  
    # Top bar layout with input definitions
    fluidRow(
      column(3, selectInput("fromStation", "From:", choices = NULL, selectize = TRUE)),  # Unique ID for 'from' station
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
            uiOutput("tableOrMessage")  # Dynamically generated UI for the table or message
      )
    )
  )

)

create_credentials_file <- function(username, password) {
  # Define the path to the .gitignore subfolder and credentials.txt
  gitignore_folder <- file.path(getwd(), ".gitignore")
  credentials_file_path <- file.path(gitignore_folder, "credentials.txt")

  # Check if the .gitignore folder exists
  if (!dir.exists(gitignore_folder)) {
    # Create the .gitignore folder if it doesn't exist
    dir.create(gitignore_folder)
    cat(".gitignore folder created.\n")
  }

  # Check if credentials.txt exists in the .gitignore folder
  if (!file.exists(credentials_file_path)) {
    # Write username and password to credentials.txt
    credentials <- paste("Username:", username, "\nPassword:", password)
    writeLines(credentials, credentials_file_path)
    cat("credentials.txt file created in the .gitignore folder and credentials written.\n")
  } else {
    cat("credentials.txt already exists in the .gitignore folder.\n")
  }
}


server <- function(input, output, session) {
  observeEvent(input$loginBtn, {
    # Example: Simple authentication logic
  if (!is.null(input$username) && !is.null(input$password)) {
    create_credentials_file(input$username, input$password)
    shinyjs::runjs("window.loggedIn = true")  # Set JavaScript variable on successful login
    shinyjs::hide("login")  # Hide the login UI
  } else {
      shinyjs::alert("Incorrect username or password!")
    }
  })

  # Define a vector of all supported stations
  all_stations <- c("EDB", "KGX", "LST", "PAD", "VIC", "WAT", "CTK", "Other station codes...")
  to_stations <- "EDB"
  from_stations <- "KGX"

  # Observer to update the 'To' station input based on user typing
  observe({
    search_term <- isolate(input$toStation)
    
    # If the search term is NULL or empty, set the choices to all stations
    if (is.null(search_term) || search_term == "") {
      updateSelectInput(session, "toStation", choices = to_stations)
    } else {
      # Filter the stations based on the search term
      filtered_stations <- to_stations[grepl(paste0("^", search_term), to_stations, ignore.case = TRUE)]
      # Update the 'To' station choices
      updateSelectInput(session, "toStation", choices = filtered_stations)
    }
  })

  # Observer to update the 'From' station input based on user typing
  observe({
    search_term <- isolate(input$fromStation)
    
    # If the search term is NULL or empty, set the choices to all stations
    if (is.null(search_term) || search_term == "") {
      updateSelectInput(session, "fromStation", choices = from_stations)
    } else {
      # Filter the stations based on the search term
      filtered_stations <- from_stations[grepl(paste0("^", search_term), from_stations, ignore.case = TRUE)]
      # Update the 'From' station choices
      updateSelectInput(session, "fromStation", choices = filtered_stations)
    }
  })

  
  selected_delay_columns <- reactive({
    if (input$selectInputID == "I'm getting married") {
      return(c("Delay_Low", "Delay_Arrival_Low"))
    } else if (input$selectInputID == "Not too worried") {
      return(c("Delay_Medium", "Delay_Arrival_Medium"))
    } else if (input$selectInputID == "Get me there today") {
      return(c("Delay_High", "Delay_Arrival_High"))
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
    # sort by departure time
    filtered_data <- filtered_data[order(filtered_data$Departure.Time),]

    # Check if filtered_data is empty
    if (nrow(filtered_data) == 0) {
      return(NULL)
    }

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

    # for variables in df:
    #   if type is time:
    #     convert to time HH:MM
    #   if type is number:
    #     round to nearest integer
    df <- df %>%
      mutate(
        ScheduledDepartureTime = format(strptime(ScheduledDepartureTime, format = "%H:%M:%S"), format = "%H:%M"),
        ScheduledArrivalTime = format(strptime(ScheduledArrivalTime, format = "%H:%M:%S"), format = "%H:%M"),
        Delay_Low = round(as.numeric(Delay_Low)),
        Delay_Medium = round(as.numeric(Delay_Medium)),
        Delay_High = round(as.numeric(Delay_High)),
        # If you have other time columns, repeat the format conversion for those as well
        Delay_Arrival_Low = format(strptime(Delay_Arrival_Low, format = "%H:%M:%S"), format = "%H:%M"),
        Delay_Arrival_Medium = format(strptime(Delay_Arrival_Medium, format = "%H:%M:%S"), format = "%H:%M"),
        Delay_Arrival_High = format(strptime(Delay_Arrival_High, format = "%H:%M:%S"), format = "%H:%M")
      )

    print(df)
    # Create a bar
    # need to change based on risk appetite

    # Get the name of the selected delay column
    delay_col_name <- selected_delay_columns()[1]
    # Ensure the delay column is treated as numeric
    delay_num <- as.numeric(df[[delay_col_name]])
    
    df$DelayBar <- sapply(delay_num, function(delay) {
      paste0('<div style="background-color:', 
             ifelse(delay <= 5, 'green', ifelse(delay <= 15, 'yellow', 'red')), 
             '; width:', delay * 5, 'px; height:20px;"></div>')
    })

    # # Add DelayBar to the dataframe
    # df$DelayBar <- sapply(df$DelayMins, function(delay) {
    #   paste0('<div style="background-color:', 
    #          ifelse(delay <= 5, 'green', ifelse(delay <= 15, 'yellow', 'red')), 
    #          '; width:', delay * 5, 'px; height:20px;"></div>')
    # })



    df
  })
  
  # Dynamically render the data table or a message if no data is available
  output$tableOrMessage <- renderUI({
    if (is.null(data()) || nrow(data()) == 0) {
      # Display a message when no data is available
      div(
        class = "no-data-message",
        HTML("No predictions available for the selected date.")
      )
    } else {
      # Render the data table when data is available
      DT::dataTableOutput("scheduleTable")
    }
  })

  # Generate the schedule table with the delay bars
  output$scheduleTable <- DT::renderDataTable({
    # Use the selected delay columns
    delay_cols <- selected_delay_columns()

    if (is.null(data())) {
      return(NULL)
    }

    df <- data() %>%
      select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar, all_of(delay_cols))

    # select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar) # Reorder columns
    # select(ScheduledDepartureTime, ScheduledArrivalTime, DelayBar,
    #          if (input$selectInputID == "I'm getting married") Delay_Arrival_Low
    #          else if (input$selectInputID == "Not too worried") Delay_Arrival_Medium
    #          else if (input$selectInputID == "Get me there today") Delay_Arrival_High
    #   ) # Reorder columns

    datatable(df, options = list(
      scrollY = '600px', # Increase the scrolling area for the DataTable
      scrollX = TRUE,    # Enable horizontal scrolling
      scrollCollapse = TRUE,
      paging = FALSE,
      searching = FALSE # Disable the searchbar
    ), rownames = FALSE, escape = FALSE) %>% # Correct placement of escape = FALSE
    formatStyle('ScheduledDepartureTime', backgroundColor = 'lightblue', color = 'black') #%>% # Format the departure time column
  })
}

# Run the application
shinyApp(ui = ui, server = server)
