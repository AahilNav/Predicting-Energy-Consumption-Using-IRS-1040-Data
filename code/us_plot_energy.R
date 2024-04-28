# Load necessary libraries
library(dplyr)
library(leaflet)
library(scales)  # For formatting numbers in the popup

# Read the data
data <- read.csv("../working_data/filtered_irs09_us.csv")  # Make sure to use the correct path to your data file

# Ensure there are no NA values or zero values in key columns for A07260
data <- data %>%
  filter(!is.na(A07260) & !is.na(Latitude) & !is.na(Longitude)) %>%
  filter(A07260 > 0)  # Filter out zero values

# Calculate the average Residential Energy Tax Credit Amount (A07260) for each latitude and longitude
avg_tax_credit <- data %>%
  group_by(Latitude, Longitude) %>%
  summarise(Avg_Tax_Credit = mean(A07260, na.rm = TRUE)) %>%
  filter(Avg_Tax_Credit > 0) %>%  # Ensure average tax credit is not zero
  ungroup()

# Scale the radius of the circles based on the Residential Energy Tax Credit Amount
radius_scale <- sqrt(avg_tax_credit$Avg_Tax_Credit) / 20  # Adjust this scaling factor as needed

# Create a color palette based on the Residential Energy Tax Credit Amount values
pal <- colorNumeric(palette = "viridis", domain = avg_tax_credit$Avg_Tax_Credit)

# Load the US states GeoJSON data
us_states_boundaries <- readLines("gz_2010_us_040_00_500k.json")
us_states_boundaries <- paste(us_states_boundaries, collapse = "\n")

# Create the map with Residential Energy Tax Credit data
map <- leaflet(avg_tax_credit) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  # Add US state borders to the map
  addGeoJSON(geojson = us_states_boundaries, 
             weight = 1, 
             color = "#444444", 
             fillColor = NA, 
             fillOpacity = 0) %>%
  # Add the circle markers for Residential Energy Tax Credit Amount
  addCircleMarkers(
    ~Longitude, ~Latitude,
    radius = ~radius_scale,
    color = ~pal(Avg_Tax_Credit),
    fillOpacity = 0.8,
    stroke = FALSE,
    popup = ~paste("Average Residential Energy Tax Credit: $", comma(Avg_Tax_Credit))
  ) %>%
  addLegend("bottomright", pal = pal, values = ~Avg_Tax_Credit,
            title = "Average Residential Energy Tax Credit",
            opacity = 1) %>%
  setView(lng = -98.5795, lat = 39.8283, zoom = 4)  # Center on the continental US

# Print the map
map
