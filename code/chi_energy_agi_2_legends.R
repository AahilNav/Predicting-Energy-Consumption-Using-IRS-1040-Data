library(dplyr)
library(leaflet)
library(leaflegend)  
library(viridis)
# Pull our git repo, or download 
# Read and prepare data
data = read.csv("../working_data/chicago_all.csv")

avg_values = data %>%
  filter(BUILDING_SUBTYPE == "All") %>%
  mutate(
    A00100_av = A00100_av * 1000,  # Adjust AGI values
    A07260_av = A07260_av * 1000,
    Jittered_Latitude = jitter(Latitude, amount = 0.001),
    Jittered_Longitude = jitter(Longitude, amount = 0.001)
  ) %>% #AGI
  mutate(
    Radius1 = case_when(
      A00100_av >= quantile(A00100_av, 0.80) ~ 20,  
      A00100_av >= quantile(A00100_av, 0.60) ~ 15,
      A00100_av >= quantile(A00100_av, 0.40) ~ 10,
      A00100_av >= quantile(A00100_av, 0.20) ~ 5,
      TRUE ~ 3
    )
  ) %>% #energy credit
  mutate(
    Radius2 = case_when(
      A07260_av >= quantile(A07260_av, 0.80) ~ 20,  
      A07260_av >= quantile(A07260_av, 0.60) ~ 15,
      A07260_av >= quantile(A07260_av, 0.40) ~ 10,
      A07260_av >= quantile(A07260_av, 0.20) ~ 5,
      TRUE ~ 3
    )
  ) %>% #This will be whatever other variables the plot finds significant
  mutate(
    Radius3 = case_when(
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.80) ~ 20,  
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.60) ~ 15,
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.40) ~ 10,
      AVERAGE.HOUSESIZE >= quantile(AVERAGE.HOUSESIZE, 0.20) ~ 5,
      TRUE ~ 3
    )
  )

# Define color palette for tax credit using 'viridis'
tax_credit_pal = colorNumeric(palette = "viridis", domain = avg_values$A07260_av)

# Define color palette for therms using 'plasma' from the viridis package
therms_pal = colorNumeric(palette = "plasma", domain = avg_values$THERMS_PER_SQFT)

# Define color palette for KWH using 'YlGnBu'
kwh_pal <- colorNumeric(palette = rev(RColorBrewer::brewer.pal(11, "RdYlBu")), domain = avg_values$KWH_PER_SQFT)

# Define color palette for AGI using 'magma' from the viridis package
agi_pal = colorNumeric(palette = "magma", domain = avg_values$A00100_av)

# Load GeoJSON data for Chicago city boundaries
chicago_boundaries <- readLines("../working_data/Boundaries - Neighborhoods.geojson") %>% paste(collapse = "\n")


## Vis01, color = therms, size = tax credit
# Create the map
vis01 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius2,
    color = ~therms_pal(THERMS.PER.SQFT),
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = therms_pal, 
    values = ~THERMS.PER.SQFT,
    title = "Gas Heating (Therms)",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius2 * 4,
    title = "Energy Tax Credit Size by Percentile",
    color = 'black',
    shape = 'circle',
    baseSize = 20,
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis01)

# Display the map
#save to figures as vis01

## Vis02, color = kwh, size = tax credit

vis02 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius2,  # Size by tax (energy) credit using Radius2
    color = ~kwh_pal(KWH.PER.SQFT),  # Color by KWH usage
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = kwh_pal,
    values = ~KWH.PER.SQFT,
    title = "KWH per SQFT",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius2*4,
    title = "Tax Credit Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,  # Visual representation size
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis02)


## Vis03, color = therms, size = agi
vis03 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius1,  
    color = ~therms_pal(THERMS.PER.SQFT),  # Color by Therms
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = therms_pal,
    values = ~THERMS.PER.SQFT,
    title = "Gas Heating (Therms)",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius1*4,
    title = "AGI Circle Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis03)



## Vis04, color = kwh, size = agi

vis04 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius1,  # Size by AGI using Radius1
    color = ~kwh_pal(KWH.PER.SQFT),  # Color by KWH usage
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = kwh_pal,
    values = ~KWH.PER.SQFT,
    title = "KWH per SQFT",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius1 * 4,
    title = "AGI Circle Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis04)

## Vis05, color = therms, size = housesize

vis05 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius3,  # Size by house size using Radius3
    color = ~therms_pal(THERMS.PER.SQFT),  # Color by Therms
    fillColor = ~therms_pal(THERMS.PER.SQFT),
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = therms_pal,
    values = ~THERMS.PER.SQFT,
    title = "Therms per SQFT",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius3 * 4,
    title = "House Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis05)

## Vis06, color = kwh, size = housesize

# Build the map for Vis06
vis06 = leaflet(avg_values) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Jittered_Longitude, ~Jittered_Latitude,
    radius = ~Radius3,  # Size by house size using Radius3
    color = ~kwh_pal(KWH.PER.SQFT),  # Color by KWH usage
    fillColor = ~kwh_pal(KWH.PER.SQFT),
    fillOpacity = 0.8,
    stroke = FALSE
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
    pal = kwh_pal,
    values = ~KWH.PER.SQFT,
    title = "KWH per SQFT",
    opacity = 1
  ) %>%
  addLegendSize(
    position = 'topright',
    values = ~Radius3 * 4,
    title = "House Size by Percentiles",
    color = 'black',
    shape = 'circle',
    baseSize = 20,
    orientation = 'horizontal',
    opacity = 0.5,
    fillOpacity = 0
  ) %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the map
print(vis06)


## ... whatever other visualizations we fid significant


## Plotting residuals

therm_resid = read.csv("../figures/Dtherm_all_result.csv")
kwh_resid = read.csv("../figures/Dkwh_all_result.csv")

# Define color palettes
therm_color_pal <- colorNumeric(palette = c("yellow", "orange", "red"), domain = range(therm_resid$Rediduals.for.therm, na.rm = TRUE), na.color = "transparent")
kwh_color_pal <- colorNumeric(palette = c("skyblue", "blue", "purple"), domain = range(kwh_resid$Rediduals.for.therm, na.rm = TRUE), na.color = "transparent")


## Visualization for Therm Residuals with Title
visResidualsTherm <- leaflet(therm_resid) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Longitude, ~Latitude,
    color = ~therm_color_pal(Rediduals.for.therm),
    fillColor = ~therm_color_pal(Rediduals.for.therm),
    fillOpacity = 0.8,
    stroke = FALSE,
    radius = 5
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
    pal = therm_color_pal,
    values = ~Rediduals.for.therm,
    title = "Therm Residuals",
    opacity = 1
  ) %>%
  addControl("<h4 style='margin: 10px; padding: 10px; text-align: center;'>XGBoost Residuals for Therm</h4>", position = "topright") %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

## Visualization for KWH Residuals with Title
visResidualsKWH <- leaflet(kwh_resid) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    ~Longitude, ~Latitude,
    color = ~kwh_color_pal(Rediduals.for.therm),
    fillColor = ~kwh_color_pal(Rediduals.for.therm),
    fillOpacity = 0.8,
    stroke = FALSE,
    radius = 5
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
    pal = kwh_color_pal,
    values = ~Rediduals.for.therm,
    title = "KWH Residuals",
    opacity = 1
  ) %>%
  addControl("<h4 style='margin: 10px; padding: 10px; text-align: center;'>XGBoost Residuals for KWH</h4>", position = "topright") %>%
  setView(lng = -87.6298, lat = 41.8781, zoom = 10)

# Display the maps
print(visResidualsTherm)
print(visResidualsKWH)
########################################################################
