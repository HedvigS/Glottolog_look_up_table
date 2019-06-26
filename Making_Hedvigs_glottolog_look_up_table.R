source("requirements.R")

options(stringsAsFactors = FALSE)

#If you're on a machine that has rendered a version of treedb from the Glottolog repos, then you can read in the newest version from there and place it here. If you're not, just read in the treedb.tsv version that is in this folder already 

#ATTN: comment this out if you're not at a machine that's rendering treed.csv and want to read in the latest version from the Glottolog repos
#read_csv("../../../../Documents/glottolog/scripts/treedb.csv") %>%
#  write_tsv("treedb.tsv")

treedb <- read_csv("treedb.csv") %>% 
  dplyr::select(glottocode = id, Macroarea =macroareas, Longitude = longitude, Latitude = latitude, Language_level_ID = dialect_language_id, Name = name, path, Family_ID = family_id, level, Parent_ID = parent_id, iso639_3, countries, endangerment_status, hid)


treedb_has_iso <- treedb %>% 
  filter(!is.na(iso639_3))
  
treedb <- treedb %>% 
  filter(is.na(iso639_3)) %>%
  mutate(iso639_3 = hid) %>% 
  full_join(treedb_has_iso) %>% 
  dplyr::select(-hid)

###  inserting the names of the language families
top_genetic <- treedb %>% 
  distinct(Family_ID) %>% 
  filter(!is.na(Family_ID)) %>% 
  mutate(top = "top")

treedb %>% 
  filter(level == "family") %>%
  select(Family_ID, Family_name = Name, Family_glottocode = glottocode) %>%
  select(Family_ID = Family_glottocode, Family_name) %>% 
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
  rownames_to_column("glottocode")

## out resulting dataframe has 3 columns, glottocode V1 which is the MED and then V2 is a list of all more refs for that langauge, including the one that is MED. Here, we just extract the type that the MED is in V1

str_extract_all(string = Glottolog_json_MED$V1, pattern = "comparative|grammar_sketch|overview|long_grammar|wordlist|bibliographical|minimal|new_testament|specific_feature|socling|dictionary|phonology|text|dialectology|ethnographic|grammar") -> Glottolog_json_MED$MED

##str_extract_all outputs characther(0) if it doesn't find what it's looking for, here we just convert those into NAs
Glottolog_json_MED$MED <- lapply(Glottolog_json_MED$MED, function(x) if(identical(x, character(0))) NA_character_ else x)

##the previous df has the cols as lists, which screws with the writing later. Let's just make those into carachter vectors for good measure.

Glottolog_json_MED %>%
  dplyr::select(glottocode, desc_status = MED) %>%
  mutate(desc_status = as.character(desc_status)) %>%
  mutate(glottocode = as.character(glottocode)) -> Glottolog_MED

rm(Glottolog_json_MED)

#### MED business over ####

Glottolog_with_family_with_isolates %>% 
  left_join(Glottolog_MED) %>%
  distinct() -> Glottolog_with_family_with_isolates_MED

rm(Glottolog_MED, treedb, Glottolog_with_family_with_isolates)

#putting the macroarea, longitude and latitude and language family of their parents on all dialects

Glottolog_with_family_with_isolates_MED %>% 
  filter(level == "language") %>%
  select(Language_level_name = Name, Language_level_ID = glottocode, Longitude, Latitude, Macroarea, Family_name, Family_ID, countries, desc_status, Isolate, Family_name_isolates_distinct, Top_genetic_unit_ID_isolates_distinct) -> Glottolog_dialect_parents

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
  dplyr::select(Name, glottocode, iso639_3, level, endangerment_status, desc_status, Parent_ID, Language_level_name, Language_level_ID, Top_genetic_unit_ID = Family_ID, Family_name, Path = path,  Countries = countries, Longitude, Latitude, Macroarea, Isolate, Family_name_isolates_distinct, Top_genetic_unit_ID_isolates_distinct) -> Glottolog_languages_and_dialects_enriched

rm(Glottolog_dialects_enriched)

