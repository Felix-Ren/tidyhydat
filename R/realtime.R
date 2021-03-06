# Copyright 2017 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.


#' Download a tibble of realtime river data from the last 30 days from the Meteorological Service of Canada datamart
#'
#' Download realtime river data from the last 30 days from the Meteorological Service of Canada (MSC) datamart. 
#' The function will prioritize downloading data collected at the highest resolution. In instances where data is 
#' not available at high (hourly or higher) resolution daily averages are used. Currently, if a station does not 
#' exist or is not found, no data is returned.
#'
#' @param station_number Water Survey of Canada station number. If this argument is omitted from the function call, the value of \code{prov_terr_state_loc}
#' is returned.
#' @param prov_terr_state_loc Province, state or territory. If this argument is omitted from the function call, the value of \code{station_number}
#' is returned.
#'
#' @return A tibble of water flow and level values. 
#' 
#' @format A tibble with 8 variables:
#' \describe{
#'   \item{STATION_NUMBER}{Unique 7 digit Water Survey of Canada station number}
#'   \item{PROV_TERR_STATE_LOC}{The province, territory or state in which the station is located}
#'   \item{Date}{Observation date and time for last thirty days. Formatted as a POSIXct class in UTC for consistency.}
#'   \item{Parameter}{Parameter being measured. Only possible values are Flow and Level}
#'   \item{Value}{Value of the measurement. If Parameter equals Flow the units are m^3/s. 
#'   If Parameter equals Level the units are metres.}
#'   \item{Grade}{reserved for future use}
#'   \item{Symbol}{reserved for future use}
#'   \item{Code}{quality assurance/quality control flag for the discharge}
#'   \item{station_tz}{Station timezone based on tidyhydat::allstations$station_tz}
#' }
#'
#' @examples
#' \dontrun{
#' ## Download from multiple provinces
#' realtime_dd(station_number=c("01CD005","08MF005"))
#'
#' # To download all stations in Prince Edward Island:
#' realtime_dd(prov_terr_state_loc = "PE")
#' }
#' 
#' @family realtime functions
#' @export
realtime_dd <- function(station_number = NULL, prov_terr_state_loc = NULL) {

  ## TODO: HAve a warning message if not internet connection exists
  if (!is.null(station_number) && station_number == "ALL") {
    stop("Deprecated behaviour.Omit the station_number = \"ALL\" argument. See ?realtime_dd for examples.")
  }
  
  ## If station number isn't and user wants the province
  if (is.null(station_number)) {
    realtime_data <- lapply(prov_terr_state_loc, all_realtime_station)
      } else{
    realtime_data <- lapply(station_number, single_realtime_station)
      }
  
  dplyr::bind_rows(realtime_data)
  

  
  



}


#' Download a tibble of active realtime stations
#'
#' An up to date dataframe of all stations in the Realtime Water Survey of Canada 
#'   hydrometric network operated by Environment and Climate Change Canada
#'
#' @param prov_terr_state_loc Province/State/Territory or Location. See examples for list of available options. 
#'   realtime_stations() for all stations.
#'
#' @family realtime functions
#' 
#' @format A tibble with 6 variables:
#' \describe{
#'   \item{STATION_NUMBER}{Unique 7 digit Water Survey of Canada station number}
#'   \item{STATION_NAME}{Official name for station identification}
#'   \item{LATITUDE}{North-South Coordinates of the gauging station in decimal degrees}
#'   \item{LONGITUDE}{East-West Coordinates of the gauging station in decimal degrees}
#'   \item{PROV_TERR_STATE_LOC}{The province, territory or state in which the station is located}
#'   \item{TIMEZONE}{Timezone of the station}
#' }
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' ## Available inputs for prov_terr_state_loc argument:
#' unique(realtime_stations()$prov_terr_state_loc)
#'
#' realtime_stations(prov_terr_state_loc = "BC")
#' realtime_stations(prov_terr_state_loc = c("QC","PE"))
#' }


