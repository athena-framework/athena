module Athena::Routing::Parameters
  struct BodyParameter(T) < Parameter(T)
    # Validates the request body.
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
            raise Athena::Routing::Exceptions::UnsupportedMediaTypeException.new "Invalid Content-Type: '#{content_type.downcase}'"
          end
        end
      else
        # Return a 400 if body was required and not supplied.
        raise Athena::Routing::Exceptions::BadRequestException.new "Request body was not supplied." if required?
      end
    end
  end
end
