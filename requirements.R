# Please run this script first to make sure you have all the necessary packages 
# installed for running the rest of the scripts in this R project

if (!suppressPackageStartupMessages(require("pacman"))) { install.packages("pacman") }

pacman::p_load(
  fields, 
  tidyverse,
  jsonlite,
  reshape2,
  stringr,
  #making maps
  mapdata,
  maptools,
  randomcoloR,
  maps)

