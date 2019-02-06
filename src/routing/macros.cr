# Closes the request with the given *status_code* and *body*.
macro halt(ctx, status_code = 200, body = "")
  {{ctx}}.response.status_code = {{status_code}}
  {{ctx}}.response.print {{body}}
  {{ctx}}.response.headers.add "Content-Type", "application/json"
  {{ctx}}.response.close
  call_next ctx
  return
end
