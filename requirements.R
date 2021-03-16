# installs the necessary packages for these scripts

if (!suppressPackageStartupMessages(require('groundhog'))) { install.packages('groundhog') }

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
  'beepr'
  )

day="2021-03-15"
groundhog.library(pkgs, day)