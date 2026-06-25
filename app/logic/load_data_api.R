box::use(
  httr2
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



#' Perform a REST API request.
#'
#' This function assembles the request to a specific resource and returns a response object using the httr2 library
#' @param resource_url A string to be appeneded to the api's base url, usually starting with a single /
#' @param request_body A list to be supplied as the request body. If no body is accepted by the resource,the value is NULL
#'  and no body is sent with the request
#' @param request_base_url A string containing the base url that all resources are appended to.
#' @return A httr2 response object containing the response of the api.
#' @export
api_request <- function(resource_url,
                        request_body = NULL,
                        request_base_url = api_base_url
) {
  req <- httr2$request(request_base_url) |>
    httr2$req_headers(Accept = 'application/json') |>
    httr2$req_url_path_append(resource_url) |>
    (\(req_obj){
      if (!is.null(request_body)){
        httr2$req_body_json(request_body)
      }else{
        req_obj
      }
    })()

  resp <- req |> httr2$req_perform()
  resp
}


get_api <- function(url) {}

get_status <- function() {}

is_request_successful <- function() {}

json2df <- function() {
  # use rjson$fromJSON
  # rjson vs jsonlite?
}


