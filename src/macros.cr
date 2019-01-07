# Closes the request with the given *status_code* and *body*.
macro halt(context, status_code = 200, body = "")
  {{context}}.response.status_code = {{status_code}}
  {{context}}.response.print {{body}}
  {{context}}.response.headers.add "Content-Type", "application/json"
  {{context}}.response.close
  call_next context
  return
end

# Dummy function to get `Top Level Namespace` to render.
#
# TODO: Remove once [this issue](https://github.com/crystal-lang/crystal/issues/6637) is resolved.
def foo; end
