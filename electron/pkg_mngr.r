# this file is a TEMPORARY fix
# the daily changing nightmare of CRAN binaries demands that we lock to
# a specific day 
# this is a SHORT TERM fix
# # Long term, we need a DESCRIPTION file:
# options(repos = 'https://packagemanager.posit.co/cran/2024-04-24')
# 
# install.packages('remotes', lib='./library', type='source')
# 
# remotes::install_deps(
#   pkgdir = '.',
#   lib = './library',
#   dependencies = TRUE,
#   type = 'source',
#   upgrade = 'never'
#)
options(repos = 'https://packagemanager.posit.co/cran/2024-04-24')

pkgs <- c(
  # Core deps first
  'rlang', 'lifecycle', 'cli', 'withr', 'xtable',
  'sourcetools', 'later', 'promises', 'fastmap',
  'commonmark', 'base64enc', 'mime', 'jsonlite',
  'htmltools', 'httpuv', 'cachem', 'memoise',
  # Then shiny itself
  'shiny',
  
  # app dependencies for other dependencies
  'pillar','Rcpp', 'magrittr', 'bslib', 'vctrs', 'generics',
  'R6', 'sass', 'jquerylib', 'rappdirs', 'ellipsis',
  'fansi', 'utf8', 'tibble', 'tidyselect', 'pkgconfig', 
  'cpp11', 'tidyr', 'fontawesome', 'fs', 
  # Your app's deps
  'yaml', 'glue', 'purrr', 'dplyr',
)

install.packages(
  pkgs,
  lib      = './r-nhyris/library',
  dependencies = TRUE,
  type     = 'source'
)