source("requirements.R")

options(stringsAsFactors = FALSE)
glottolog_cldf_json <- jsonlite::read_json("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/cldf-metadata.json")

glottolog_version <- glottolog_cldf_json$`prov:wasDerivedFrom`$`dc:created`
day_script_run <- Sys.Date() %>% as.character()

c("This script was run on", day_script_run, "using version", glottolog_version, "of Glottolog derived from the raw data files from the GitHub Repos glottolog/glottolog-cldf. The functions used were from packages as they existed on ", day,", using groundhog-package-versioning") %>%  
  write_lines("Glottolog_lookup_table_Hedvig_output/version_data.txt", sep = " ")

#reading in the files as they are found in the CLDF release
values <- read_csv("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/values.csv", na = c("","<NA>")) %>% 
  rename(Glottocode = Language_ID)

values_wide <- values %>% 
  dcast(Glottocode ~ Parameter_ID, value.var = "Value")

languages <- read_csv("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/languages.csv", na = c("","<NA>")) %>% 
  dplyr::select(-ID) %>% 
  rename(Language_level_ID = Language_ID) 

cldf <- full_join(values_wide,languages) %>% 
  mutate(Language_level_ID = ifelse(level == "language", Glottocode, Language_level_ID))

rm(values, languages, values_wide)

#marking out the isolates
cldf_with_isolates_marked <- cldf %>% 
  mutate(Isolate = ifelse(is.na(Family_ID) & level != "family", "Yes", "No")) %>% 
  mutate(Family_ID_isolates_distinct = ifelse(is.na(Family_ID), Language_level_ID, Family_ID))

cldf_with_isolates_dialects_marked <-cldf_with_isolates_marked %>% 
  filter(Isolate == "Yes") %>% 
  dplyr::select(Family_ID_isolates_distinct = Glottocode, Isolate_fam = Isolate) %>% 
  full_join(cldf_with_isolates_marked) %>% 
  mutate(Isolate = ifelse(Isolate_fam == "Yes", "Yes", Isolate)) %>% 
  filter(!is.na(Name)) 

#adding family_name column
top_genetic <- cldf_with_isolates_dialects_marked %>% 
  filter(level == "family"|Isolate == "Yes" & level =="language") %>% 
  filter(is.na(Family_ID)) %>% 
  dplyr::select(Family_name = Name, Family_ID_isolates_distinct = Glottocode) 

cldf_with_family <- cldf_with_isolates_dialects_marked %>% 
  left_join(top_genetic) %>% 
  distinct()

rm(cldf)

##Adding in areas of linguistic contact from AUTOTYP

AUTOTYP <- read_csv("https://raw.githubusercontent.com/autotyp/autotyp-data/master/data/Register.csv") %>% 
  dplyr::select(glottocode = Glottocode, Area, Longitude, Latitude) %>% 
  filter(glottocode != "balk1252") %>% #There's a set of languages in autotyp that have more than one area, for now they're just hardcoded excluded in these lines
  filter(glottocode != "east2295") %>% 
  filter(glottocode != "indo1316") %>% 
  filter(glottocode != "kyer1238") %>% 
  filter(glottocode != "mart1256") %>% 
  filter(glottocode != "minn1241") %>% 
  filter(glottocode != "noga1249") %>% 
  filter(glottocode != "oira1263") %>% 
  filter(glottocode != "peri1253") %>% 
  filter(glottocode != "taha1241") %>% 
  filter(glottocode != "tibe1272") %>% 
  filter(glottocode != "till1254") %>% 
  filter(glottocode != "toho1245") %>% 
  filter(glottocode != "kati1270")

#This next bit where we find the autotyp areas of languages was written by Seán Roberts
# We know the autotyp-area of langauges in autotyp and their long lat. We don't know the autotyp area of languages in Glottolog. We also can't be sure that the long lat of languoids with the same glottoids in autotyp and glottolog have the exact identical long lat. First let's make two datasets, one for autotyp languages (hence lgs where we know the area) and those that we wish to know about, the Glottolog ones.

lgs_with_known_area <- as.matrix(AUTOTYP[!is.na(AUTOTYP$Area),c("Longitude","Latitude")])
rownames(lgs_with_known_area) <- AUTOTYP[!is.na(AUTOTYP$Area),]$glottocode

known_areas <- AUTOTYP %>% 
  filter(!is.na(Area)) %>% 
  dplyr::select(glottocode, Area) %>% 
  distinct() %>% 
  dplyr::select(AUTOTYP_glottocode = glottocode, everything())

rm(AUTOTYP)

lgs_with_unknown_area <- as.matrix(cldf_with_isolates_dialects_marked[,c("Longitude","Latitude")])
rownames(lgs_with_unknown_area) <- cldf_with_isolates_dialects_marked$Glottocode

# For missing, find area of closest langauge
atDist <- rdist.earth(lgs_with_known_area,lgs_with_unknown_area, miles = F)

rm(lgs_with_known_area, lgs_with_unknown_area)

df_matched_up <- as.data.frame(unlist(apply(atDist, 2, function(x){names(which.min(x))})), stringsAsFactors = F) %>% 
  rename(AUTOTYP_glottocode = `unlist(apply(atDist, 2, function(x) {     names(which.min(x)) }))`)

cldf_with_autotyp <- df_matched_up %>% 
  rownames_to_column("Glottocode") %>%
  full_join(known_areas) %>% 
  right_join(cldf_with_family) %>% 
  dplyr::select(-AUTOTYP_glottocode) %>% 
  rename(AUTOTYP_area = Area) 

#making columns with the names of languages, but stripped so it won't cause trouble in applications like SplitsTree
cldf_with_autotyp$Name %>% 
  stringi::stri_trans_general("latin-ascii") %>% 
  str_replace_all("\\(", "") %>%  
  str_replace_all("\\)", "") %>% 
  str_replace_all("\\-", "") %>% 
  str_replace_all("\\'", "?") ->  cldf_with_autotyp$Name_stripped

cldf_with_autotyp$Name_stripped %>% 
  str_replace_all(" ", "_")  ->  cldf_with_autotyp$Name_stripped_no_spaces

##adding distinct color by language family

n <- length(unique(cldf_with_autotyp$Family_ID))

color_vector <- distinctColorPalette(n)

cldf_with_color <- cldf_with_autotyp

cldf_with_color$Family_color <- color_vector[as.factor(cldf_with_autotyp$Family_ID)]

cldf_with_color_isolates_marked <- cldf_with_color %>% 
  mutate(Family_color = ifelse(Isolate == "Yes", "#000000", Family_color))

##writing it out!!

df_for_writing <- cldf_with_color_isolates_marked %>% 
  dplyr::select(Glottocode, Name, level, Family_name, Macroarea, AUTOTYP_area, category, ISO639P3code, Countries, Longitude, Latitude, med, aes, Family_ID_isolates_distinct, Isolate, Language_level_ID, Name_stripped, Name_stripped_no_spaces, classification, subclassification, Family_color) %>% 
  mutate(Language_level_ID = ifelse(level == "language", Glottocode, Language_level_ID))

df_for_writing %>% 
  write_tsv("Glottolog_lookup_table_Hedvig_output/Heti_Glottolog_lookup_table_cldf_version.tsv", na = "")