Glottolog_languages_and_dialects_enriched %>% 
  filter(level != "dialect") %>%
  dplyr::select(-Language_level_ID) %>% 
  mutate(Language_level_name = Name) %>% 
  mutate(Language_level_ID = glottocode) %>% 
  full_join(filter(Glottolog_languages_and_dialects_enriched, level == "dialect")) %>% 
  full_join(Glottolog_families) %>% 
  dplyr::select(-path, -countries, -Family_ID)-> Glottolog_language_leveled

rm(Glottolog_families, Glottolog_languages_and_dialects_enriched)

Glottolog_language_leveled$Name %>% 
  stringi::stri_trans_general("latin-ascii") %>% 
  str_replace_all("\\(", "") %>%  
  str_replace_all("\\)", "") %>% 
  str_replace_all("\\-", "") %>% 
  str_replace_all("\\'", "?")->  Glottolog_language_leveled$Name_stripped

Glottolog_language_leveled$Name_stripped %>% 
  str_replace_all(" ", "_")  ->  Glottolog_language_leveled$Name_stripped_no_spaces

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

lgs_with_unknown_area <- as.matrix(Glottolog_language_leveled[,c("Longitude","Latitude")])
rownames(lgs_with_unknown_area) <- Glottolog_language_leveled$glottocode

# For missing, find area of closest langauge
atDist <- rdist.earth(lgs_with_known_area,lgs_with_unknown_area, miles = F)

rm(lgs_with_known_area, lgs_with_unknown_area)

Glottolog_matched_up <- as.data.frame(unlist(apply(atDist, 2, function(x){names(which.min(x))})), stringsAsFactors = F) %>% 
  rename(AUTOTYP_glottocode = `unlist(apply(atDist, 2, function(x) {     names(which.min(x)) }))`)

Glottolog_language_leveled_with_autotyp_area <- Glottolog_matched_up %>% 
  rownames_to_column("glottocode") %>%
  full_join(known_areas) %>% 
  full_join(Glottolog_language_leveled) %>% 
  dplyr::select(-AUTOTYP_glottocode) %>% 
  rename(AUTOTYP_area = Area) 
  
n <- length(unique(Glottolog_language_leveled_with_autotyp_area$Family_name_isolates_distinct))

#Below are 3 different ways of finding distinctive colors for the tips. The first 2 glue a bunch of things toegher

# 
#Colouring method 1
#If you need more than 73 distinctive colours, use this chunk. It has 433.
# color_vector <- grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]
# 
# color_vector <- sample(color_vector, n)
# 
# vlabels$color_lc <- color_vector[as.factor(desc(vlabels$Family_name))]

#Colouring method 2
#If you have 74 or fewer colors you need, you could glue together all qualtiative palettes in RColorBrewer
# qual_col_pals <- brewer.pal.info[brewer.pal.info$category == 'qual',]
#  
#  col_vector <- unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
#  
#  color_vector <- sample(col_vector, n)


color_vector <- distinctColorPalette(n)


Glottolog_language_leveled_with_autotyp_area$Family_color <- color_vector[as.factor(Glottolog_language_leveled_with_autotyp_area$Family_name_isolates_distinct)]

dir.create("Glottolog_lookup_table_Hedvig_output")

write_tsv(Glottolog_language_leveled_with_autotyp_area, path = "Glottolog_lookup_table_Hedvig_output/Glottolog_lookup_table_Heti_edition.tsv")

treedb_time <- file.info("treedb.csv")$mtime

cat(paste("This file was created ", Sys.Date(), "by Hedvig Skirgård based on Glottolog and AUTOTYP data. The underlying glottolog data was rendered at", treedb_time ,". More information at https://github.com/HedvigS/Glottolog_look_up_table"), file= "Glottolog_lookup_table_Hedvig_output/Glottolog_lookup_meta.txt", sep = "\n")       

zip(zipfile = "Glottolog_lookup_table_Hedvig_output", files = "Glottolog_lookup_table_Hedvig_output")

source("Worldmap_plotting.R")
            