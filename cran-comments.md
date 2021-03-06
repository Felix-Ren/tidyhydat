tidyhydat 0.3.5
=========================
### IMPROVEMENTS
* New function: `realtime_add_local_datetime()` adds a local datetime column to `realtime_dd()` tibble (#64)
* New function: `pull_station_number()` wraps `pull(STATION_NUMBER)` for convenience

### MINOR BREAKING CHANGES
* In effort to standardize, the case of column names for some rarely used function outputs were changed to reflect more commonly used function outputs. This may impact some workflows where columns are referenced by names (#99).   

### BUG FIXES
* Functions that have a `start_date` and `end_date` actually work with said argument (#98)
* `hy_annual_instant_peaks()` now parses the date correctly into UTC and includes a datetime and time zone column.  (#64)
* `hy_stn_data_range()` now returns actual `NA`'s rather than string NA's (#97)

### MINOR IMPROVEMENT
* `download_hydat()` now returns an informative error if the download fails due to proxy-related connection issues (@rywhale, #101). 

## Test environments
* win-builder (via `devtools::build_win()`)
* local Windows 10, R 3.4.3 (via R CMD check --as-cran)
* ubuntu, R 3.4.3 (travis-ci) (release)
* Debian Linux, R-release, GCC (debian-gcc-release) - r-hub
* Windows Server 2008 R2 SP1, R-devel, 32/64 bit - r-hub
* macOS 10.11 El Capitan, R-release (experimental) - r-hub
* macOS 10.9 Mavericks, R-oldrel (experimental) (macos-mavericks-oldrel) - r-hub
 
## R CMD check results

* No warnings
* No notes
* No errors



## Downstream dependencies

There are currently no downstream dependencies.
