# :nodoc:
private macro halt(response, status_code, body)
  {{response}}.status_code = {{status_code}}
  {{response}}.print {{body}}
  {{response}}.headers.add "Content-Type", "application/json; charset=utf-8"
  {{response}}.close
  return
end

# :nodoc:
macro throw(status_code = 200, body = "")
  response = get_response
  response.status_code = {{status_code}}
  response.print {{body}}
  response.headers.add "Content-Type", "application/json"
  response.close
  return
end

module Athena::Routing::Handlers
  # Executes the controller action for the given route.
  class ActionHandler < Athena::Routing::Handlers::Handler
    def handle(ctx : HTTP::Server::Context, action : Action?, config : Athena::Config::Config) : Nil
      handle_next; return if ctx.request.method == "OPTIONS"
      halt ctx.response, 404, %({"code": 404, "message": "No route found for '#{ctx.request.method} #{ctx.request.path}'"}) if action.nil?

      # Set the current request/response on the controller
      # since it can now be assured an action was found.
      action.controller.request = ctx.request
      action.controller.response = ctx.response

      params = Hash(String, String?).new

      split_path = ctx.request.path.split('/')
      action.params.each do |param|
        params[param.name] = case param
                             when PathParam  then split_path[param.segment_index]
                             when QueryParam then process_query_param ctx, param
                             when BodyParam  then process_body_param ctx, param
                             end
      end

      action.as(RouteAction).callbacks.on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end

      response = action.as(RouteAction).action.call ctx, params

      action.as(RouteAction).callbacks.on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end

      ctx.response.print action.as(RouteAction).renderer.render response, ctx, action.groups
    rescue ex
      pp ex
      if a = action
        a.not_nil!.controller.handle_exception ex, a.method
      end
    end

    private def process_query_param(ctx : HTTP::Server::Context, param : Athena::Routing::QueryParam) : String?
      # If the query param was defined.
      if val = ctx.request.query_params[param.name]?
        # If the param has a pattern.
        if pat = param.pattern
          # Return the value if the pattern matches.
          if val =~ pat
            val
          else
            # Return a 400 if the query param was required and does not match the pattern.
            halt ctx.response, 400, %({"code": 400, "message": "Expected query param '#{param.name}' to match '#{pat}' but got '#{val}'"}) unless param.type.nilable?
          end
        else
          # Just return the value if there is no pattern set.
          val
        end
      else
        # Return a 400 if the query param was required and not supplied.
        halt ctx.response, 400, %({"code": 400, "message": "Required query param '#{param.name}' was not supplied."}) unless param.type.nilable?
      end
    end

    private def process_body_param(ctx : HTTP::Server::Context, param : Athena::Routing::BodyParam) : String?
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
        halt ctx.response, 400, %({"code": 400, "message": "Request body was not supplied."}) unless param.type.nilable?
      end
    end
  end
end
