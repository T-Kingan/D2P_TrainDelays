import csv

import csv
from datetime import datetime, timedelta  # Import the datetime module


mca_file_path = r'C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Coursework\timetable_data_V2\RJTTF937.MCA'

output_directory = r'C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Coursework\timetable_data_V2'

extension = ".csv"

bs_file_path = f"{output_directory}/Basic_Schedule_RJTTF937{extension}"
locations_file_path = f"{output_directory}/Locations_RJTTF9373{extension}"

timetable_csv_path = f"{output_directory}/KingsCross_Edinburgh_Timetable.csv"

# Define TIPLOC codes for the stations
origin_tiploc = 'KNGX'       # London Kings Cross
destination_tiploc = 'EDINBUR' # Edinburgh Waverley

bs_field_mapping = {
    'Record Identity': (0, 2),
    'Transaction Type': (2, 3),
    'Train UID': (3, 9),
    'Date Runs From': (9, 15),
    'Date Runs To': (15, 21),
    'Days Run': (21, 28),
    'Bank Holiday Running': (28, 29),
    'Train Status': (29, 30),
    'Train Category': (30, 32),
    'Train Identity': (32, 36),
    'Headcode': (36, 40),
    'Course Indicator': (40, 41),
    'Profit Centre Code/Train Service Code': (41, 49),
    'Business Sector': (49, 50),
    'Power Type': (50, 53),
    'Timing Load': (53, 57),
    'Speed': (57, 60),
    'Operating Chars': (60, 66),
    'Train Class': (66, 67),
    'Sleepers': (67, 68),
    'Reservations': (68, 69),
    'Connect Indicator': (69, 70),
    'Catering Code': (70, 74),
    'Service Branding': (74, 78),
    'Spare': (78, 79),
    'STP Indicator': (79, 80)
}

origin_location_field_mapping = {
    'Record Identity': (0, 2),
    'Location': (2, 10),
    'Scheduled Departure Time': (10, 15),
    'Public Departure Time': (15, 19),
    'Platform': (19, 22),
    'Line': (22, 25),
    'Engineering Allowance': (25, 27),
    'Pathing Allowance': (27, 29),
    'Activity': (29, 41),
    'Performance Allowance': (41, 43),
    'Spare': (43, 80)
}

intermediate_location_field_mapping = {
    'Record Identity': (0, 2),
    'Location': (2, 10),
    'Scheduled Arrival Time': (10, 15),
    'Scheduled Departure Time': (15, 20),
    'Scheduled Pass': (20, 25),
    'Public Arrival': (25, 29),
    'Public Departure': (29, 33),
    'Platform': (33, 36),
    'Line': (36, 39),
    'Path': (39, 42),
    'Activity': (42, 54),
    'Engineering Allowance': (54, 56),
    'Pathing Allowance': (56, 58),
    'Performance Allowance': (58, 60),
    'Spare': (60, 80)
}

terminating_location_field_mapping = {
    'Record Identity': (0, 2),
    'Location': (2, 10),
    'Scheduled Arrival Time': (10, 15),
    'Public Arrival Time': (15, 19),
    'Platform': (19, 22),
    'Path': (22, 25),
    'Activity': (25, 37),
    'Spare': (37, 80)
}

def parse_line(line, field_mapping):
    parsed_data = {}
    for field, (start, end) in field_mapping.items():
        parsed_data[field] = line[start:end].strip()
    return parsed_data

def parse_all_mca(mca_file):
    all_trains = []

    with open(mca_file, 'r') as file:
        current_train = {}
        for line in file:
            record_type = line[0:2]

            if record_type == 'BS':
                if current_train:  # If current_train is not empty
                    all_trains.append(current_train)
                current_train = {'BS': parse_line(line, bs_field_mapping)}

            elif record_type in ['LO', 'LI', 'LT']:
                location_mapping = {
                    'LO': origin_location_field_mapping,
                    # --- Doesn't have all the fields of the intermediate location ---
                    # For example if its actually going to aberdeen it might miss edinburgh
                    'LI': intermediate_location_field_mapping,
                    'LT': terminating_location_field_mapping
                }
                parsed_data = parse_line(line, location_mapping[record_type])
                current_train[record_type] = parsed_data

                if record_type == 'LT':
                    all_trains.append(current_train)
                    current_train = {}  # Reset for the next train entry
        
        if current_train:  # Add the last train entry if the file does not end with an 'LT'
            all_trains.append(current_train)

    return all_trains

