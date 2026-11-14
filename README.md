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

## Background
In IntELiMon, managers collect Terrestrial Laser Scans (TLS) at monitoring plots, which record the 
three-dimensional structure of vegetation and fuel. These TLS scans are then submitted to a national dataset 
at USGS EROS where the complex structural data is summarized as standard forestry, fuels, and ecology metrics 
along with custom models developed and calibrated for individual sites. This tool retrieves those results for 
the plots you choose, groups scans into time steps around the treatment dates you enter, and shows how the 
vegetation and fuels structure has changed.

Project website: https://intelimon.xyz

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
  * renv
  * The key to decrypt the IntELiMon API address (see below)

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

#### Decrypting the API
The API address used to download the publicly available data has its url stored in an encrypted form. The app 
tries to decrypt the url using the variable `API_PATH_KEY`. The decryption key can be saved to this variable 
name in a `.env` file stored in the project root or by setting the environment variable:

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
into the tool for analysis.

If running from source, by default the app runs as if it is hosted on a web sever and no tab for loading local 
data appears. To unhide this tab when running from source on your local machine, first set an environment 
variable *as if* the app had been compiled, then initiate the app:

```r
Sys.setenv("APP_ENV" = "electron")
rhino::app()
```

> [!NOTE]
> An Electron (Node.JS) wrapper is used to compile the app.

#### Adding local/private data
When the user selects a directory using the `Load IntELiMon metrics` button, the app will search for any valid 
filename that uses IntELiMon naming conventions in that directory or its sub-directories. These filenames are 
added to the list of publicly available TLS scans with the agency name `MyPC`. If filenames do not match the 
conventions for IntELiMon files, they will not be added. To load some or all of these scans for analysis, go 
to the `Selection Map` tab, and select the agency `MyPC`. Then look at the `Table` view and select the desired 
scans. There is not yet a mechanism to assign point locations to these plots, but this feature is in 
development. The app can load scans from multiple directories, but will not load scans with the same names. 