realtime_stations <- function(prov_terr_state_loc = NULL) {
  prov <- prov_terr_state_loc
  
  realtime_link <- "http://dd.weather.gc.ca/hydrometric/doc/hydrometric_StationList.csv"

  url_check <- httr::GET(realtime_link,httr::user_agent("https://github.com/ropensci/tidyhydat"))
  
  ## Checking to make sure the link is valid
  if(httr::http_error(url_check) == "TRUE"){
    stop(paste0(realtime_link," is not a valid url. Datamart may be down or the url has changed."))
  }
  
  net_tibble <- httr::content(url_check,
                              type = "text/csv",
                              encoding = "UTF-8",
                              skip = 1,
                              col_names = c(
                                "STATION_NUMBER",
                                "STATION_NAME",
                                "LATITUDE",
                                "LONGITUDE",
                                "PROV_TERR_STATE_LOC",
                                "TIMEZONE"
                              ),
                              col_types = readr::cols(
                                STATION_NUMBER = readr::col_character(),
                                STATION_NAME = readr::col_character(),
                                LATITUDE = readr::col_double(),
                                LONGITUDE = readr::col_double(),
                                PROV_TERR_STATE_LOC = readr::col_character(),
                                TIMEZONE = readr::col_character()
                              )
                          )
  
  if (is.null(prov)) {
    return(net_tibble)
  }
  

  net_tibble <- dplyr::filter(net_tibble, .data$PROV_TERR_STATE_LOC %in% prov)
  net_tibble
}

#' Add local datetime column to realtime tibble
#' 
#' Adds \code{local_datetime} and \code{tz_used} columns based on either the first timezone specified into the tibble or
#' a user supplied timezone. This function is meant to used in a pipe with the \code{realtime_dd()} function. 
#' 
#' @param .data Tibble created by \code{realtime_dd}
#' @param set_tz A timezone string in the format of \code{OlsonNames()}
#' 
#' @details Date from realtime_dd is supplied in UTC which is the easiest format to work with across timezones. 
#' \code{realtime_add_local_datetime} adjusts local_datetime to a common timezone. This is most useful when all stations exist
#' within the same timezone though it is possible.
#' 
#' @examples
#' \dontrun{
#'
#' realtime_dd(c("08MF005","02LA004")) %>%
#'  realtime_add_local_datetime()
#' }
#' 
#' @export
realtime_add_local_datetime <- function(.data, set_tz = NULL){
  
  timezone_data <- dplyr::left_join(.data, tidyhydat::allstations[,c("STATION_NUMBER", "station_tz")], by = c("STATION_NUMBER"))
  
  tz_used <- timezone_data$station_tz[1]
  
  if(dplyr::n_distinct(timezone_data$station_tz) > 1) {
    warning(paste0("Multiple timezones detected. All times in local_time have been adjusted to ", tz_used), call. = FALSE)
  }
  
  if(!is.null(set_tz)) {
    message(paste0("Using ", set_tz," timezones"))
    tz_used <- set_tz 
  }
  
  timezone_data$local_datetime <- lubridate::with_tz(timezone_data$Date, tz = tz_used)
  
  timezone_data$tz_used <- tz_used
  
  dplyr::select(timezone_data, .data$STATION_NUMBER, .data$PROV_TERR_STATE_LOC, .data$Date, 
                .data$station_tz, .data$local_datetime, .data$tz_used, dplyr::everything())
}


#' Calculate daily means from higher resolution realtime data
#' 
#' This function is meant to be used within a pipe as a means of easily moving from higher resolution 
#' data to daily means.
#' 
#' @param .data A data argument that is designed to take only the output of realtime_dd
#' @param na.rm a logical value indicating whether NA values should be stripped before the computation proceeds.
#' 
#' @examples
#' \dontrun{
#' realtime_dd("08MF005") %>% realtime_daily_mean()
#' }
#' 
#' @export
realtime_daily_mean <- function(.data, na.rm = FALSE){
  
  df_mean <- dplyr::mutate(.data, Date = as.Date(.data$Date))
  
  df_mean <- dplyr::group_by(df_mean, .data$STATION_NUMBER, .data$PROV_TERR_STATE_LOC, .data$Date, .data$Parameter)
  
  df_mean <- dplyr::summarise(df_mean, Value = mean(.data$Value, na.rm = na.rm))
  
  df_mean <- dplyr::arrange(df_mean, .data$Parameter)
  
  dplyr::ungroup(df_mean)
}
