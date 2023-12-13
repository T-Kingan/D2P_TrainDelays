# This file brings together into a single csv all of the different elements for our future predictions
import pandas as pd
from sklearn.preprocessing import LabelEncoder

# Import train timetable data
# Creating data frame for KingsCross_Edinburgh_Future_Timetable
file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Future Data/KingsCross_Edinburgh_Future_Timetable.csv'
df = pd.read_csv(file_path)

# Select columns to keep from KingsCross_Edinburgh_Future_Timetable
columns_to_keep = [0, 2, 3]
df = df.iloc[:, columns_to_keep]

# Rename columns to fit names in forecasting csv
df.rename(columns={'Date': 'date_of_service'}, inplace=True)
df.rename(columns={'Arrival Time': 'scheduled_arr'}, inplace=True)
df.rename(columns={'Departure Time': 'scheduled_dept'}, inplace=True)

# Function to convert time from 'HHMM' to 'HH:MM' format
def convert_time(time):
    # Ensure the time is a string, zero-padded to 4 digits
    time_str = str(time).zfill(4)
    # Insert a colon between the hour and minute
    return time_str[:2] + ':' + time_str[2:]



#/////////////////////////////////////////////////////////////////
# Adding days of week
df['date_of_service'] = pd.to_datetime(df['date_of_service'], dayfirst=True)
# Add a new column with the day of the week (1 for Monday, 7 for Sunday) (nothing to do with holiday data)
df['day_of_week'] = df['date_of_service'].dt.dayofweek + 1

#/////////////////////////////////////////////////
# adding weather data
EDN_weather_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Future Data/Future weather data/Edinburgh 2023-12-02 to 2024-03-02.csv'
EDN_weather = pd.read_csv(EDN_weather_file_path)

#df_weather = df_weather[['datetime', 'tempmax', 'tempmin', 'precip', 'snow', 'windspeed' ]]
EDN_weather = EDN_weather[['datetime', 'tempmax', 'tempmin', 'precip', 'snow', 'windspeed' ]]

# Convert 'date' columns in both DataFrames to datetime format for accurate merging
EDN_weather['datetime'] = pd.to_datetime(EDN_weather['datetime'])
df['date_of_service'] = pd.to_datetime(df['date_of_service'], dayfirst=True)


# Merge the DataFrames on the date columns
df = pd.merge(df, EDN_weather, left_on='date_of_service', right_on='datetime', how='left')
df = df.drop(columns=['datetime'])

#///////////////////////////
# Remove NaNs
df['snow'].fillna(0, inplace=True)

#/////////////////////////////////////////////////
# Exporting the final file to be used

output_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/Future Data/predict_from_this.csv' 

# Save the sorted DataFrame to a new CSV file
df.to_csv(output_file_path, index=False)
