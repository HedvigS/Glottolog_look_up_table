source("requirements.R")

options(stringsAsFactors = FALSE)

#If you're on a machine that has rendered a version of treedb from the Glottolog repos, then you can read in the newest version from there and place it here. If you're not, just read in the treedb.tsv version that is in this folder already 

#ATTN: comment this out if you're not at a machine that's rendering treed.csv and want to read in the latest version from the Glottolog repos
#read_csv("../../../../Documents/glottolog/scripts/treedb.csv") %>%
#  write_tsv("treedb.tsv")

treedb <- read_csv("treedb.csv") %>% 
  dplyr::select(Glottocode = id, Macroarea =macroareas, Longitude = longitude, Latitude = latitude, Language_level_ID = dialect_language_id, Name = name, path, Family_ID = family_id, level, Parent_ID = parent_id, iso639_3, countries, endangerment_status)

###  inserting the names of the language families
top_genetic <- treedb %>% 
  distinct(Family_ID) %>% 
  filter(!is.na(Family_ID)) %>% 
  mutate(top = "top")

treedb %>% 
  filter(level == "family") %>%
  select(Family_ID, Family_name = Name, Family_Glottocode = Glottocode) %>%
  select(Family_ID = Family_Glottocode, Family_name) %>% 
  full_join(top_genetic)-> Glottolog_family

Glottolog_family %>% 
  right_join(treedb, by = "Family_ID") %>% 
  distinct()-> Glottolog_with_family

Glottolog_with_family %>% 
  filter(level == "language") %>% 
  filter(is.na(Parent_ID)) %>% 
  mutate(Family_name_isolates_distinct = Name) %>% 
  mutate(Top_genetic_unit_ID_isolates_distinct = path) %>% 
  mutate(Isolate = "Yes") -> Isolates

Glottolog_with_family %>% 
  filter(level != "language"|!is.na(Parent_ID)) %>% 
  mutate(Family_name_isolates_distinct = Family_name) %>% 
  mutate(Top_genetic_unit_ID_isolates_distinct = Family_ID) %>% 
  mutate(Isolate = "No") %>%  
  rbind(Isolates) %>% 
  dplyr::select(-top) -> Glottolog_with_family_with_isolates

rm(Glottolog_with_family, Isolates, Glottolog_family)


###MED BUSINES STARTS ####
#Here we read in the descriptive status per languoid form Glottolog

#trying to read in directly from the URL. If you haven't got internet or jsut read it in, just read in Glottolog_MED_from_json.tsv at the end
# read url and convert to data.frame
Glottolog_json_MED <- jsonlite::fromJSON('https://raw.githubusercontent.com/clld/glottolog3/master/glottolog3/static/ldstatus.json') %>%
  as_tibble() %>%
  t(.) %>%
  as.data.frame() %>%
  rownames_to_column("Glottocode")

## out resulting dataframe has 3 columns, glottocode V1 which is the MED and then V2 is a list of all more refs for that langauge, including the one that is MED. Here, we just extract the type that the MED is in V1

str_extract_all(string = Glottolog_json_MED$V1, pattern = "comparative|grammar_sketch|overview|long_grammar|wordlist|bibliographical|minimal|new_testament|specific_feature|socling|dictionary|phonology|text|dialectology|ethnographic|grammar") -> Glottolog_json_MED$MED

##str_extract_all outputs characther(0) if it doesn't find what it's looking for, here we just convert those into NAs
Glottolog_json_MED$MED <- lapply(Glottolog_json_MED$MED, function(x) if(identical(x, character(0))) NA_character_ else x)

##the previous df has the cols as lists, which screws with the writing later. Let's just make those into carachter vectors for good measure.

Glottolog_json_MED %>%
  dplyr::select(Glottocode, desc_status = MED) %>%
  mutate(desc_status = as.character(desc_status)) %>%
  mutate(Glottocode = as.character(Glottocode)) -> Glottolog_MED

rm(Glottolog_json_MED)

#### MED business over ####

Glottolog_with_family_with_isolates %>% 
  left_join(Glottolog_MED) %>%
  distinct() -> Glottolog_with_family_with_isolates_MED

rm(Glottolog_MED, treedb, Glottolog_with_family_with_isolates)

#putting the macroarea, longitude and latitude and language family of their parents on all dialects

Glottolog_with_family_with_isolates_MED %>% 
  filter(level == "language") %>%
  select(Language_level_name = Name, Language_level_ID = Glottocode, Longitude, Latitude, Macroarea, Family_name, Family_ID, countries, desc_status, Isolate, Family_name_isolates_distinct, Top_genetic_unit_ID_isolates_distinct) -> Glottolog_dialect_parents

Glottolog_families <- Glottolog_with_family_with_isolates_MED %>% 
  filter(level == "family")

Glottolog_with_family_with_isolates_MED %>% 
  filter(level == "dialect") %>% 
  dplyr::select(-Longitude, -Latitude, -Macroarea, -Family_name, -Family_ID, -countries, -Parent_ID, -desc_status, -Isolate) %>%
  left_join(Glottolog_dialect_parents) %>% 
  mutate(Parent_ID = Language_level_ID) -> Glottolog_dialects_enriched

rm(Glottolog_dialect_parents)

