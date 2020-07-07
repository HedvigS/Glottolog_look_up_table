source("requirements.R")

options(stringsAsFactors = FALSE)

#reading in the files as they are found in the CLDF release
values <- read_csv("../glottolog-cldf/cldf/values.csv", na = c("","<NA>")) %>% 
  rename(Glottocode = Language_ID)

values_wide <- values %>% 
  dcast(Glottocode ~ Parameter_ID, value.var = "Value")

languages <- read_csv("../glottolog-cldf/cldf/languages.csv", na = c("","<NA>")) %>% 
  dplyr::select(-Language_ID, -ID) 

cldf <- full_join(values_wide,languages) 

rm(values, languages, values_wide)

#adding family_name column
top_genetic <- cldf %>% 
  filter(level == "family") %>% 
  filter(is.na(Family_ID)) %>% 
  select(Family_ID, Family_name = Name, Family_glottocode = Glottocode) %>%
  select(Family_ID = Family_glottocode, Family_name)

cldf_with_family <- cldf %>% 
  mutate(Family_ID = if_else(is.na(Family_ID) & level == "family", Glottocode, Family_ID)) %>% 
  full_join(top_genetic)

rm(cldf)

#marking out the isolates
isolates_df <- cldf_with_family %>% 
  filter(level == "language") %>% 
  filter(is.na(Family_ID)) %>% 
  mutate(Family_name_isolates_distinct = Name) %>% 
  mutate(Family_ID_isolates_distinct = Glottocode) %>% 
  mutate(Isolate = "Yes")

cldf_with_isolates <- cldf_with_family %>% 
  filter(level != "language"|!is.na(Family_ID)) %>% 
  mutate(Family_name_isolates_distinct = Family_name) %>% 
  mutate(Family_ID_isolates_distinct = Family_ID) %>% 
  mutate(Isolate = "No") %>%  
  rbind(isolates_df) 

rm(isolates_df, top_genetic, cldf_with_family)

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

lgs_with_unknown_area <- as.matrix(cldf_with_isolates[,c("Longitude","Latitude")])
rownames(lgs_with_unknown_area) <- cldf_with_isolates$Glottocode

# For missing, find area of closest langauge
atDist <- rdist.earth(lgs_with_known_area,lgs_with_unknown_area, miles = F)

rm(lgs_with_known_area, lgs_with_unknown_area)

df_matched_up <- as.data.frame(unlist(apply(atDist, 2, function(x){names(which.min(x))})), stringsAsFactors = F) %>% 
  rename(AUTOTYP_glottocode = `unlist(apply(atDist, 2, function(x) {     names(which.min(x)) }))`)

cldf_with_autotyp <- df_matched_up %>% 
  rownames_to_column("Glottocode") %>%
  full_join(known_areas) %>% 
  right_join(cldf_with_isolates) %>% 
  dplyr::select(-AUTOTYP_glottocode) %>% 
  rename(AUTOTYP_area = Area) 

##adding in a column which tells, for dialects, which is the language leveled parent

Parent_IDs <- cldf_with_autotyp %>% 
  filter(level == "language") %>% 
  dplyr::select(Parent_ID = Glottocode, Language_level_ID = Glottocode)

#first tier
cldf_with_parent_ID <- cldf_with_autotyp %>% 
  mutate(Parent_ID = str_sub(classification,-8,-1))

Dialects_first_tier <- cldf_with_parent_ID %>% 
  left_join(Parent_IDs) %>% 
  filter(level == "dialect")

Dialects_first_tier_solved <- Dialects_first_tier %>% 
  filter(!is.na(Language_level_ID))

#second tier
Dialects_second_tier <- Dialects_first_tier %>% 
  filter(is.na(Language_level_ID)) %>% 
  dplyr::select(-Language_level_ID) %>% 
  mutate(Parent_ID_2 = str_sub(classification,-17, -1)  %>% str_sub(start = 1, end = 8)) %>% 
  left_join(Parent_IDs %>% rename(Parent_ID_2= Parent_ID))

Dialects_second_tier_solved <- Dialects_second_tier %>% 
  filter(!is.na(Language_level_ID))

#third tier
Dialects_third_tier <-  Dialects_second_tier %>% 
  filter(is.na(Language_level_ID)) %>% 
  dplyr::select(-Language_level_ID) %>% 
  mutate(Parent_ID_3 = str_sub(classification,-26, -1)  %>% str_sub(start = 1, end = 8)) %>% 
  left_join(Parent_IDs %>% rename(Parent_ID_3 = Parent_ID))

Dialects_third_tier_solved <- Dialects_third_tier %>% 
  filter(!is.na(Language_level_ID))

