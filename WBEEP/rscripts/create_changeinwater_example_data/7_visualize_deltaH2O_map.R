library(RColorBrewer)
library(geojsonio)
library(sf) 
library(dplyr)
library(ggplot2)
library(mapview)

# This topojson file was shared by David
topo_data_conus <- topojson_read("WBEEP/cache/simp_10.topojson")
topo_data_conus$hru_id_nat <- factor(topo_data_conus$hru_id_nat)
conus_sf <- st_as_sf(topo_data_conus)
st_crs(conus_sf) <- "+proj=lcc +lat_1=43.26666666666667 +lat_2=42.06666666666667 +lat_0=41.5 +lon_0=-93.5 +x_0=1500000 +y_0=1000000 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"

# Make plots using historic percentiles by HRU
for(season in c("winter", "spring", "summer", "autumn")) {
  
  map_data <- readRDS(sprintf("WBEEP/cache/deltaH2O_map_hru_data_%s.rds", season))
  conus_data_sf <- left_join(conus_sf, map_data, by = c("hru_id_nat" = "HRU"))
  
  # Turn categories into colors
  deltaH2O_low_col <- colorRampPalette(c("#CC4C02", "#FED98E")) # Brown to yellow
  deltaH2O_high_col <- colorRampPalette(c("#a7b9d7", "#144873")) # Light blue to dark blue
  map_cats <- c("very low", "low", "average", "high", "very high")
  map_colors <- c(deltaH2O_low_col(2), "#FFFFFF", deltaH2O_high_col(2))
  names(map_colors) <- map_cats
  conus_data_sf$map_cat <- factor(conus_data_sf$map_cat, levels=map_cats)
  
  # Plot
  conus_nosmoothing <- ggplot(conus_data_sf, aes(fill=map_cat)) +
    geom_sf(color = NA)+
    scale_fill_manual(name = "Water Availability", values = map_colors) +
    theme_void() +
    coord_sf(datum = NA)
  
  # takes ~10 min to save
  ggsave(conus_nosmoothing, 
         filename = sprintf("WBEEP/img/conus_deltaH2O_hru_%s.png", season), 
         height = 8, width = 11)
  
  message(sprintf("Completed %s", season))
}

# Make plots using historic percentiles for all of CONUS
for(season in c("winter", "spring", "summer", "autumn")) {
  
  map_data <- readRDS(sprintf("WBEEP/cache/deltaH2O_map_data_%s.rds", season))
  conus_data_sf <- left_join(conus_sf, map_data, by = c("hru_id_nat" = "HRU"))
  
  # Turn categories into colors
  deltaH2O_low_col <- colorRampPalette(c("#CC4C02", "#FED98E")) # Brown to yellow
  deltaH2O_high_col <- colorRampPalette(c("#a7b9d7", "#144873")) # Light blue to dark blue
  map_cats <- c("very low", "low", "average", "high", "very high")
  map_colors <- c(deltaH2O_low_col(2), "#FFFFFF", deltaH2O_high_col(2))
  names(map_colors) <- map_cats
  conus_data_sf$map_cat <- factor(conus_data_sf$map_cat, levels=map_cats)
  
  # Plot
  conus_nosmoothing <- ggplot(conus_data_sf, aes(fill=map_cat)) +
    geom_sf(color = NA)+
    scale_fill_manual(name = "Water Availability", values = map_colors) +
    theme_void() +
    coord_sf(datum = NA)
  
  # takes ~10 min to save
  ggsave(conus_nosmoothing, 
         filename = sprintf("WBEEP/img/conus_deltaH2O_conus_%s.png", season), 
         height = 8, width = 11)
  
  message(sprintf("Completed %s", season))
}

all_deltaH2O <- readRDS("WBEEP/cache/deltaH2O_yrs.rds")
max_deltaH2O <- max(all_deltaH2O$deltaH2O)
min_deltaH2O <- min(all_deltaH2O$deltaH2O)

# Make plots that don't use historic context and just use values
# Every which way I try this one results in invisible values due to the extreme high/lows
for(season in c("winter", "spring", "summer", "autumn")) {
  
  map_data <- readRDS(sprintf("WBEEP/cache/deltaH2O_map_data_%s.rds", season))
  conus_data_sf <- left_join(conus_sf, map_data, by = c("hru_id_nat" = "HRU"))
  
  # test
  conus_data_sf <- conus_data_sf[48000:58000,]
  
  # Use the same colors (except white), but not the categories
  deltaH2O_low_col <- colorRampPalette(c("#CC4C02", "#FED98E")) # Brown to yellow
  deltaH2O_high_col <- colorRampPalette(c("#a7b9d7", "#144873")) # Light blue to dark blue
  map_colors <- c(deltaH2O_low_col(2), "#ffffff", deltaH2O_high_col(2))
  
  # Plot
  conus_vals_rescaled <- ggplot(conus_data_sf, aes(fill=deltaH2O)) +
    geom_sf(color = NA)+
    scale_fill_gradientn(name = "Water Flux, in/day", 
                         colors = map_colors,
                         limits = c(min_deltaH2O, max_deltaH2O),
                         values = scales::rescale(c(min_deltaH2O, 0, max_deltaH2O))) +
    theme_void() +
    coord_sf(datum = NA)
  
  # conus_vals <- ggplot(conus_data_sf, aes(fill=deltaH2O)) +
  #   geom_sf(color = NA)+
  #   scale_fill_gradient2(name = "Water Flux, in/day",
  #                        low = head(map_colors,1),
  #                        midpoint = 0,
  #                        high = tail(map_colors,1)) +
  #   theme_void() +
  #   coord_sf(datum = NA)
  
  # takes ~10 min to save
  ggsave(conus_vals_rescaled, 
         filename = sprintf("WBEEP/img/conus_deltaH2O_vals_rescaled_%s.png", season), 
         height = 8, width = 11)
  
  # ggsave(conus_vals, 
  #        filename = sprintf("WBEEP/img/conus_deltaH2O_vals_%s.png", season), 
  #        height = 8, width = 11)
  
  message(sprintf("Completed %s", season))
}
