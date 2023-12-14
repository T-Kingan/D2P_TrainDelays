# Load the httr package
library(httr)
library(jsonlite)
library(dplyr)

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

make_api_call <- function(url, body, username, password) {
  repeat {
    response <- POST(url, authenticate(username, password), body = body, encode = "json")
    if (i %% 10 == 0) {  # Print status only for every 10th call
      cat("API call to", url, "\n")
      cat("Status Code:", status_code(response), "\n")
    }

    if (status_code(response) == 200) {
      content <- content(response, "text")
      parsed_json <- fromJSON(content)
      if (i %% 10 == 0) {
        cat("API call successful. Data retrieved.\n")
      }
      return(parsed_json)
    } else if (status_code(response) == 502) {
      cat("API call failed with status 502. Retrying in 2 minutes.\n")
      Sys.sleep(5)  # Wait for 5 sec before retry
    } else if (status_code(response) == 503) {
      cat("API call failed with status 503. Retrying in 2 minutes.\n")
      Sys.sleep(60)  # Wait for 1 minute before retry
    } else {
      cat("API call failed. Status code:", status_code(response), "\n")
      stop("API call failed with status code: ", status_code(response))
    }
  }
}

# Set up API URL and credentials
metrics_url <- "https://hsp-prod.rockshore.net/api/v1/serviceMetrics"
details_url <- "https://hsp-prod.rockshore.net/api/v1/serviceDetails"


csv_file_path <- "train_journeys.csv"
new_csv_file_path <- "train_journeys_Details.csv"
# Load the CSV into dataframe
train_journeys_df <- read.csv(csv_file_path, header = TRUE, sep = ",")

new_train_journeys_df <- tryCatch({
  read.csv(new_csv_file_path, header = TRUE, sep = ",")
}, warning = function(w) {
  NULL
}, error = function(e) {
  NULL
})

# Find the last processed 'rid' in the new CSV
if (!is.null(new_train_journeys_df) && nrow(new_train_journeys_df) > 0) {
  last_processed_rid <- tail(new_train_journeys_df$rid, 1)
  # Find the corresponding row number in the old CSV
  row_to_start <- which(train_journeys_df$rid == last_processed_rid) + 1
} else {
  row_to_start <- 1
}

# Get the number of rows in the dataframe
n <- nrow(train_journeys_df)

# Start time
start_time <- Sys.time()

# Initialize timing variables and queue for rolling average
time_taken_queue <- numeric(0)
rolling_avg_length <- 10  # Length of the rolling average queue

# For each row in the dataframe, do an API call to get the details
for (i in row_to_start:n) {
  iteration_start_time <- Sys.time()  # Start time for this iteration
  
  row <- train_journeys_df[i,]
  rid <- row$rid
  details_body <- list(rid = rid)
  parsed_details_json <- make_api_call(details_url, details_body, username, password)

  # Extract details and add them to the dataframe
  train_journeys_df[i, "date_of_service"] <- parsed_details_json$serviceAttributesDetails$date_of_service
  train_journeys_df[i, "scheduled_dept"] <- parsed_details_json$serviceAttributesDetails$locations$gbtt_ptd[1]
  train_journeys_df[i, "scheduled_arr"] <- tail(parsed_details_json$serviceAttributesDetails$locations$gbtt_pta, 1)
  train_journeys_df[i, "actual_dept"] <- parsed_details_json$serviceAttributesDetails$locations$actual_td[1]
  train_journeys_df[i, "actual_arr"] <- tail(parsed_details_json$serviceAttributesDetails$locations$actual_ta, 1)
  # Concatenate all reasons into a single string
  delay_reasons_concat <- paste(parsed_details_json$serviceAttributesDetails$locations$late_canc_reason, collapse = "; ")
  train_journeys_df[i, "delay_reasons"] <- delay_reasons_concat

  # Write the updated row back to the CSV file
  if (i == 1) {
    write.csv(train_journeys_df[i,], new_csv_file_path, row.names = FALSE)
  } else {
    write.table(train_journeys_df[i,], file = new_csv_file_path, sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, quote = TRUE)
  }

  iteration_end_time <- Sys.time()  # End time for this iteration
  time_taken <- iteration_end_time - iteration_start_time  # Time taken for this iteration
  # Update the queue and calculate rolling average
  time_taken_queue <- c(time_taken_queue, as.numeric(time_taken))
  if (length(time_taken_queue) > rolling_avg_length) {
    time_taken_queue <- time_taken_queue[-1]  # Remove the oldest time
  }
  average_time_per_iteration <- mean(time_taken_queue)
  estimated_time_left <- average_time_per_iteration * (n - i)

  if (i %% 10 == 0) {  # Print estimated time only for every 10th iteration
    cat("Processed row", i, "of", n, ". Estimated time left:", round(estimated_time_left, 2), "seconds\n")
  }

}