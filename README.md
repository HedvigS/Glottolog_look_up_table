# Glottolog_look_up_table

This is a small repos with an R script that cobbles together a large tsv sheet with every languoid in Glottolog (i.e. languages, dialects and families) with various meta data. Besides the "regular" Glottolog meta data (Family, long/lat, Macroarea, Countries, etc) there are also some extra info and modifications, see lists below. 

**Basic meta-data from Glottolog**
* Longitude/Latitude
* Level (language/dialect/family)
* Macroarea (Australia, South America, North America, Eurasia, Africa, Papunesia)
* Name
* ISO 6393-3
* Glottocode
* Parent-ID 
* Top-genetic unit ID
* Path (from languoid to root of tree)
* Countries

**Added meta-data**
* AUTOTYP-area (based on this csv: https://raw.githubusercontent.com/autotyp/autotyp-data/master/data/Register.csv )
* Name_stripped (ASCII and stripped for certain interprunctiation that certain programs, for example SplitsTree, struggles with)
* Family_name
* Isolate have a family name and family ID (the name and glottocode of the language) and there is a separate column that distinguishes Isolates from non-Isolates ("Isolate")
* instead of just dialects having an ID for their parent that is a language, languages also have their own IDs as the "language_level_ID"
* all dialects inherits meta-data from their language-level parents
* Family_color is a distinctive colour in HEX code for every family, including seprate ones for each Isolate

**todo**
* make it possible to run the python lines within R
* deal with the "non-genealogical families" like "Sign language" etc so that they are represented in a different way (alongside the old style), see outline here: https://github.com/glottolog/glottolog/issues/318#issuecomment-499368382

**How is x determined?**

I'm just reshuffling Glottolog and AUTOTYP, I'm not making decisions about languages. If you want to know how some of these things are determined, see the list below:

* what is and what is not a language: https://glottolog.org/glottolog/glottologinformation#principles
* ancestry: https://glottolog.org/glottolog/glottologinformation#classification
* long/lat: https://glottolog.org/glottolog/glottologinformation#coordinates
* endangerment & descriptive status: https://scholarspace.manoa.hawaii.edu/bitstream/10125/24792/1/hammarstrom_et_al.pdf
