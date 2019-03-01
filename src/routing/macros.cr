# Closes the request with the given *status_code* and *body*.
macro throw(status_code = 200, body = "")
  response = get_response
  response.status_code = {{status_code}}
  response.print {{body}}
  response.headers.add "Content-Type", "application/json"
  response.close
  return
end
