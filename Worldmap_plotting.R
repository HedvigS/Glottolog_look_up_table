source("requirements.R")

dir.create("plots")

#worldmaps
#rendering a worldmap that is pacific centered
world <- map_data('world', wrap=c(-25,335), ylim=c(-56,80), margin=T)

lakes <- map_data("lakes", wrap=c(-25,335), col="white", border="gray", ylim=c(-55,65), margin=T)

Glottolog <- read_tsv("Glottolog_lookup_table_Hedvig_output/Glottolog_lookup_table_Heti_edition.tsv") %>% 
  filter(level == "language") 

Glottolog %>%
  filter(!is.na(Family_name_isolates_distinct)) %>%
  filter(Family_name != 'Bookkeeping') %>% 
  filter(Family_name != 'Unattested') %>%
  filter(Family_name != 'Artificial Language') %>% 
  filter(Family_name != 'Unclassifiable') %>% 
  filter(Family_name != 'Speech Register')  -> Glottolog

#shifting the longlat of the dataframe to match the pacific centered map
Glottolog_long_shifted <- Glottolog %>% 
  mutate(Longitude = if_else(Longitude <= -25, Longitude + 360, Longitude))


#Basemap
basemap <- ggplot(Glottolog_long_shifted ) +
  geom_polygon(data=world, aes(x=long,
                               y=lat,group=group),
               colour="gray90",
               fill="gray90", size = 0.5) +
  geom_polygon(data=lakes, aes(x=long,
                               y=lat,group=group),
               colour="gray90",
               fill="white", size = 0.3)  +
  theme(legend.position="none",
        panel.grid.major = element_blank(), #all of these lines are just removing default things like grid lines, axises etc
        panel.grid.minor = element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        axis.line = element_blank(),
        panel.border = element_blank(),
        panel.background = element_rect(fill = "white"),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank())   +
  coord_map(projection = "vandergrinten", ylim=c(-56,67)) +
  expand_limits(x = Glottolog_long_shifted $Longitude, y = Glottolog_long_shifted $Latitude)

png("plots/Glottolog_all_languages.png", width =1200, height = 700)
plot(basemap + geom_point(stat = "identity", size = 3,aes(x=Longitude, y=Latitude), fill = Glottolog_long_shifted$Family_color , shape = 21, alpha = 0.4, stroke = 0.4, color = "grey44") +   
       theme(title  = element_text(size = 32)) )
dev.off()


