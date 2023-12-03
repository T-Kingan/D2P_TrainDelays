# The aim of this script is to download all of the public holidays from 1 Jan 2020 - 31 March '23

#///////////////////////////
#This part of code gets the public holidays from online and saves as a csv
import pandas as pd
bank_holidays = pd.read_json(path_or_buf = 'https://www.gov.uk/bank-holidays.json')

def get_england_and_wales(data_frame):
    return (
        pd
        .json_normalize(
            data_frame.to_dict(),
            record_path=[['england-and-wales', 'events']]
        )
        .astype({
            'title': 'string',
            'date': 'datetime64[ns]',
            'notes': 'string',
            'bunting': 'bool'
        })
    )

bh = get_england_and_wales(bank_holidays)

start_date = '2019-12-31'
end_date = '2023-3-31'

bh_by_date = bh.query('date > @start_date and date <= @end_date')
#print(bh_by_date)

output_file_path = '/Users/bert/Documents/Documents - Bert’s MacBook Pro/Imperial/Data to Product/CW/LDN - EDI/holidays.csv' 

# Save the sorted DataFrame to a new CSV file
bh_by_date.to_csv(output_file_path, index=False)

#/////////////////////////////
# This part of the code creates a data frame with all dates 1/1/20-31/3/23 then adds in public holiday y/n


# Creating a date range from 1/1/2020 to 31/3/2023
date_range = pd.date_range(start="2020-01-01", end="2023-03-31")

# Converting the public holiday dates to datetime for comparison
bh_by_date['date'] = pd.to_datetime(bh_by_date['date'])

# Creating a new DataFrame with the date range
date_df = pd.DataFrame(date_range, columns=['date'])

# Checking if each date in the date range is a public holiday
date_df['is_holiday'] = date_df['date'].isin(bh_by_date['date']).astype(int)

# Shifting the 'is_holiday' column to create new columns for before and after the holiday
date_df['day_before_holiday'] = date_df['is_holiday'].shift(-1).fillna(0).astype(int)
date_df['two_days_before_holiday'] = date_df['is_holiday'].shift(-2).fillna(0).astype(int)
date_df['day_after_holiday'] = date_df['is_holiday'].shift(1).fillna(0).astype(int)
date_df['two_days_after_holiday'] = date_df['is_holiday'].shift(2).fillna(0).astype(int)

print(date_df.head() ) # Display the first few rows of the new DataFrame
