#This file aims to build a final file that can be used to then forecast from

import pandas as pd

# Creating data frame for NRDP_(KGX-EDB) csv
file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/NRDP_(KGX-EDB).csv'
df = pd.read_csv(file_path)

# Select columns to keep from NRDP_(KGX-EDB) csv
columns_to_keep = [3, 4, 5, 6, 12, 13]
df = df.iloc[:, columns_to_keep]



#/////////////////////////////////////////////////////////////////
# Bringing in the public holiday data

# Creating data frame for public holiday data
# file_path_hols = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/01-01-2021_to_02-12-23_holidays.csv'
# df_hols = pd.read_csv(file_path_hols)

# # Convert 'date' columns in both DataFrames to datetime format for accurate merging
# df_hols['date'] = pd.to_datetime(df_hols['date'])
df['date_of_service'] = pd.to_datetime(df['date_of_service'], dayfirst=True)

# # Merge the DataFrames on the date columns
# df = pd.merge(df, df_hols, left_on='date_of_service', right_on='date', how='left')
# df = df.drop(columns=['date', 'day_type']) #dropping some extra columns

# Add a new column with the day of the week (1 for Monday, 7 for Sunday) (nothing to do with holiday data)
df['day_of_week'] = df['date_of_service'].dt.dayofweek + 1

#///////////////////////////////
# Adding weather data
# Creating data frame for weather data
file_path_weather = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Complete weather data (forecast from)/Edinburgh 2021-01-01 to 2023-12-02.csv'
df_weather = pd.read_csv(file_path_weather)
#df_weather = df_weather[['datetime', 'tempmax', 'tempmin', 'precip', 'snow', 'windspeed' ]]
df_weather = df_weather[['datetime', 'tempmax', 'tempmin', 'precip', 'snow', 'windspeed' ]]

# Convert 'date' columns in both DataFrames to datetime format for accurate merging
df_weather['datetime'] = pd.to_datetime(df_weather['datetime'])
df['date_of_service'] = pd.to_datetime(df['date_of_service'], dayfirst=True)


# Merge the DataFrames on the date columns
df = pd.merge(df, df_weather, left_on='date_of_service', right_on='datetime', how='left')
df = df.drop(columns=['datetime'])


#////////////////////////////////////////////////
# Manipulate time to remove ':'
df['scheduled_arr'] = df['scheduled_arr'].str.replace(':', '')
df['scheduled_dept'] = df['scheduled_dept'].str.replace(':', '')

#/////////////////////////////////////////////////
# Exporting the final file to be used for forecasting

output_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Final Data Sources/to_forecast_from.csv' 

# Save the sorted DataFrame to a new CSV file
df.to_csv(output_file_path, index=False)
