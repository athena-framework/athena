# Closes the request with the given *status_code* and *body*.
macro halt(ctx, status_code = 200, body = "")
  {{ctx}}.response.status_code = {{status_code}}
  {{ctx}}.response.print {{body}}
  {{ctx}}.response.headers.add "Content-Type", "application/json"
  {{ctx}}.response.close
  call_next ctx
  return
end

# Dummy function to get `Top Level Namespace` to render.
#
# TODO: Remove once [this issue](https://github.com/crystal-lang/crystal/issues/6637) is resolved.
def foo; end
