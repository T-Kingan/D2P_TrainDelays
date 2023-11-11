library(httr)
library(jsonlite)
library(xml2)
library(tidyverse)

# Function to authenticate and get token
get_auth_token <- function(email, password) {
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

get_file_with_token <- function(url, token){
  # Prepare the headers with the token
  headers <- c('X-Auth-Token' = token)

  # Make the GET request
  response <- GET(url, add_headers(.headers=headers))

  # Check the response status code
  if (response$status_code == 200) {
    # If the response is OK, return the content as text
    text_content <- content(response, "text")
    # Parse the XML content
    xml_content <- read_xml(text_content)
    return(xml_content)
  } else {
    # If the response is not OK, return the status code and message
    return(list(status = response$status_code, message = content(response, "text")))
  }
}

# ... Functions to parse the XML Data ...

# Function to convert a single XML node into a tibble row
node_to_df <- function(node) {
  # Obtain all child nodes
  children <- xml_children(node)
  
  # Create a named list where each name is a node name and each value is the node text
  data_list <- map(children, ~ xml_text(.x))
  names(data_list) <- map(children, ~ ifelse(xml_name(.x) == "", "empty_node_name", xml_name(.x)))
  
  #~ xml_name(.x))
  
  # Return a one-row tibble (data frame) created from this named list
  #return(as_tibble(list(data_list)))
  return(as_tibble(data_list))
}

# Function to convert an XML document into a data frame
xml_to_df <- function(xml_content) {
  # Find all the top-level nodes you are interested in
  # Adjust the XPath to select the nodes that represent individual records
  records <- xml_find_all(xml_content, "./*")
  
  # Convert each node to a row in a data frame
  df_list <- map(records, node_to_df)
  
  # Combine all rows into a single data frame
  bind_rows(df_list)
}

# ... Rest of code to run ...

# Replace with your actual email and password registered with NRDP
email <- "jane@doe.com"
password <- "password"

# Authenticate and get token
auth_details <- get_auth_token(email, password)
token <- auth_details$token
expiration_time <- auth_details$expiration_time

# Check if token is expired before making a new request
# REDUNDANT? - Already get a new token anyway
if (is_token_expired(expiration_time)) {
  auth_details <- get_auth_token(email, password)
  token <- auth_details$token
  expiration_time <- auth_details$expiration_time
}

# Call the function with the URL and the token
url_GET <- "https://opendata.nationalrail.co.uk/api/staticfeeds/5.0/incidents"
xml_file <- get_file_with_token(url_GET, token)
#print(xml_file) #It is there...

file_type <- class(xml_file)
print(file_type)

# If xml_file is a parsed XML document or node
if ("xml_document" %in% file_type || "xml_node" %in% file_type) {
  # Convert the XML to a data frame
  xml_df <- xml_to_df(xml_file)
  
  # View the data frame in a readable tabular format
  View(xml_df)
} else {
  print("xml_file is not of class 'xml_document' or 'xml_node'")
}

# If xml_file is a parsed XML document
#if (typeof(xml_file) == "externalptr") {
# if(class(xml_file) == "xml_document"){
#   print("Reached here!")
#   # Convert the XML to a data frame
#   xml_df <- xml_to_df(xml_file)
  
#   # View the data frame in a readable tabular format
#   print(xml_df)
#   View(xml_df)
#   # NOT RUNNING!
# }



