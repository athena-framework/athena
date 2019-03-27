module Athena::Routing::Parameters
  struct BodyParameter(T) < Parameter(T)
    def process(ctx : HTTP::Server::Context) : String?
      # If a body is included in the request
      if ctx.request.body
        if content_type = ctx.request.headers["Content-Type"]? || "text/plain"
          body : String = ctx.request.body.not_nil!.gets_to_end
          case content_type.downcase
          when "application/json", "text/plain", "application/x-www-form-urlencoded"
            # Return the body.
            body
          else
            # Return a 415 if an unsupported content type is used.
            halt ctx.response, 415, %({"code": 415, "message": "Invalid Content-Type: '#{content_type.downcase}'"})
          end
        end
      else
        # Return a 400 if body was required and not supplied.
        halt ctx.response, 400, %({"code": 400, "message": "Request body was not supplied."}) if required?
      end
    end
  end
end
