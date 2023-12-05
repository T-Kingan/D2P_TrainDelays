import csv

mca_file_path = r'C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Coursework\timetable_data_V2\RJTTF937.MCA'

output_directory = r'C:\Users\thoma\OneDrive - Imperial College London\Des Eng Y4\Data2Product\Coursework\timetable_data_V2'

extension = ".csv"

bs_file_path = f"{output_directory}/Basic_Schedule_RJTTF937{extension}"
locations_file_path = f"{output_directory}/Locations_RJTTF9373{extension}"

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


origin_location_field_mapping = {}
intermediate_location_field_mapping = {}
terminating_location_field_mapping = {}


def parse_mca_to_csv(mca_file, locations_file, bs_file, origin_tiploc, destination_tiploc):
    
    with open(mca_file, 'r') as file, \
         open(locations_file, 'w', newline='') as locations_file_var, \
         open(bs_file, 'w', newline='') as bs_file_var:
        
        # Need to implement the following somewhere
        # csvwriter = csv.writer(csvfile)
        # # Write the header row
        # csvwriter.writerow(['Departure Date', 'Departure Time', 'Arrival Time'])

        bs_csvwriter = csv.DictWriter(bs_file_var, fieldnames=bs_field_mapping.keys())
        #location_csvwriter = csv.DictWriter(locations_file_var, fieldnames=location_fieldnames)
        
        bs_csvwriter.writeheader()
        #location_csvwriter.writeheader()

        current_train = {}

        #
        for line in file:
            record_type = line[0:2]

            if record_type == 'BS':
                # Start a new train entry
                
                # 
                bs_record = parse_basic_schedule(line)
                bs_csvwriter.writerow(bs_record)

            # next line is a BX record
            # followed by LO
            # followed by LI for each intermediate location
            # followed by LT


            # --- To be implemented ---
            # elif record_type in ['LO', 'LI', 'LT']: # PERHAPS separate by location type? They are formatted differently
            #     location_record = parse_location_record(line)
                
            #     if location_record['tiploc'] == origin_tiploc and record_type == 'LO':
            #         current_train['departure_date'] = current_train['date_runs_from']
            #         current_train['departure_time'] = location_record['scheduled_departure']

            #     elif location_record['tiploc'] == destination_tiploc and record_type == 'LT':
            #         current_train['arrival_time'] = location_record['scheduled_arrival']
            #         csvwriter.writerow([current_train.get('departure_date'), 
            #                             current_train.get('departure_time'), 
            #                             current_train.get('arrival_time')])

def parse_basic_schedule(line):
    # Extract fields from the line based on fixed-width values
    bs_parsed_data = {}
    for field, (start, end) in bs_field_mapping.items():
        # Adjust the start index for zero-based indexing and set the end index for slicing
        bs_parsed_data[field] = line[start:end].strip()
    
    return bs_parsed_data

def parse_location_record(line):  # Not all location records are the same format...
    # Extract fields from the line based on fixed-width values
    return {
        'tiploc': line[2:9].strip(), # Position 3-10?
        'scheduled_arrival': line[10:15].strip(),
        'scheduled_departure': line[15:20].strip(),
        # ... add other relevant fields
    }

def parse_origin_location(line):
    return {
        'tiploc': line[2:9].strip(),
        'scheduled_departure': line[10:15].strip(),
    }




# Parse the .MCA file and write to CSV
parse_mca_to_csv(mca_file_path, locations_file_path, bs_file_path, origin_tiploc, destination_tiploc)
