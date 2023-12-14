library(shiny)   # Web application framework for R
library(DT)      # R interface to the DataTables JavaScript library
library(dplyr)   # Data manipulation package
library(shinyBS) # Adds Bootstrap components to Shiny
library(shinyjs) # Easily improve the user experience of your Shiny apps

# Set the file path for the CSV file
csvFilePath <- "lookup_table.csv"

# Read CSV data
train_data <- read.csv(csvFilePath)

# Function to pad times with leading zero if necessary
pad_time <- function(time) {
  time_str <- as.character(time)
  n <- nchar(time_str)
  
  if (n == 4) {
    return(time_str)
  } else if (n == 3) {
    return(paste0("0", time_str))
  } else if (n == 2) {
    return(paste0("00", time_str))
  } else if (n == 1) {
    return(paste0("000", time_str))
  } else {
    return(time_str)  # Return the original string if it doesn't match any condition
  }
}

# Apply padding to time fields and convert to HH:MM format
train_data$scheduled_dept <- format(strptime(sapply(train_data$scheduled_dept, pad_time), format = "%H%M"), format = "%H:%M")
train_data$scheduled_arr <- format(strptime(sapply(train_data$scheduled_arr, pad_time), format = "%H%M"), format = "%H:%M")


# --- Login UI ---
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

# --- Main UI ---
ui <- fluidPage(
  loginUI,
  # Use shinyjs to hide the main UI until the user logs in
  conditionalPanel(
    condition = "window.loggedIn === true", #
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
                selectInput("selectInputID", "Risk Appetite", choices = c("High urgency - I can't be late", "Medium urgency - I could maybe be late", "Low urgency - I'm not in a rush"), selected = "Medium urgency - I can be a bit late"))
                
            )
      ),
    # Key for understanding the circle colors
    fluidRow(
      column(12, 
             div(style = "padding: 10px; background-color: #f7f7f7; border-radius: 5px; margin-top: 20px; margin-bottom: 20px;",
                 tags$h4("Key:"),
                 tags$ul(
                   tags$li(tags$span(style = "height: 10px; width: 10px; background-color: red; border-radius: 50%; display: inline-block; margin-right: 5px;"), "Red Circle: Don't expect this train to be on time"),
                   tags$li(tags$span(style = "height: 10px; width: 10px; background-color: green; border-radius: 50%; display: inline-block; margin-right: 5px;"), "Green Circle: Train is expected to be on time")
                 )
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


# Function to create the credentials.txt file
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

# --- Server ---
server <- function(input, output, session) {
  # 
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


  # Placeholder for actual data - need to fetch and process data based on the input
  data <- reactive({   # will re-run when input$fromStation, input$toStation, or input$date changes

    # Validate the station inputs
    validate(
      need(input$fromStation %in% c("EDB", "KGX", "ADD_SUPPORTED_STATIONS_HERE"), "The 'From' station is not supported."),
      need(input$toStation %in% c("EDB", "KGX", "ADD_SUPPORTED_STATIONS_HERE"), "The 'To' station is not supported.")
    )
    # Fetch data based on input$fromStation, input$toStation, and input$date
    # Convert the delay to a numeric value and add it to the dataframe

    # Print the input date to check its format and value
    print(paste("Selected date:", format(input$date, "%d/%m/%Y")))
    print(head(train_data$date_of_service))  # Print the first few rows for a quick check
    
    # Convert the input date to the same format as in your dataset
    filtered_date <- format(input$date, "%d/%m/%Y")
    
    # Add a new column to train_data with the formatted date_of_service
    train_data <- train_data %>%
      mutate(formatted_date_of_service = format(as.Date(date_of_service, format = "%Y-%m-%d"), "%d/%m/%Y")) # Adjust the format as needed
    
    # Filter the data and sort by scheduled_dept
    filtered_data <- train_data %>%
      filter(formatted_date_of_service == filtered_date) %>%
      arrange(scheduled_dept)

    # Print the filtered and sorted data
    print(filtered_data)

    df <- data.frame(
      ScheduledDepartureTime = filtered_data$scheduled_dept,
      ScheduledArrivalTime = filtered_data$scheduled_arr,
      high_urgency = filtered_data$high,
      medium_urgency = filtered_data$medium,
      low_urgency = filtered_data$low
    )

    print(df)

    # Define a function to create the circle HTML based on the urgency value
    create_circle_html <- function(urgency_value) {
      color <- ifelse(urgency_value == 1, "red", "green")
      paste0('<div style="border-radius: 50%; width: 20px; height: 20px; background-color: ', color, ';"></div>')
    }

    # Assuming you have high_urgency, medium_urgency, and low_urgency columns in filtered_data
    df$Circle <- if(input$selectInputID == "High urgency - I can't be late") {
      sapply(df$high_urgency, create_circle_html)
    } else if(input$selectInputID == "Medium urgency - I can be a bit late") {
      sapply(df$medium_urgency, create_circle_html)
    } else { # Low urgency
      sapply(df$low_urgency, create_circle_html)
    }

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
      #Render the data table when data is available
      DT::dataTableOutput("scheduleTable")
    }
  })

  # Generate the schedule table with the delay bars
  output$scheduleTable <- DT::renderDataTable({
    # # Use the selected delay columns
    if (is.null(data())) {
      return(NULL)
    }

    df <- data() %>%
      select(ScheduledDepartureTime, ScheduledArrivalTime, Circle)

    datatable(df, options = list(
      scrollY = '450px', # Increase the scrolling area for the DataTable
      scrollX = TRUE,    # Enable horizontal scrolling
      scrollCollapse = TRUE,
      paging = FALSE,
      searching = FALSE # Disable the searchbar
    ), rownames = FALSE, escape = FALSE) #%>% # Correct placement of escape = FALSE
    #formatStyle('ScheduledDepartureTime', backgroundColor = 'lightblue', color = 'black') #%>% # Format the departure time column
  })
}

# Run the application
shinyApp(ui = ui, server = server)
