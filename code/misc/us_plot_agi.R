# Load necessary libraries
library(dplyr)
library(leaflet)
library(scales)  # For formatting numbers in the popup

# Read the data
data <- read.csv("../working_data/filtered_irs09_us.csv")  # Make sure to use the correct path to your data file

# Ensure there are no NA values or zero values in key columns for A00100
data <- data %>%
  filter(!is.na(A00100) & !is.na(Latitude) & !is.na(Longitude)) %>%
  filter(A00100 > 0)  # Filter out zero values

# Calculate the average AGI (A00100) for each latitude and longitude
avg_agi <- data %>%
  group_by(Latitude, Longitude) %>%
  summarise(Avg_AGI = mean(A00100, na.rm = TRUE)) %>%
  filter(Avg_AGI > 0) %>%  # Ensure average AGI is not zero
  ungroup()

# Scale the radius of the circles based on the AGI
# Adjust this scaling factor to be smaller to increase variance
radius_scale_factor <- 0.000005  # Smaller factor increases size variance
avg_agi$Radius <- sqrt(avg_agi$Avg_AGI) * radius_scale_factor

# Create a color palette based on the AGI values
pal <- colorNumeric(palette = "viridis", domain = avg_agi$Avg_AGI)

# Load the US states GeoJSON data
us_states_boundaries <- readLines("../working_data/gz_2010_us_040_00_500k.json")
us_states_boundaries <- paste(us_states_boundaries, collapse = "\n")

# Create the map with AGI data
map <- leaflet(avg_agi) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  # Add US state borders to the map
  addGeoJSON(geojson = us_states_boundaries, 
             weight = 1, 
             color = "#444444", 
             fillColor = NA, 
             fillOpacity = 0) %>%
  # Add the circle markers for AGI
  addCircleMarkers(
    ~Longitude, ~Latitude,
    radius = ~Radius,
    color = ~pal(Avg_AGI),
    fillOpacity = 0.8,
    stroke = FALSE,
    popup = ~paste("Average AGI: $", comma(Avg_AGI))
  ) %>%
  addLegend("bottomright", pal = pal, values = ~Avg_AGI,
            title = "Average AGI",
            opacity = 1) %>%
  setView(lng = -98.5795, lat = 39.8283, zoom = 4)  # Center on the continental US

# Print the map
map
