import pandas as pd

# Define file paths
energy_usage_path = '../working_data/ss/Energy_Usage_2010_20240424.csv'
zip_tract_path = '../working_data/prework/ZIP_TRACT_122018.csv'

# Load the energy usage data from CSV
energy_usage = pd.read_csv(energy_usage_path)
energy_usage['CENSUS BLOCK'] = energy_usage['CENSUS BLOCK'].astype(str)
energy_usage['tract'] = energy_usage['CENSUS BLOCK'].str[:11]  # Adjust slicing as necessary

# Load the ZIP to tract mapping from CSV
zip_tract = pd.read_csv(zip_tract_path, dtype={'tract': str, 'zip': str})

# Clean up 'zip' entries by removing brackets and quotes using raw string notation for regex
zip_tract['zip'] = zip_tract['zip'].str.replace(r'[\[\]\']', '', regex=True).str.split()

# Explode the DataFrame to handle entries with multiple ZIP codes
zip_tract = zip_tract.explode('zip')

# Group by tract and zip, count occurrences, and find the mode
zip_count = zip_tract.groupby(['tract', 'zip']).size().reset_index(name='count')
most_prevalent_zip = zip_count.loc[zip_count.groupby('tract')['count'].idxmax()]

# If there are ties, this picks the first one; adjust if another rule is needed
zip_dict = pd.Series(most_prevalent_zip['zip'].values, index=most_prevalent_zip['tract']).to_dict()

# Map the ZIP codes using the dictionary
energy_usage['zip'] = energy_usage['tract'].map(zip_dict)

# Identify rows with missing ZIP codes to check for pattern or further issues
missing_zip = energy_usage[energy_usage['zip'].isna()]

# Save the updated and missing data for further inspection
energy_usage.to_csv('updated_energy_usage_with_prevalent_zip.csv', index=False)
missing_zip.to_csv('missing_zip_codes_with_prevalent.csv', index=False)
