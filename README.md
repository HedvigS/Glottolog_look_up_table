# Glottolog_look_up_table

This is a small repos with an R script that cobbles together a large tsv sheet with every languoid in Glottolog (i.e. languages, dialects and families) with various meta data. Besides the "regular" Glottolog meta data (Family, long/lat, Macroarea, Countries, etc) there are also some extra info and modifications, see lists below. 

The resulting file is basically just a restructuring of what comes out of the treedb.py script from the Glottolog recipes: https://github.com/glottolog/glottolog/blob/master/scripts/treedb.py with some added information. It's a bit like the "language.csv" file that comes with every version of Glottolog (https://glottolog.org/meta/downloads), just zhujzhed up a bit to my liking and possible to run of the exact current version of Glottolog instead of just the latest published version.

**Important**

The result from this script is a folder with two files. 
1. Glottolog_lookup_table_Heti_edition.tsv - the actual large table
2. Glottolog_lookup_meta.txt - short file with the date of when this script was run. 

The meta data file contain two dates. The first date is the time when this script was run and the sheet was generated. The second date is the time when I last updated my clone of the whole glottolog repos and was able to run the treedb.py script and generated the underlying treedb.csv sheed of basic glottolog data.
That date is the date when I did the following:

First date = date of run of my script
https://github.com/HedvigS/Glottolog_look_up_table/blob/master/Making_Hedvigs_glottolog_look_up_table.R

Second date = update of glottolog repos and run of treedb.py
glottolog repos: https://github.com/glottolog/glottolog
treedb.py at the glottolog repos: https://github.com/glottolog/glottolog/blob/master/scripts/treedb.py
(You can see my notes here for running treedb.py: https://github.com/HedvigS/Glottolog_look_up_table/blob/master/running_treedb_at_glottolog_repos.txt)

The folder is also zipped up for you for convenience. 

Watch out for the fact that the desc_status and AUTOTYP_area are both rendered from static files (see URLs below). The URL's need to change with new versions of glottolog and in case AUTOTYP restructure their repos.

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
* descriptive status (from this json: https://raw.githubusercontent.com/clld/glottolog3/master/glottolog3/static/ldstatus.json)
* AUTOTYP-area (based on this csv: https://raw.githubusercontent.com/autotyp/autotyp-data/master/data/Register.csv )
* Name_stripped (ASCII and stripped for certain interprunctiation that certain programs, for example SplitsTree, struggles with)
* Family_name
* Isolate have a family name and family ID (the name and glottocode of the language) and there is a separate column that distinguishes Isolates from non-Isolates ("Isolate")
* instead of just dialects having an ID for their parent that is a language, languages also have their own IDs as the "language_level_ID"
* all dialects inherits meta-data from their language-level parents

**todo**
* make it possible to run the python lines within R
* deal with the "non-genealogical families" like "Sign language" etc so that they are represented in a different way (alongside the old style), see outline here: https://github.com/glottolog/glottolog/issues/318#issuecomment-499368382


**How is x determined?**

I'm just reshuffling Glottolog and AUTOTYP, I'm not making decisions about languages. If you want to know how some of these things are determined, see the list below:

* what is and what is not a language: https://glottolog.org/glottolog/glottologinformation#principles
* ancestry: https://glottolog.org/glottolog/glottologinformation#classification
* long/lat: https://glottolog.org/glottolog/glottologinformation#coordinates
* endangerment & descriptive status: https://scholarspace.manoa.hawaii.edu/bitstream/10125/24792/1/hammarstrom_et_al.pdf
