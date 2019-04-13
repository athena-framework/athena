require "./handler"

module Athena::Routing::Handlers
  # Handles CORS for the given action.
  class CorsHandler < Athena::Routing::Handlers::Handler
    # ameba:disable Metrics/CyclomaticComplexity
    def handle(ctx : HTTP::Server::Context, action : Action, config : Athena::Config::Config)
      # Run the next handler and return if CORS is globally not enabled, not enabled for a specific controller/action, or strategy is whitelist and cors_group is nil.
      if !config.routing.cors.enabled || action.route.cors_group == false || (config.routing.cors.strategy == "whitelist" && action.route.cors_group.nil?)
        handle_next; return
      end

      cors_options : Athena::Config::CorsOptions = action.route.cors_group.nil? ? config.routing.cors.defaults : config.routing.cors.groups[action.route.cors_group]

      ctx.response.headers["Access-Control-Allow-Origin"] = cors_options.allow_origin

      # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin#CORS_and_caching
      if cors_options.allow_origin != '*'
        ctx.response.headers["Vary"] = "Origin"
      end

      ctx.response.headers["Access-Control-Allow-Credentials"] = "true" if cors_options.allow_credentials
      ctx.response.headers["Access-Control-Expose-Headers"] = cors_options.expose_headers.join(',') unless cors_options.expose_headers.empty?

      # Skip the preflight processing if request is not a preflight
      return unless ctx.request.method == "OPTIONS"

      if requested_method = ctx.request.headers["Access-Control-Request-Method"]?
        if cors_options.allow_methods.map(&.downcase).includes?(requested_method.downcase)
          ctx.response.headers["Access-Control-Allow-Methods"] = cors_options.allow_methods.join(',')
        else
          raise Athena::Routing::Exceptions::MethodNotAllowedException.new "Request method '#{requested_method}' is not allowed."
        end
      end

      if requested_headers = ctx.request.headers["Access-Control-Request-Headers"]?
        requested_headers.split(',').each do |requested_header|
          unless cors_options.allow_headers.map(&.downcase).includes?(requested_header.downcase)
            raise Athena::Routing::Exceptions::ForbiddenException.new "Request header '#{requested_header}' is not allowed."
          end
        end
        ctx.response.headers["Access-Control-Allow-Headers"] = cors_options.allow_headers.join(',')
      else
        raise Athena::Routing::Exceptions::ForbiddenException.new "Preflight request header 'Access-Control-Request-Headers' is missing."
      end

      ctx.response.headers["Access-Control-Max-Age"] = cors_options.max_age.to_s if cors_options.max_age > 0
    rescue ex
      action.controller.handle_exception ex, ctx
    end
  end
end
