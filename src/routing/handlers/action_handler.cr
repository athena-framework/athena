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
  class ActionHandler
    include HTTP::Handler

    def call_handler(ctx : HTTP::Server::Context, routes : Amber::Router::RouteSet(Action), config : Athena::Config::Config)
      call_next(ctx, routes, config); return if ctx.request.method == "OPTIONS"

      search_key = '/' + ctx.request.method + ctx.request.path
      route = routes.find search_key

      halt ctx.response, 404, %({"code": 404, "message": "No route found for '#{ctx.request.method} #{ctx.request.path}'"}) unless route.found?

      action = route.payload.not_nil!
      params = Hash(String, String?).new

      # Set the current request/response on the controller
      action.controller.request = ctx.request
      action.controller.response = ctx.response

      params.merge! route.params

      if ctx.request.body
        if content_type = ctx.request.headers["Content-Type"]? || "text/plain"
          body : String = ctx.request.body.not_nil!.gets_to_end
          case content_type.downcase
          when "application/json", "text/plain", "application/x-www-form-urlencoded"
            params["body"] = body
          else
            halt ctx.response, 415, %({"code": 415, "message": "Invalid Content-Type: '#{content_type.downcase}'"})
          end
        end
      else
        halt ctx.response, 400, %({"code": 400, "message": "Request body was not supplied."}) if !action.body_type.nilable? && action.body_type != Nil
      end

      if reuest_params = ctx.request.query
        query_params = HTTP::Params.parse reuest_params

        action.query_params.each do |qp|
          next if qp.name == "placeholder"
          if val = query_params[qp.as(QueryParam).name]?
            params[qp.as(QueryParam).name] = if pat = qp.as(QueryParam).pattern
                                               if val =~ pat
                                                 val
                                               else
                                                 halt ctx.response, 400, %({"code": 400, "message": "Expected query param '#{qp.as(QueryParam).name}' to match '#{pat}' but got '#{val}'"}) unless qp.as(QueryParam).type.nilable?
                                               end
                                             else
                                               val
                                             end
          else
            halt ctx.response, 400, %({"code": 400, "message": "Required query param '#{qp.as(QueryParam).name}' was not supplied."}) unless qp.as(QueryParam).type.nilable?
          end
        end
      else
        action.query_params.each do |qp|
          next if qp.name == "placeholder"
          halt ctx.response, 400, %({"code": 400, "message": "Required query param '#{qp.as(QueryParam).name}' was not supplied."}) unless qp.as(QueryParam).type.nilable?
          params[qp.as(QueryParam).name] = nil
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
      if a = action
        a.not_nil!.controller.handle_exception ex, a.method
      end
    end
  end
end
