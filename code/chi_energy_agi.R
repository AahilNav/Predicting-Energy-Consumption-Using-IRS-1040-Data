# Load necessary libraries
library(dplyr)
library(leaflet)
library(scales)  # For formatting numbers in the popup

# Read the data
data <- read.csv("../working_data/chicago_all.csv")
avg_values = data %>% filter(BUILDING_SUBTYPE == "All")
avg_values$A00100_av = avg_values$A00100_av*1000
avg_values$A07260_av = avg_values$A07260_av*1000

# Ensure there are no NA values in key columns
# data = data %>%
#   filter(!is.na(A00100) & !is.na(A07260) & !is.na(Latitude) & !is.na(Longitude))

# Calculate the average AGI (A00100) and average Residential Energy Tax Credit (A07260) for each latitude and longitude
# avg_values = data %>%
#   group_by(Latitude, Longitude) %>%
#   summarise(Avg_AGI = mean(A00100, na.rm = TRUE),
#             Avg_Tax_Credit = mean(A07260, na.rm = TRUE)) %>%
#   filter(Avg_AGI > 0, Avg_Tax_Credit > 0) %>%
#   ungroup()

# Apply jitter to the aggregated latitude and longitude for visualization clarity
set.seed(123)
avg_values$Jittered_Latitude = jitter(avg_values$Latitude, amount = 0.001)
avg_values$Jittered_Longitude = jitter(avg_values$Longitude, amount = 0.001)

# Scale the radius of the circles based on AGI
avg_values$Radius = sqrt(avg_values$A00100_av) / 50

# Create a color palette based on the Residential Energy Tax Credit Amount
tax_credit_pal = colorNumeric(palette = "viridis", domain = avg_values$A07260_av)

# Load GeoJSON data for Chicago city boundaries directly
chicago_boundaries = readLines("../working_data/Boundaries - Neighborhoods.geojson")
chicago_boundaries = paste(chicago_boundaries, collapse = "\n")

# Create the map with AGI data and add the Chicago city boundaries
map = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius,
    color = ~tax_credit_pal(A07260_av),
    fillOpacity = 0.8,
    stroke = FALSE,
    popup = ~paste("Average AGI: $", comma(A00100_av), "<br>",
                   "Average Residential Energy Tax Credit: $", comma(A07260_av))
  ) %>%
  addGeoJSON(geojson = chicago_boundaries, 
             weight = 1, 
             color = "#444444", 
             fillColor = NA, 
             fillOpacity = 0
  ) %>%
  addLegend("topright", pal = tax_credit_pal, values = ~A07260_av,
            title = "Average Residential Energy Tax Credit",
            opacity = 1,
            ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Print the map
map

