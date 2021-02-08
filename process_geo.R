pckgs <- c('dplyr','tidyr','readr','magrittr','stringr','forcats','data.table','broom',
           'ggplot2','cowplot','ggmap','ggh4x','ggrepel',
           'sf', 'rgdal','maptools','cartogram')
for (pp in pckgs) { library(pp,character.only=T,quietly = T,warn.conflicts = F)}

dir_base <- getwd()
dir_output <- file.path(dir_base, 'output')
dir_figures <- file.path(dir_base, 'figures')
dir_data <- file.path(dir_base, 'data')
dir_geo <- file.path(dir_data, 'geo')

###########################
# ---- (1) LOAD DATA ---- #

# PHU data
df_phu <- read_csv(file.path(dir_output, 'df_phu.csv'))
df_deaths <- read_csv(file.path(dir_output, 'df_deaths.csv'))
df_census <- read_csv(file.path(dir_output, 'df_census.csv'))
df_phu_year <- read_csv(file.path(dir_output,'phu_deaths_year.csv'))


path_shp <- file.path(dir_geo, 'Ministry_of_Health_Public_Health_Unit_Boundary.shp')
shp_phu <- read_sf(path_shp) %>% 
  mutate(area = as.numeric(units::set_units(st_area(geometry),km^2))) %>% 
  dplyr::select(PHU_NAME_E,area) %>% dplyr::rename(PHU=PHU_NAME_E)
# Figure out mapping
u_PHU_full <- sort(unique(shp_phu$PHU))
u_PHU_short <- sort(unique(df_phu$PHU))

di_PHU <- list()
for (phu in u_PHU_short) {
  mtch <- str_subset(u_PHU_full, phu)
  ll <- length(mtch)
  if (ll == 1) {
    di_PHU[[mtch]] <- phu
  }
}
di_PHU["Hamilton Public Health Services"] <- "City of Hamilton Services"
di_PHU["Hastings and Prince Edward Counties Health Unit"] <- "Hastings Prince Edward"
di_PHU["Sudbury and District Health Unit"] <- "Public Health Sudbury & Districts"
di_PHU["Region of Waterloo, Public Health"] <- "Region of Waterloo and Emergency Services"

# Assign new names
shp_phu <-  mutate(shp_phu, PHU=as.character(factor(PHU,levels=names(unlist(di_PHU)),
                                                    labels=as.vector(unlist(di_PHU)))))


#####################################
# ---- (2) APPEND DEMOGRAPHICS ---- #

# Merge opioid with census
# setdiff(unique(df_census$PHU), unique(df_phu_year$PHU))

dat_demo <- df_phu_year %>% 
  dplyr::select(year,PHU,msr,value) %>% 
  pivot_wider(id_cols=c(year,PHU),names_from='msr',values_from='value')
dat_demo <- df_census %>% 
  pivot_wider(id_cols=c(year,PHU),names_from='cn',values_from='value') %>% 
  dplyr::select(-area_km2) %>% 
  left_join(dat_demo)


dat_demo %>% 
  pivot_longer(!c(year,PHU,n_death,r_death),names_to='cn') %>% 
  arrange(year,cn)



# Merge census
shp_phu <- shp_phu %>% left_join(dat_demo,'PHU')

# Merge on the mortatily data



# Get the tabular form of the data
shp_phu %>% dplyr::select(-geometry) %>% as_tibble
  
  



# shp_phu %>% as_tibble() %>% dplyr::select(area,area_km2,PHU) %>% 
#   mutate_if(is.double,list(~log(.))) %>% 
#   mutate(err=abs((area-area_km2))) %>% arrange(-err)
# ggplot(aes(x=area,y=area_km2)) + geom_point()  + 
# theme_bw() + geom_abline(slope=1,intercept = 0)


#########################
# ---- (3) FIGURES ---- #

# (i) Geofaceting
#   https://ryanhafen.com/blog/geofacet/
# (ii)


ggplot(st_transform(shp_phu,crs=4326),aes(fill=income)) + theme_bw() +
  geom_sf() + scale_fill_viridis_c() + 
  labs(x='Longitude',y='Latitude')

shp_cartogram <- cartogram_cont(st_transform(shp_phu, crs = 3978),"poverty_child", itermax = 5)

ggplot(shp_cartogram,aes(fill=poverty_child)) + theme_bw() +
  geom_sf() + scale_fill_viridis_c() + 
  labs(x='Longitude',y='Latitude') + 
  ggrepel::geom_text_repel(data = shp_cartogram,
    aes(label = PHU, geometry = geometry),
    stat = "sf_coordinates",
    min.segment.length = 0,size=3,max.overlaps = 50)