def filter_dept_dest(all_trains, origin_tiploc, destination_tiploc):
    filtered_trains = []

    for train in all_trains:
        if 'BS' in train and 'LO' in train and 'LT' in train:
            origin_location = train['LO']
            destination_location = train['LT']

            if (
                origin_location['Location'] == origin_tiploc
                and destination_location['Location'] == destination_tiploc
            ):
                # Train originates at Kings Cross and terminates at Edinburgh
                filtered_trains.append(train)
            # --- Need to include if Train originates at Kings Cross and has an intermediary stop at Edinburgh e.g. Aberdeen ---
            # elif origin_location['Location'] == origin_tiploc:
            #     timetable.append(train)

    return filtered_trains

def construct_timetable(filtered_trains, from_date, to_date):
  # create a dictionary where each key is a day and the corresponding value is a list of trains that day
  # construct a list of days between from_date and to_date
  timetable = {}
  # Calculate the range of dates between from_date and to_date
  current_date = from_date
  while current_date <= to_date:
      # Format the current_date as a string in the desired format, e.g., 'YYYY-MM-DD'
      current_date_str = current_date.strftime('%Y-%m-%d')
      
      # Initialize an empty list of trains for this day
      timetable[current_date_str] = []
      
      # Move to the next day
      current_date += timedelta(days=1)
  # for each train, check if it runs on each day in the list of days
  # if it does, add it to the list of trains for that day
  for train in filtered_trains:
      # Get the days that this train runs
      days_run = train['BS']['Days Run']
      
      # Get the start and end dates for this train
      date_runs_from = datetime.strptime(train['BS']['Date Runs From'], '%y%m%d')
      date_runs_to = datetime.strptime(train['BS']['Date Runs To'], '%y%m%d')

      # Check if the train runs on each day in the timetable
      current_date = from_date
      while current_date <= to_date:
          # Format the current_date as a string in the desired format, e.g., 'YYYY-MM-DD'
          current_date_str = current_date.strftime('%Y-%m-%d')
          # Check if the train runs on this day
          if (
              current_date >= date_runs_from
              and current_date <= date_runs_to
              and days_run[current_date.weekday()] == '1'
          ):
              # Add the train to the list of trains for this day
              # Add more specific information about the train
              dept_time = train['LO']['Public Departure Time'] # format into time
              arr_time = train['LT']['Public Arrival Time'] # format into time

              timetable[current_date_str].append({
                  'Train UID': train['BS']['Train UID'],
                  'Departure Time': dept_time,
                  'Arrival Time': arr_time
              })
          
          # Move to the next day
          current_date += timedelta(days=1)
  return timetable

# Function to write the timetable to a CSV file
def write_timetable_to_csv(timetable, output_path):
    with open(output_path, 'w', newline='') as csvfile:
        fieldnames = ['Date', 'Train UID', 'Departure Time', 'Arrival Time']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        # Iterate over each day in the timetable
        for date, trains in timetable.items():
            # Write each train's information as a row in the CSV file
            for train in trains:
                writer.writerow({
                    'Date': date,
                    'Train UID': train['Train UID'],
                    'Departure Time': train['Departure Time'],
                    'Arrival Time': train['Arrival Time']
                })
  
from_date = datetime.strptime('2023-12-01', '%Y-%m-%d')
to_date = datetime.strptime('2024-01-01', '%Y-%m-%d')

all_trains = parse_all_mca(mca_file_path)
filtered_trains = filter_dept_dest(all_trains, origin_tiploc, destination_tiploc)
new_timetable = construct_timetable(filtered_trains, from_date, to_date)
write_timetable_to_csv(new_timetable, timetable_csv_path)



    # # Write to Basic Schedule CSV file
    # with open(bs_file, 'w', newline='') as bs_file_var:
    #     bs_csvwriter = csv.DictWriter(bs_file_var, fieldnames=bs_field_mapping.keys())
    #     bs_csvwriter.writeheader()
    #     for train in all_trains:
    #         if 'BS' in train:
    #             bs_csvwriter.writerow(train['BS'])

    # Process all_trains to create the timetable
    # This step will need to filter the trains for those starting at Kings Cross and ending at Edinburgh
    # and then extract and write the necessary timetable information to another CSV file

# Call the function with the correct file paths
