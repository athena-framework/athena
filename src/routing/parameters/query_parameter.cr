module Athena::Routing::Parameters
  struct QueryParameter(T) < Parameter(T)
    getter pattern : Regex?

    def initialize(name : String, @pattern : Regex? = nil)
      super name
    end

    def process(ctx : HTTP::Server::Context) : String?
      # If the query param was defined.
      if val = ctx.request.query_params[@name]?
        # If the param has a pattern.
        if pat = @pattern
          # Return the value if the pattern matches.
          if val =~ pat
            val
          else
            # Return a 400 if the query param was required and does not match the pattern.
            raise Athena::Routing::Exceptions::BadRequestException.new "Expected query param '#{@name}' to match '#{pat}' but got '#{val}'" if required?
          end
        else
          # Just return the value if there is no pattern set.
          val
        end
      else
        # Return a 400 if the query param was required and not supplied.
        raise Athena::Routing::Exceptions::BadRequestException.new "Required query param '#{@name}' was not supplied." if required?
      end
    end
  end
end
