source("requirements.R")

if (!dir.exists("plots")) { dir.create("plots") }

values <- read_csv("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/values.csv", na = c("","<NA>")) %>% 
  rename(Glottocode = Language_ID)

values_wide <- values %>% 
  dcast(Glottocode ~ Parameter_ID, value.var = "Value")

languages <- read_csv("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/languages.csv", na = c("","<NA>")) %>% 
  dplyr::select(-ID) %>% 
  rename(Language_level_ID = Language_ID) 

Glottolog <- full_join(values_wide,languages) %>% 
  mutate(Language_level_ID = ifelse(level == "language", Glottocode, Language_level_ID))

rm(values, languages, values_wide)

#worldmaps
#rendering a worldmap that is pacific centered
world <- map_data('world', wrap=c(-25,335), ylim=c(-56,80), margin=T)

lakes <- map_data("lakes", wrap=c(-25,335), col="white", border="gray", ylim=c(-55,65), margin=T)

Glottolog_only_languages <- Glottolog %>%
  filter(Family_ID != 'book1242') %>% 
  filter(Family_ID != 'unat1236') %>%
  filter(Family_ID != 'arti1236') %>% 
  filter(Family_ID != 'pidg1258') %>% 
  filter(Family_ID != 'spee1234') %>% 
  filter(level =="language")

##calcualting unique distinct color for each family (isolates all get same)

n <- length(unique(Glottolog_only_languages$Family_ID))

color_vector <- distinctColorPalette(n)

Glottolog_only_languages$Family_color <- color_vector[as.factor(Glottolog_only_languages$Family_ID)]


#shifting the longlat of the dataframe to match the pacific centered map
Glottolog_long_shifted <- Glottolog_only_languages %>% 
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
  coord_map(projection = "vandergrinten") 

png("plots/Glottolog_all_languages.png", width =1200, height = 700)
plot(basemap + geom_point(stat = "identity", size = 2.5,aes(x=Longitude, y=Latitude), fill = Glottolog_long_shifted$Family_color, shape = 21, alpha = 0.4, stroke = 0.4, color = "grey44") +   
       theme(title  = element_text(size = 32)) )
dev.off()