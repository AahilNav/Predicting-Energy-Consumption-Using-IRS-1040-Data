import os
import pandas as pd

#Before running this code unzip all the files in data and put them in a folder named '09-21csv'
folder_path = os.path.join(os.getcwd(), 'data', '09-21csv')
out_path = os.path.join(os.getcwd(), 'working_data')
codebook_path = os.path.join(os.getcwd(), 'artifacts','Codebook.xlsx')

#Create outpath if it doesn't exist
if not os.path.exists(out_path):
    os.makedirs(out_path)


#Read in mapping document.  The variable names are in the 'Variable' column and variable desciptions are in the 'Description' column of the 'SelectedVars' sheet of the codebook
#Output a dictionary of {Variable: Description} we will use to filter and lable variables in each doc
def read_mapper(codebook_path):
    var_dict = {}
    
    # Read the Excel file
    df_codebook = pd.read_excel(codebook_path, sheet_name='SelectedVars')
    
    # Populate the dictionary
    for _, row in df_codebook.iterrows():
        var_dict[row['Variable']] = row['Description']
    
    #print(var_dict)
    return var_dict

def capitalize_column_headers(headers):
    capitalized_headers = [str(header).upper() for header in headers]
    return capitalized_headers

def standardize_headers(df, year):
    # Capitalize each variable name
    df.columns = capitalize_column_headers(df.columns)
    
    # Add columns with blank rows for any variable in var_dict not in file
    for var in var_dict:
        if var not in df.columns:
            df[var] = pd.NA
    
    # Delete columns not in var_dict
    columns_to_keep = [col for col in df.columns if col in var_dict]
    df = df[columns_to_keep]
    
    # Organize columns in the order of var_dict
    df = df.reindex(columns=var_dict.keys())

    #Add year to observations in the 'Year' column

    return df

def assign_year(filename):
    # Extract first two characters from filename
    year_code = filename[:2]
    
    # Map year code to full year
    year_mapping = {'09': '2009', '10': '2010', '11': '2011', '12': '2012', '13': '2013',
                    '14': '2014', '15': '2015', '16': '2016', '17': '2017', '18': '2018',
                    '19': '2019', '20': '2020', '21': '2021'}
    
    return year_mapping.get(year_code, 'Unknown')

def clean_data(df):
    #replace .0001 with 0
    df.replace(.0001, 0, inplace=True)

    return df

def filter_texas(df):
    # Only include observations with STATE=="TX"
    df = df[df['STATE'] == 'TX']
    
    return df


def output_all(folder_path, out_path, var_dict, Year_list):
    # Iterate over each file in the folder
    for filename in os.listdir(folder_path):
        year = assign_year(filename)
        print(year)
        if year in Year_list:
            if filename.endswith('.csv'):
                file_path = os.path.join(folder_path, filename)
                
                # Read the CSV file
                df = pd.read_csv(file_path)
                df = standardize_headers(df, var_dict)
                df = clean_data(df)
                
                # Populate 'Year' column
                df['YEAR'] = year
                
                # Save the structured DataFrame to the out_path
                new_filename = filename.replace('.csv', '_stdz.csv')
                structured_file_path = os.path.join(out_path, new_filename)
                df.to_csv(structured_file_path, index=False)

def output(folder_path, out_path, var_dict, Texas):
    # Create master df
    master_df = pd.DataFrame()
    
    # Iterate over each file in the folder
    for filename in os.listdir(folder_path):
        if filename.endswith('.csv'):
            file_path = os.path.join(folder_path, filename)
            
            # Determine year using assign_year()
            year = assign_year(filename)
            print(year)
            
            # Read the CSV file
            df = pd.read_csv(file_path)
            df = standardize_headers(df, var_dict)

            #If Texas = True, filter for only Texas values
            if Texas:
                df = filter_texas(df)

            df = clean_data(df)
            df['YEAR'] = year
            
            # Append to master df
            master_df = pd.concat([master_df, df])
    
    # Sort master df
    master_df.sort_values(by=['STATEFIPS', 'ZIPCODE', 'YEAR', 'AGI_STUB'], inplace=True)
    
    # Save the master DataFrame to the out_path
    if Texas:
        master_file_path = os.path.join(out_path, 'allagi_TX.csv')

    else:
        master_file_path = os.path.join(out_path, 'allagi.csv')
    
    master_df.to_csv(master_file_path, index=False)




if __name__ == "__main__":
    Year_list = ['2009', '2010','2021']
    Texas = True
    var_dict = read_mapper(codebook_path)
    output_all(folder_path, out_path, var_dict, Year_list)
    output(folder_path, out_path, var_dict, Texas)
    
