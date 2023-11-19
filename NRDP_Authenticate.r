# Authentication with the National Rail Data Portal

library(httr)
library(jsonlite)
library(xml2)
library(tidyverse)

setwd("C:/Users/thoma/OneDrive - Imperial College London/Des Eng Y4/Data2Product/Coursework")
source("C:/Users/thoma/OneDrive - Imperial College London/Des Eng Y4/Data2Product/Coursework/login_details.r")
#C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Coursework\login_details.r

# Function to authenticate and get token (JSON)
get_auth_token <- function() {   #function(email, password)
  body <- list(username = email, password = password)
  response <- POST(
    url = "https://opendata.nationalrail.co.uk/authenticate",
    body = body,
    encode = "form",
    content_type("application/x-www-form-urlencoded") # format of the data sent in the body
  )
  
  if (response$status_code == 200) {
    content <- content(response, "text")
    parsed_content <- fromJSON(content)
    token <- parsed_content$token
    expiration_time <- as.numeric(strsplit(token, ":")[[1]][2])
    
    list(token = token, expiration_time = expiration_time) # Return the token and expiration time
    # ^Because it is part of the function
  } else {
    content <- content(response, "text")
    error_message <- fromJSON(content)
    stop(paste("Authentication failed:", error_message$error))
  }
}

# Function to check if the token is expired
is_token_expired <- function(expiration_time) {
  current_time <- as.numeric(Sys.time())
  # Check if the current UNIX time is greater than the expiration time
  current_time > (expiration_time / 1000)
}