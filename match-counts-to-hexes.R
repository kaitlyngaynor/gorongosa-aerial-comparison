# Map the aerial counts for each period onto the camera grid

library(here)
library(tidyverse)
library(sf)
library(sp)
library(rgdal)

# read in aerial count data from Stalmans et al Plos One paper
aerial_data <- read_csv(here::here("data", "aerial-count", "stalmans-plosone-data.csv")) 

# convert to sf object
aerial_data_sf <- st_as_sf(aerial_data, 
                           coords = c("Longitude", "Latitude"),
                           crs = 4326)

# bring in camera hexes
hexes <- st_read(here::here('data', 'camera-trap'), 'CameraGridHexes') %>% 
  st_transform(crs = 4326)

# map the points onto the hexagonal grid cells
aerial_data_hexes <- st_join(aerial_data_sf, hexes)

# see what species we are looking at
hex_summary <- aerial_data_hexes %>% 
  st_drop_geometry() %>% # remove spatial attributes
  group_by(Species, Count, StudySite) %>%
  summarise(TotalIndividuals = sum(Number), TotalGroups = n()) %>% 
  drop_na() %>%  # drop points outside of camera grid 
  ungroup()

head(hex_summary)

# change the Tinley names to match mine
hex_summary <- hex_summary %>%
  mutate(Species = fct_recode(Species, "Baboon" = "Baboon troop")) %>%
  mutate(Species = fct_recode(Species, "Wildebeest" = "Blue wildebeest")) %>%
  mutate(Species = fct_recode(Species, "Reedbuck" = "Common reedbuck")) %>%
  mutate(Species = fct_recode(Species, "Duiker_common" = "Duiker grey")) %>%
  mutate(Species = fct_recode(Species, "Duiker_red" = "Duiker red")) %>%
  mutate(Species = fct_recode(Species, "Sable_antelope" = "Sable"))

# hmm, seems like baboon were NOT included in Marc's paper, even though they WERE in the shapefile that he sent me (paper was only herbivores)
head(hex_summary)  

unique(hex_summary$Species) # 19 species included across all counts

# export the hex summary
write.csv(hex_summary, "data/hex-summary.csv")
