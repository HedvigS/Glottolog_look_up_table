source("Making_Hedvigs_glottolog_lookup_table_Heti_edition.R")

glottolog_lookup_table <- read_tsv("Glottolog_lookup_table_Hedvig_output/Heti_Glottolog_lookup_table_cldf_version.tsv")

glottolog_lookup_table %>% 
  filter(level == "language") %>% 
  filter(Family_name != 'Bookkeeping') %>% 
  filter(Family_name != 'Unattested') %>% 
  filter(Family_name != 'Pidgin') %>%
  filter(Family_name != 'Artificial Language') %>% 
  filter(Family_name != 'Speech Register')  %>% 
  mutate(Name_split = str_split(Name, " ")) %>% 
  unnest(Name_split) %>%  
  group_by(Name_split) %>% 
  summarise(n = n()) %>% 
  arrange(desc(n)) %>% 
  write_tsv("Glottolog_lookup_table_Hedvig_output/name_freq.tsv")