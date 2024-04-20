import csv
import os

#Before running this code unzip all the files in data and put them in a folder named '09-21csv'
folder_path = os.path.join(os.getcwd(), 'data', '09-21csv')
out_path = os.path.join(os.getcwd(), 'artifacts')

def capitalize_column_headers(headers):
    capitalized_headers = [str(header).upper() for header in headers]
    return capitalized_headers

def read_csv_files(folder_path):
    data_dict = {}

    # Iterate over each file in the folder
    for filename in os.listdir(folder_path):
        if filename.endswith('.csv'):
            file_path = os.path.join(folder_path, filename)
            
            with open(file_path, 'r') as file:
                reader = csv.reader(file)
                
                # Extract column headers (variable names)
                headers = next(reader)
                
                # Capitalize column headers
                capitalized_headers = capitalize_column_headers(headers)
                
                # Create dictionary for the file
                file_dict = {
                    'vars_names': capitalized_headers
                }
                
                # Add file dictionary to the data dictionary
                data_dict[filename] = file_dict

    return data_dict

def write_vardoc(data_dict, suffix=''):
    output_shared_file_path = os.path.join(out_path, f'shared_vars{suffix}.csv')
    output_unique_file_path = os.path.join(out_path, f'unique_vars{suffix}.csv')

    # Identify shared variables
    shared_vars = set(data_dict[next(iter(data_dict))]['vars_names'])
    for file_data in data_dict.values():
        shared_vars.intersection_update(file_data['vars_names'])

    # Write shared variables
    with open(output_shared_file_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Shared_Vars'])
        for var in shared_vars:
            writer.writerow([var])

    print(f"Shared variable names have been written to {output_shared_file_path}")

    # Write unique variables
    with open(output_unique_file_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Year', 'Filename', 'Num_Unique_Vars', 'Unique_Vars'])
        
        # Sort filenames by year (first two characters)
        sorted_filenames = sorted(data_dict.keys(), key=lambda x: x[:2])

        for filename in sorted_filenames:
            year = f"20{filename[:2]}"
            file_data = data_dict[filename]
            unique_vars = set(file_data['vars_names']) - shared_vars
            writer.writerow([year, filename, len(unique_vars), ','.join(unique_vars)])

    print(f"Unique variable names have been written to {output_unique_file_path}")

if __name__ == "__main__":
    # Call the function for all files
    data_dict = read_csv_files(folder_path)
    write_vardoc(data_dict)

    # Filter files for years '13' to '21' and call the function again
    filtered_data_dict = {k: v for k, v in data_dict.items() if k[:2] in ['12', '13']}
    write_vardoc(filtered_data_dict, '_12-13')
