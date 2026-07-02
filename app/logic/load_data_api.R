box::use(
  httr2,
  dt = data.table,
)

# API server path has been encrypted
# The decryption key is stored in .env as:
# API_PATH_KEY=super_secret_32_character_key___
# the path was encrypted using:
# > readRenviron('.env')
# > httr2$secret_encrypt("https://the/intelimon/api/path/", "API_PATH_KEY")

readRenviron(".env")

api_base_url <- httr2$secret_decrypt(
  "983U5eHDRR6VR1Czn6pinkokV-PU-sbxWdkl0fmUoYklWMqTfU3oFzUhT3yQXOF8CM4sW0hFsbierKI2fbPx_P7et7k7e25Sqw",
  key = "API_PATH_KEY"
)

#--Generic API functions-------------------------------------------------------------------------

#' Perform a REST API request.
#'
#' This function assembles the request to a specific resource and returns a response object using the httr2 library
#'
#' @param resource_url A string to be appeneded to the api's base url, usually starting with a single /
#' @param request_body A list to be supplied as the request body. If no body is accepted by the resource,the value is NULL
#'  and no body is sent with the request
#' @param request_base_url A string containing the base url that all resources are appended to.
#' @return A httr2 response object containing the response of the api.
#' @export
api_request <- function(resource_url,
                        request_body = NULL,
                        request_base_url = api_base_url,
                        request_method = 'GET'
) {
  req <- httr2$request(request_base_url) |>
    httr2$req_headers(Accept = 'application/json') |>
    httr2$req_method(request_method) |>
    httr2$req_url_path_append(resource_url) |>
    (\(req_obj){
      if (!is.null(request_body)){
        httr2$req_body_json(req_obj, request_body)
      }else{
        req_obj
      }
    })()

  tryCatch(
    resp <- req |> httr2$req_perform(),
    # if the response is an error, return the error
    error = \(e) {
      resp <- httr2$last_response()
    }

  )

}

#' Check if API request was successful and return a boolean response.
#'
#' This function checks an API response to see if it returned an error. Function returns False if there is an error and
#' True if there is no error.
#'
#' @param resp an httr2 library response variable from an API request
#' @return a boolean value, True if resposne was successful, False on error.
#' @export
is_request_successful <- function(resp) {
  !httr2$resp_is_error(resp)
}

#' Convert a REST API response to a data table
#'
#' Convert an httr2 API response into a data.table. When httr2 poles an API it creates a response object with the body
#' of the response in JSON format.This function converts the json body into a data.table.
#'
#' @param httr2 API response
#' @return data.table
#' @export
resp2dt <- function(resp) {
  if (is_request_successful(resp)) {
    resp_json <- resp |> httr2$resp_body_json(check_type=TRUE)

    # if json is a list of lists
    test_sample <- resp_json[[1]]
    if (is.list(test_sample)){
      dt$rbindlist(resp_json, fill=TRUE)
    # if json is a simple list
    } else if(is.character(test_sample)|is.numeric(test_sample)){
      # may need unlist before data.table?
      dt$data.table(value = unlist(resp_json))
    }
  }
}

#--IntELiMon specific API interactions---------------------------------------------------------------------------

#' Get list of agencies that have collected IntELiMon data.
#'
#' Poll the IntELiMon API for a list of valid agencies that are tied to plot data.
#' @export
get_agencies <- function() {
  resp <- api_request('/agencies')

  resp2dt(resp)
}

#' Get list of sites available for supplied agencies.
#'
#' Take a list of agencies as an input and, for each agency, return a data table of sites collected.
#'
#' @param a list of agency strings
#' @return a data table of sites
#' @export
get_sites_from_agency <- function(agencies) {
  site_list <- list()
  i <- 1
  for (agcy in agencies) {
    # get datatable of sites for an agency
    resp <- api_request('/sites', request_body = list(agency=agcy))
    # add to list of datatables
    site_list[[i]] <- resp2dt(resp)
    i <- i + 1
  }
  # concatenate list of data tables into a single data table
  dt$rbindlist(site_list)
}

#'
#' @param xmin a floating point number
#' @export
get_sites_from_bbox <- function(x_min,
                                x_max,
                                y_min,
                                y_max,
                                site = NULL
) {

  resp <- api_request('/plots',
                       request_body = list( site=site,
                                            xmax=-x_max,
                                            ymin=y_min,
                                            xmin=x_min,
                                            ymax=y_max
                       )
  )
  resp2dt(resp)
}