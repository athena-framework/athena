# :nodoc:
private macro halt(response, status_code, body)
  {{response}}.status_code = {{status_code}}
  {{response}}.print {{body}}
  {{response}}.headers.add "Content-Type", "application/json; charset=utf-8"
  {{response}}.close
  return
end

module Athena::Routing
  # Handles routing and param conversion on each request.
  class CorsHandler
    include HTTP::Handler

    def call_handler(ctx : HTTP::Server::Context, routes : Amber::Router::RouteSet(Action), config : Athena::Config::Config)
      call_next(ctx, routes, config); return unless config.routing.enable_cors

      cors_config : Athena::Config::CorsConfig = config.routing.cors

      ctx.response.headers["Access-Control-Allow-Origin"] = cors_config.allow_origin

      # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin#CORS_and_caching
      if cors_config.allow_origin != '*'
        ctx.response.headers["Vary"] = "Origin"
      end

      ctx.response.headers["Access-Control-Allow-Credentials"] = "true" if cors_config.allow_credentials
      ctx.response.headers["Access-Control-Expose-Headers"] = cors_config.expose_headers.join(',') unless cors_config.expose_headers.empty?

      # Skip the preflight processing if request is not a preflight
      call_next(ctx, routes, config); return unless ctx.request.method == "OPTIONS"

      if requested_method = ctx.request.headers["Access-Control-Request-Method"]?
        if cors_config.allow_methods.includes?(requested_method)
          ctx.response.headers["Access-Control-Allow-Methods"] = cors_config.allow_methods.join(',')
        else
          halt ctx.response, 405, %({"code":405,"message":"Method '#{requested_method}' is not allowed."})
        end
      else
        halt ctx.response, 403, %({"code":403,"message":"Preflight request header 'Access-Control-Request-Method' is missing."})
      end

      if requested_headers = ctx.request.headers["Access-Control-Request-Headers"]?
        requested_headers.split(',').each do |requested_header|
          unless cors_config.allow_headers.includes?(requested_header.downcase)
            halt ctx.response, 403, %({"code":403,"message":"Request header '#{requested_header}' is not allowed."})
          end
        end
        ctx.response.headers["Access-Control-Allow-Headers"] = cors_config.allow_headers.join(',')
      else
        halt ctx.response, 403, %({"code":403,"message":"Preflight request header 'Access-Control-Request-Headers' is missing."})
      end

      ctx.response.headers["Access-Control-Max-Age"] = cors_config.max_age.to_s if cors_config.max_age > 0
    end
  end
end
