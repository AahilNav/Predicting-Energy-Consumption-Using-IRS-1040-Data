library(dplyr)
library(leaflet)
library(leaflegend)  

# Read and prepare data
data <- read.csv("../working_data/chicago_all.csv")
avg_values <- data %>%
  filter(BUILDING_SUBTYPE == "All") %>%
  mutate(
    A00100_av = A00100_av * 1000,  # Adjust AGI values
    A07260_av = A07260_av * 1000,
    Jittered_Latitude = jitter(Latitude, amount = 0.001),
    Jittered_Longitude = jitter(Longitude, amount = 0.001)
  ) %>%
  mutate(
    Radius = case_when(
      A00100_av >= quantile(A00100_av, 0.80) ~ 20,  # Smallest circle
      A00100_av >= quantile(A00100_av, 0.60) ~ 16,
      A00100_av >= quantile(A00100_av, 0.40) ~ 12,
      A00100_av >= quantile(A00100_av, 0.20) ~ 8,
      TRUE ~ 4
    )
  )

# Create a color palette
tax_credit_pal <- colorNumeric(palette = "viridis", domain = avg_values$A07260_av)

# Load GeoJSON data for Chicago city boundaries
chicago_boundaries <- readLines("../working_data/Boundaries - Neighborhoods.geojson") %>% paste(collapse = "\n")

# Create the map
map <- leaflet(avg_values) %>%
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
  addGeoJSON(
    geojson = chicago_boundaries, 
    weight = 1, 
    color = "#444444", 
    fillColor = NA, 
    fillOpacity = 0
  ) %>%
  addLegend(
    position = "topright", 
    pal = tax_credit_pal, 
    values = ~A07260_av,
    title = "Residential Energy Tax Credit",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'bottomright',
    values = ~Radius * 5,
    title = "AGI Circle Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,  # Adjusted as per requirement
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0,
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(map)