#fourth
Dialects_fourth_tier <-  Dialects_third_tier %>% 
  filter(is.na(Language_level_ID)) %>% 
  dplyr::select(-Language_level_ID) %>% 
  mutate(Parent_ID_4 = str_sub(classification,-35, -1)  %>% str_sub(start = 1, end = 8)) %>% 
  left_join(Parent_IDs %>% rename(Parent_ID_4 = Parent_ID))

Dialects_fourth_tier_solved <- Dialects_fourth_tier %>% 
  filter(!is.na(Language_level_ID))

#fifth
Dialects_fifth_tier<- Dialects_fourth_tier %>% 
  filter(is.na(Language_level_ID)) %>% 
  filter(is.na(Language_level_ID)) %>% 
  dplyr::select(-Language_level_ID) %>% 
  mutate(Parent_ID_5 = str_sub(classification,-44, -1)  %>% str_sub(start = 1, end = 8)) %>% 
  left_join(Parent_IDs %>% rename(Parent_ID_5 = Parent_ID))

Dialects_fifth_tier_solved <- Dialects_fifth_tier %>% 
  filter(!is.na(Language_level_ID))

#sixth
Dialects_sixth_tier <- Dialects_fifth_tier %>% 
  filter(is.na(Language_level_ID)) %>% 
  dplyr::select(-Language_level_ID) %>% 
  mutate(Parent_ID_6 = str_sub(classification,-53, -1)  %>% str_sub(start = 1, end = 8)) %>% 
  left_join(Parent_IDs %>% rename(Parent_ID_6 = Parent_ID))

Dialects_sixth_tier_solved <- Dialects_sixth_tier %>% 
  filter(!is.na(Language_level_ID))

Dialects_all_tiers_solved <- Dialects_sixth_tier_solved %>% 
  full_join(Dialects_fifth_tier_solved) %>% 
  full_join(Dialects_fourth_tier_solved) %>% 
  full_join(Dialects_third_tier_solved) %>% 
  full_join(Dialects_second_tier_solved) %>% 
  full_join(Dialects_first_tier_solved)

cldf_with_language_level <- cldf_with_autotyp %>% 
  filter(level != "dialect") %>% 
  full_join(Dialects_all_tiers_solved)

##adding in name, autotyp area and other things to the language level per dialect

Language_level_meta_df <- cldf_with_language_level %>% 
  filter(level == "language") %>%
  dplyr::select(Language_level_ID = Glottocode, AUTOTYP_area_language_level= AUTOTYP_area, Language_level_longitude = Longitude, Language_level_latitude = Latitude, Isolate)

dialect_df_enriched <- cldf_with_language_level %>% 
  filter(level == "dialect") %>% 
  dplyr::select(-Isolate) %>% 
  left_join(Language_level_meta_df) %>% 
  mutate(Longitude = if_else(is.na(Longitude), Language_level_longitude, Longitude)) %>% 
  mutate(Latitude = if_else(is.na(Latitude), Language_level_latitude, Latitude)) %>% 
  mutate(AUTOTYP_area = if_else(is.na(AUTOTYP_area), AUTOTYP_area_language_level, AUTOTYP_area)) %>% 
  dplyr::select(-Language_level_longitude, -Language_level_latitude, -AUTOTYP_area_language_level)

cldf_dialects_enriched <- cldf_with_language_level %>% 
  filter(level != "dialect") %>% 
  full_join(dialect_df_enriched)

rm(list=setdiff(ls(), c("cldf_dialects_enriched")))

#making columns with the names of languages, but stripped so it won't cause trouble in applications like SplitsTree
cldf_dialects_enriched$Name %>% 
  stringi::stri_trans_general("latin-ascii") %>% 
  str_replace_all("\\(", "") %>%  
  str_replace_all("\\)", "") %>% 
  str_replace_all("\\-", "") %>% 
  str_replace_all("\\'", "?")->  cldf_dialects_enriched$Name_stripped

cldf_dialects_enriched$Name_stripped %>% 
  str_replace_all(" ", "_")  ->  cldf_dialects_enriched$Name_stripped_no_spaces

#adding in col for marking contact languages
Contact_languages <- read_tsv("Contact_lgs.tsv") %>% 
  mutate(Contact_language = "Yes")

cldf_with_contact_lgs_marked <- cldf_dialects_enriched %>% 
  left_join(Contact_languages) 

##writing it out!!

df_for_writing <- cldf_with_contact_lgs_marked %>% 
  dplyr::select(Glottocode, Name, level, Family_name, Macroarea, AUTOTYP_area, category, ISO639P3code, Countries, Longitude, Latitude, med, aes, Family_ID_isolates_distinct, Isolate, Language_level_ID, Name_stripped, Name_stripped_no_spaces, classification, subclassification)

df_for_writing %>% 
  write_tsv("Glottolog_lookup_table_Hedvig_output/Heti_Glottolog_lookup_table_cldf_version.tsv")

