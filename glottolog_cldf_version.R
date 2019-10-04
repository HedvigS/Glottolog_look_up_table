library(tidyverse)
library(reshape2)

values <- read_csv("../glottolog-cldf/cldf/values.csv", na = "<NA>")

values_wide <- values %>% 
  dcast(Language_ID ~ Parameter_ID, value.var = "Value") %>% 
  rename(ID = Language_ID)

language_table <- read_csv("../glottolog-cldf/cldf/languages.csv", na = "<NA>") %>% 
  rename(glottocode = Glottocode) %>% 
  rename(Language_level_ID = Language_ID)

both_wide <- full_join(language_table, values_wide)

write_tsv(both_wide, "glottolog_cldf_language_table.tsv")

both_wide %>% 
  filter(level == "dialect") %>% 
  filter(!is.na(aes)) %>% View()