# Script to retrieve HSP Metrics data and store in a CSV file
library(httr)
library(jsonlite)
library(dplyr)
library(lubridate) # For date manipulation

# Path to CSV file to store the results
csv_file_path <- "train_journeys.csv"

# Function to read username and password from a .txt file
read_login_details <- function() {
  login_file <- ".gitignore/credentials.txt"
  if (file.exists(login_file)) {
    lines <- readLines(login_file)
    #print(lines)
    username <- NULL
    password <- NULL
    
    for (line in lines) {
      parts <- strsplit(line, ":")[[1]]  # Access the first (and only) element of the list
      if (length(parts) == 2) {
        key <- trimws(parts[1])   # Trim whitespace from the key
        value <- trimws(parts[2]) # Trim whitespace from the value

        if (key == "Username") {
          username <- value
        } else if (key == "Password") {
          password <- value
        }
      }
    }
    
    if (!is.null(username) && !is.null(password)) {
      return(list(username = username, password = password))
    } else {
      print(username)
      print(password)
      stop("Invalid format in credentials.txt. It should contain 'Username:' and 'Password:' lines.")
    }
  } else {
    stop("credentials.txt not found in the .gitignore subfolder.")
  }
}

# Get the username and password from the .txt file
login_info <- read_login_details()
username <- login_info$username
password <- login_info$password

# Function to make API calls with error handling
make_api_call <- function(url, body, username, password) {
  repeat {
    cat("Starting API call at", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")  # Add timestamp
    response <- POST(url, authenticate(username, password), body = body, encode = "json")
    cat("API call to", url, "\n")
    cat("Status Code:", status_code(response), "\n")
    
    if (status_code(response) == 200) {
      content <- content(response, "text")
      parsed_json <- fromJSON(content)
      cat("API call successful. Data retrieved.\n")
      return(parsed_json)
    } else {
      cat("API call failed. Status code:", status_code(response), "\n")
      if (status_code(response) == 502) {
        Sys.sleep(5) # Wait for 2 minutes before retry
      } else {
        stop("API call failed with status code: ", status_code(response))
      }
    }
  }
}

# Set up API URL, credentials, and other variables
metrics_url <- "https://hsp-prod.rockshore.net/api/v1/serviceMetrics"

start_date <- as.Date("2021-01-01")
end_date <- Sys.Date()
day_types <- c("WEEKDAY", "SATURDAY", "SUNDAY")

# Function to process dates in 2-week intervals
process_dates <- function(start_date, end_date) {
  interval_end <- min(start_date + days(13), end_date) # Limit to 2 weeks
  return(list(start = start_date, end = interval_end))
}

# Initialize or load existing dataframe
tryCatch({
    combined_results_df <- read.csv(csv_file_path, stringsAsFactors = FALSE)
    # Check if the dataframe is empty or has incorrect columns
    if (ncol(combined_results_df) != 4 || !all(c("rid", "gbtt_ptd", "gbtt_pta", "day_type") %in% names(combined_results_df))) {
        cat("CSV file is empty or has incorrect format. Initializing a new dataframe.\n")
        combined_results_df <- data.frame(rid = character(), gbtt_ptd = character(), gbtt_pta = character(), day_type = character(), stringsAsFactors = FALSE)
    }
}, error = function(e) {
    cat("Error reading CSV file: ", e$message, "\nInitializing a new dataframe.\n")
    combined_results_df <- data.frame(rid = character(), gbtt_ptd = character(), gbtt_pta = character(), day_type = character(), stringsAsFactors = FALSE)
})

# Timing variables
total_calls <- 0
total_time_taken <- 0

# Main loop to process each 2-week period
while(start_date <= end_date) {
  dates <- process_dates(start_date, end_date)
  start_date <- dates$end + days(1) # Update start date for next iteration

  for (day in day_types) {
    metrics_body <- list(
      from_loc = "KGX", to_loc = "EDB", 
      from_time = "0000", to_time = "2359", 
      from_date = format(dates$start, "%Y-%m-%d"), 
      to_date = format(dates$end, "%Y-%m-%d"), 
      days = day
    )

    cat("Making API call for", day, "from", format(dates$start, "%Y-%m-%d"), "to", format(dates$end, "%Y-%m-%d"), "\n")
    start_call_time <- Sys.time()
    parsed_metrics_json <- make_api_call(metrics_url, metrics_body, username, password)
    end_call_time <- Sys.time()

    # Calculate duration and update timing variables
    call_duration <- end_call_time - start_call_time
    total_calls <- total_calls + 1
    total_time_taken <- total_time_taken + call_duration

    # Estimate remaining time
    average_time_per_call <- total_time_taken / total_calls
    estimated_calls_left <- length(day_types) * as.numeric(difftime(end_date, start_date, units = "days")) / 14
    estimated_time_left <- average_time_per_call * estimated_calls_left

    cat("Estimated time left:", round(estimated_time_left, 2), "seconds\n")

    # Process parsed_metrics_json and append to combined_results_df as earlier
    # ...
        # extract the list parsed_metrics_json$Services$serviceAttributesMetrics$rids
    rids <- parsed_metrics_json$Services$serviceAttributesMetrics$rids
    gbtt_ptd <- parsed_metrics_json$Services$serviceAttributesMetrics$gbtt_ptd
    gbtt_pta <- parsed_metrics_json$Services$serviceAttributesMetrics$gbtt_pta

    # Initialize an empty dataframe to store the results for this day type
    result_df <- data.frame(rid = character(), gbtt_ptd = character(), gbtt_pta = character(), day_type = character(), stringsAsFactors = FALSE)

    # for loop to iterate through each rid
    for (i in seq_along(rids)) {
        current_rids <- rids[[i]]
        current_gbtt_ptd <- gbtt_ptd[i]
        current_gbtt_pta <- gbtt_pta[i]

        # Create a temporary dataframe for the current set of rids
        temp_df <- data.frame(rid = current_rids, gbtt_ptd = rep(current_gbtt_ptd, length(current_rids)), gbtt_pta = rep(current_gbtt_pta, length(current_rids)), day_type = rep(day, length(current_rids)), stringsAsFactors = FALSE)

        # Bind the temporary dataframe to the result dataframe
        result_df <- rbind(result_df, temp_df)    
    }
    # Combine the results for this day type with the overall results
    cat("Structure of combined_results_df:\n")
    str(combined_results_df)
    cat("Structure of result_df:\n")
    str(result_df)
    combined_results_df <- rbind(combined_results_df, result_df)
    # error possibly arrising from combined_results_df being added to each time rather than re-assigned

  }
  
  # Write or append to CSV after each 2-week period is processed
  write.csv(combined_results_df, csv_file_path, row.names = FALSE)
}
