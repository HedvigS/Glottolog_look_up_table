# installs the necessary packages for these scripts

day="2021-03-14" #the particular date which we want to re-create, we'll be loading packages as they were on this specific date on CRAN.

if (!suppressPackageStartupMessages(require('groundhog'))) { install.packages('groundhog') }
library(groundhog)

if (!dir.exists("groundhog_packages")) { dir.create("groundhog_packages") }

set.groundhog.folder("groundhog_packages") #place the date-specific packages in a folder inside this directory instead of somewhere higher up in the folder hierarchy. 

pkgs <- c(
  'fields', #for geo distance calculations
  'tidyverse', #for data wrangling
  'reshape2', #specifially for melt()
  'stringr',#for some string searching
  #making maps
  'mapdata',
  'maptools',
  'randomcoloR',
  'maps', 
  #wrangling trees
  'phytools',
  'ape',
  'beepr', 
  'jsonlite'
  )

groundhog.library(pkgs, day)