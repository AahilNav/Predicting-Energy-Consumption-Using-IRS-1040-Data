import pandas as pd

# Load the unique ZIP codes with manually entered lat-long
zip_codes = pd.read_csv('../working_data/ss/unique_zip_codes.csv')
zip_codes['zip'] = zip_codes['zip'].astype(int).astype(str)  # Ensure zip codes are strings and formatted correctly

# Split the 'latlong' into two separate columns for 'Latitude' and 'Longitude'
# Handling spaces correctly if present after the comma
zip_codes[['Latitude', 'Longitude']] = zip_codes['latlong'].str.split(', ', expand=True)
if zip_codes['Longitude'].isnull().sum() > 0:  # Fallback if no space was found
    zip_codes[['Latitude', 'Longitude']] = zip_codes['latlong'].str.split(',', expand=True)

# Check for NaN values in latitude and longitude columns
print("NaN values in Latitude column:", zip_codes['Latitude'].isnull().sum())
print("NaN values in Longitude column:", zip_codes['Longitude'].isnull().sum())

# Create dictionaries mapping ZIP codes to Latitude and Longitude
latitude_dict = zip_codes.set_index('zip')['Latitude'].to_dict()
longitude_dict = zip_codes.set_index('zip')['Longitude'].to_dict()

# Load the updated energy usage data
energy_usage = pd.read_csv('updated_energy_usage_with_prevalent_zip.csv')
# Ensure all zip codes are converted to strings and handle NaNs
energy_usage['zip'] = energy_usage['zip'].astype(float).astype('Int64').astype(str)  # Handles NaNs correctly

# Remove trailing ".0" from zip codes
energy_usage['zip'] = energy_usage['zip'].apply(lambda x: x[:-2] if '.0' in x else x)

# Check for NaN values in the zip column
print("NaN values in 'zip' column of energy_usage:", energy_usage['zip'].isnull().sum())

# Map latitude and longitude using the dictionaries
energy_usage['Latitude'] = energy_usage['zip'].map(latitude_dict)
energy_usage['Longitude'] = energy_usage['zip'].map(longitude_dict)

# Check for NaN values in latitude and longitude columns after mapping
print("NaN values in 'Latitude' column after mapping:", energy_usage['Latitude'].isnull().sum())
print("NaN values in 'Longitude' column after mapping:", energy_usage['Longitude'].isnull().sum())

# Save the final updated dataset with latitude and longitude
energy_usage.to_csv('final_updated_energy_usage_with_coordinates.csv', index=False)