Glottolog_with_family_with_isolates_MED %>%
  filter(level != "dialect" & level != "family") %>%
  full_join(Glottolog_dialects_enriched) %>% 
  dplyr::select(Name, Glottocode, iso639_3, level, endangerment_status, desc_status, Parent_ID, Language_level_name, Language_level_ID, Top_genetic_unit_ID = Family_ID, Family_name, Path = path,  Countries = countries, Longitude, Latitude, Macroarea, Isolate, Family_name_isolates_distinct, Top_genetic_unit_ID_isolates_distinct) -> Glottolog_languages_and_dialects_enriched

rm(Glottolog_dialects_enriched, Glottolog_with_family_with_isolates)

Glottolog_languages_and_dialects_enriched %>% 
  filter(level != "dialect") %>%
  dplyr::select(-Language_level_ID) %>% 
  mutate(Language_level_name = Name) %>% 
  mutate(Language_level_ID = Glottocode) %>% 
  full_join(filter(Glottolog_languages_and_dialects_enriched, level == "dialect")) %>% 
  full_join(Glottolog_families) %>% 
  dplyr::select(-path, -countries, -Family_ID)-> Glottolog_language_leveled

rm(Glottolog_families, Glottolog_languages_and_dialects_enriched)

Glottolog_language_leveled$Name %>% 
  stringi::stri_trans_general("latin-ascii") %>% 
  str_replace_all("\\(", "") %>%  
  str_replace_all("\\)", "") %>% 
  str_replace_all("\\-", "") %>% 
  str_replace_all("\\'", "")->  Glottolog_language_leveled$Name_stripped

##Adding in areas of linguistic contact from AUTOTYP

AUTOTYP <- read_csv("https://raw.githubusercontent.com/autotyp/autotyp-data/master/data/Register.csv") %>% 
  dplyr::select(Glottocode, Area, Longitude, Latitude) %>% 
  filter(Glottocode != "balk1252") %>% #There's a set of languages in autotyp that have more than one area, for now they're just hardcoded excluded in these lines
  filter(Glottocode != "east2295") %>% 
  filter(Glottocode != "indo1316") %>% 
  filter(Glottocode != "kyer1238") %>% 
  filter(Glottocode != "mart1256") %>% 
  filter(Glottocode != "minn1241") %>% 
  filter(Glottocode != "noga1249") %>% 
  filter(Glottocode != "oira1263") %>% 
  filter(Glottocode != "peri1253") %>% 
  filter(Glottocode != "taha1241") %>% 
  filter(Glottocode != "tibe1272") %>% 
  filter(Glottocode != "till1254") %>% 
  filter(Glottocode != "toho1245") %>% 
  filter(Glottocode != "kati1270")

# We know the autotyp-area of langauges in autotyp and their long lat. We don't know the autotyp area of languages in Glottolog. We also can't be sure that the long lat of languoids with the same glottoids in autotyp and glottolog have the exact identical long lat. First let's make two datasets, one for autotyp languages (hence lgs where we know the area) and those that we wish to know about, the Glottolog ones.
lgs_with_known_area <- as.matrix(AUTOTYP[!is.na(AUTOTYP$Area),c("Longitude","Latitude")])
rownames(lgs_with_known_area) <- AUTOTYP[!is.na(AUTOTYP$Area),]$Glottocode

known_areas <- AUTOTYP %>% 
  filter(!is.na(Area)) %>% 
  dplyr::select(Glottocode, Area) %>% 
  distinct() %>% 
  dplyr::select(AUTOTYP_Glottocode = Glottocode, everything())

rm(AUTOTYP)

lgs_with_unknown_area <- as.matrix(Glottolog_language_leveled[,c("Longitude","Latitude")])
rownames(lgs_with_unknown_area) <- Glottolog_language_leveled$Glottocode

# For missing, find area of closest langauge
atDist <- rdist.earth(lgs_with_known_area,lgs_with_unknown_area, miles = F)

rm(lgs_with_known_area, lgs_with_unknown_area)

Glottolog_matched_up <- as.data.frame(unlist(apply(atDist, 2, function(x){names(which.min(x))})), stringsAsFactors = F) %>% 
  rename(AUTOTYP_Glottocode = `unlist(apply(atDist, 2, function(x) {     names(which.min(x)) }))`)

rm(atDist)

Glottolog_language_leveled_with_autotyp_area <- Glottolog_matched_up %>% 
  rownames_to_column("Glottocode") %>%  
  left_join(known_areas) %>% 
  full_join(Glottolog_language_leveled) %>% 
  dplyr::select(-AUTOTYP_Glottocode) %>% 
  rename(AUTOTYP_area = Area) %>% 
  rename(glottocode = Glottocode)
  

rm(Glottolog_matched_up, Glottolog_language_leveled, known_areas)


Glottolog_language_leveled_with_autotyp_area$Name_stripped_no_spaces <- Glottolog_language_leveled_with_autotyp_area$Name_stripped %>% 
  str_replace_all(" ", "_")


dir.create("Glottolog_lookup_table_Hedvig_output")


write_tsv(Glottolog_language_leveled_with_autotyp_area, path = "Glottolog_lookup_table_Hedvig_output/Glottolog_lookup_table_Heti_edition.tsv")

cat(paste("This file was created ", Sys.Date(), "by Hedvig Skirgård based on Glottolog and AUTOTYP data. More information at https://github.com/HedvigS/Glottolog_look_up_table"), file= "Glottolog_lookup_table_Hedvig_output/Glottolog_lookup_meta.txt", sep = "\n")            

zip(zipfile = "Glottolog_lookup_table_Hedvig_output", files = "Glottolog_lookup_table_Hedvig_output")
            