library(dplyr)
library(leaflet)
library(leaflegend)  

# Pull our git repo, or download 
# Read and prepare data
data <- read.csv("../working_data/chicago_all.csv")

avg_values <- data %>%
  filter(BUILDING_SUBTYPE == "All") %>%
  mutate(
    A00100_av = A00100_av * 1000,  # Adjust AGI values
    A07260_av = A07260_av * 1000,
    Jittered_Latitude = jitter(Latitude, amount = 0.001),
    Jittered_Longitude = jitter(Longitude, amount = 0.001)
  ) %>% #AGI
  mutate(
    Radius1 = case_when(
      A00100_av >= quantile(A00100_av, 0.80) ~ 20,  # Smallest circle
      A00100_av >= quantile(A00100_av, 0.60) ~ 16,
      A00100_av >= quantile(A00100_av, 0.40) ~ 12,
      A00100_av >= quantile(A00100_av, 0.20) ~ 8,
      TRUE ~ 4
    )
  ) %>% #energy credit
  mutate(
    Radius2 = case_when(
      A07260_av >= quantile(A07260_av, 0.80) ~ 20,  # Smallest circle
      A07260_av >= quantile(A07260_av, 0.60) ~ 16,
      A07260_av >= quantile(A07260_av, 0.40) ~ 12,
      A07260_av >= quantile(A07260_av, 0.20) ~ 8,
      TRUE ~ 4
    )
  ) %>% #This will be whatever other variables the plot finds significant
  mutate(
    Radius3 = case_when(
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.80) ~ 20,  # Smallest circle
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.60) ~ 16,
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.40) ~ 12,
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.20) ~ 8,
      TRUE ~ 4
    )
  )

# Create a color palette
tax_credit_pal <- colorNumeric(palette = "viridis", domain = avg_values$A07260_av)
therms_pal <- colorNumeric(palette = "Oranges", domain = avg_values$THERMS.PER.SQFT) #unsure if this is correct
kwh_pal <- colorNumeric(palette = "Yellows", domain = avg_values$KWH.PER.SQFT)#unsure if this is correct
agi_al <- colorNumeric(palette = "Blues", domain = avg_values$KWH.PER.SQFT)#unsure if this is correct

# Load GeoJSON data for Chicago city boundaries
chicago_boundaries <- readLines("../working_data/Boundaries - Neighborhoods.geojson") %>% paste(collapse = "\n")


## Vis01, color = therms, size = tax credit
# Create the map
vis01 <- leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius2,
    color = ~therms_pal(THERMS.PER.SQFT),
    fillOpacity = 0.8,
    stroke = FALSE,
    popup = ~paste("", comma(A00100_av), "<br>",
                   "", comma(A07260_av)) #can we delete this? does this matter?
  ) %>%
  addGeoJSON(
    geojson = chicago_boundaries, 
    weight = 1, 
    color = "#444444", 
    fillColor = NA, 
    fillOpacity = 0
  ) %>%
  addLegend(
    position = "bottomright", 
    pal = therms_pal(), 
    values = ~THERMS.PER.SQFT,
    title = "Gas Heating (Therms)",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius2 * 5,
    title = " Average Energy Tax Credits",
    color = 'black',
    shape = 'circle',
    baseSize = 20,  # Adjusted as per requirement
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0,
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
#save to figures as vis01

## Vis02, color = kwh, size = tax credit


## Vis03, color = therms, size = agi



## Vis04, color = kwh, size = agi



## Vis05, color = therms, size = housesize



## Vis06, color = kwh, size = housesize


## ... whatever other visualizations we fid significant


## Plotting residuals





########################################################################