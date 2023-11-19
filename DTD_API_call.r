library(httr)
library(jsonlite)
library(xml2)
library(tidyverse)

# Adding Authentication to the R script
source("C:/Users/thoma/OneDrive - Imperial College London/Des Eng Y4/Data2Product/Coursework/NRDP_Authenticate.r")

auth_details <- get_auth_token()
token <- auth_details$token
expiration_time <- auth_details$expiration_time

# Check if token is expired before making a new request
# REDUNDANT? - Already get a new token anyway
if (is_token_expired(expiration_time)) {
  auth_details <- get_auth_token(email, password)
  token <- auth_details$token
  expiration_time <- auth_details$expiration_time
}

# Function to perform a HTTP GET request to a given URL with the token
get_nrdp_data <- function(url, token) {
  # Prepare the headers with the token
  headers <- c('X-Auth-Token' = token,
               'Content-Type' = 'application/json',
               'Accept' = '*/*')

  # Make the GET request
  response <- GET(url, add_headers(.headers=headers))
  #content_type(response) # Gives error

  # Check the response status code
  if (response$status_code == 200) {
    # If the response is OK, return the content (assuming it's a zip file)
    content <- content(response, "raw")
    return(content)
  } else {
    # If the response is not OK, return the status code and message
    return(list(status = response$status_code, message = content(response, "text")))
  }
}

# URLs for the data feeds
fares_url <- "https://opendata.nationalrail.co.uk/api/staticfeeds/2.0/fares"
routeing_url <- "https://opendata.nationalrail.co.uk/api/staticfeeds/2.0/routeing"
timetable_url <- "https://opendata.nationalrail.co.uk/api/staticfeeds/3.0/timetable"

# Perform the GET requests
#fares_data <- get_nrdp_data(fares_url, token)
#routeing_data <- get_nrdp_data(routeing_url, token)
timetable_data <- get_nrdp_data(timetable_url, token)

writeBin(timetable_data, "timetable_data.zip")



