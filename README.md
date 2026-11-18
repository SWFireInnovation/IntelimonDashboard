# IntELiMon Decision Support Tool
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![R](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FSWFireInnovation%2FIntelimonDashboard%2Fmain%2Frenv.lock&query=%24.R.Version&label=R&logo=r&logoColor=white&color=276DC3)
[![DOI](https://zenodo.org/badge/DOI/placeholder/zenodo.placeholder.svg)](https://doi.org/placeholder/zenodo.placeholder)

The IntELiMon Decision Support Tool is an open-source Shiny dashboard that returns results from the 
Interagency Ecosystem Lidar Monitoring Program in a format that supports planning and evaluation of treatment 
success by land managers. 

> [!WARNING]
>This is a beta release. Parts of the tool are experimental, and some features do not work yet. See Project 
>status.

## Acknowledgements
Funds supporting this work came from Bureau of Indian Affairs/US Wildland Fire Service though Interagency 
Agreement (IAA) 4500174398. 

## Background
In IntELiMon, managers collect Terrestrial Laser Scans (TLS) at monitoring plots, which record the 
three-dimensional structure of vegetation and fuel. These TLS scans are then submitted to a national dataset 
at USGS EROS where the complex structural data is summarized as standard forestry, fuels, and ecology metrics 
along with custom models developed and calibrated for individual sites. This tool retrieves those results for 
the plots you choose, groups scans into time steps around the treatment dates you enter, and shows how the 
vegetation and fuels structure has changed.

Project website: https://intelimon.xyz

## How to use it

The app is organized as a series of tabs that follow a typical workflow:

1. Select and download plots: zoom, pan, or use filters to find the plots you want, then download data for the
   selected.
1. Set treatment dates and experimental features for plot grouping
1. Look at standard outputs and custom models displaying plot averages over time 
1. Build reports by selecting tables and figures from tabs throughout your workflow
1. Other experimental features
   1. Fuels exports (experimental): surface and canopy fuel for use in modeling
   1. Forestry exports (experimental): stand metrics and thinning scenarios for single plots
   1. rothRmel (experimental): fire behavior comparisons across scans

## Running the App
### Hosted web app
[https://intelimon-dashboard.nrp-nautilus.io/](https://intelimon-dashboard.nrp-nautilus.io/)

### Compiled desktop app
This feature is still in development, but is part of near-term planning.

This is the intended way for private datasets to be viewed and analyzed in the tool.

### Running from source
This is currently the only way to view or analyze private datasets in the tool.

#### Requirements
Compiling R packages from source will be necessary for multiple packages.

* R 4.4.0 (newer version untested)
* renv
* The key to decrypt the IntELiMon API address (see below)
* Compiler for R packages
  * Windows- RTools 4.4.x
  * OSx- XTools
    * `brew` recommended for OS dependencies
      * libpng
      * cairo 
      * pkg-config
      * fribidi
      * harfbuzz
      * freetype
      * libjpeg
      * gdal
      * geos
      * proj
      * tbb
      * sqlite
      * jpeg
      * svglite
      * udunits
  * Unbuntu
    * `apt-get` recommended for OS dependencies
      * libgdal-dev
      * libgeos-dev
      * libproj-dev
      * libsqlite3-dev
      * gdal-bin
      * pandoc
      * libudunits2-dev
      * libharfbuzz-dev
      * libfribidi-dev
      * libfreetype6-dev
      * libpng-dev
      * libarchive-dev

#### Installation

1. Install all requirements
1. Clone the repository
```bash
git clone https://github.com/SWFireInnovation/IntelimonDashboard.git
```
3. Open an R consol in the `/IntelimonDashboard` directory
3. Restore the R environment (`renv`)
```r
renv::restore()
```

#### Decrypting the API url
The publicly available data is downloaded from an API. The API url is encrypted for security. The app 
expects the decryption key to be saved to the variable `API_PATH_KEY`, either in a `.env` file stored in the 
project root or by setting the environment variable:

```r
Sys.setenv('API_PATH_KEY' = '<decryption key>')
```

Contact the repository owners to get the decryption key.

#### Running
From any R console:

```r
rhino::app()
```

### Running locally (compiled or source)
On startup, the local version will always try to download a list of publicly available scans through the API. 
This assumes a working web connection.

When running the compiled version, a new tab will appear to allow the user to load data from a local machine 
into the tool for analysis. Loaded data does not leave the local machine.

If running from source, by default the app runs as if it is hosted on a web server and no tab for loading local 
data appears. To unhide this tab when running from source on your local machine, first set an environment 
variable *as if* the app had been compiled, then initiate the app:

```r
Sys.setenv("APP_ENV" = "electron")
rhino::app()
```

> [!NOTE]
> An Electron (Node.JS) wrapper is used to compile the app.

#### Adding local/private data
Processing of raw .ptx files is not yet enabled, but is part of near-term planning.

When the user selects a directory using the `Load IntELiMon metrics` button, the app will search for any csv 
with a valid 
filename that uses IntELiMon naming conventions in that directory or its sub-directories. These filenames are 
added to the list of publicly available TLS scans with the agency name `MyPC`. If filenames do not match the 
conventions for IntELiMon files, they will not be added. To load some or all of these scans for analysis, go 
to the `Selection Map` tab, and select the agency `MyPC`. Then look at the `Table` view and select the desired 
scans. There is not yet a mechanism to assign point locations to these plots, but this feature is in 
development. The app can load scans from multiple directories, but will not load scans with the same names. 

## Project structure
This app uses the [Rhino](https://appsilon.github.io/rhino/) framework and loads packages exclusively using 
[box](https://appsilon.github.io/rhino/articles/explanation/box-modules.html) to allow for a modular 
structure similar to Python or Java.

A detailed explanation of conventions used in this code is documented in `AGENTS.md`. 

File structure:
```bash
app/
  main.R          # app entry point and navbar
  logic/          # Shiny-independent code (data, statistics, reports)
  view/           # Shiny modules, prefixed by type, one per tab, widget, card, etc.
  static/help/    # Markdown help pages shown in the Help tab
electron/         # The Node.JS Electron wrapper for the desktop app
tests/            # unit tests
```

## Citing

If you use this software, please cite it using the information in CITATION.cff (GitHub's "Cite this 
repository" button). Each release is archived on Zenodo with its own DOI.

## License
[MIT License](https://github.com/SWFireInnovation/biomass/blob/main/LICENSE)