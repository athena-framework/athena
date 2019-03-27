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
    # ameba:disable Metrics/CyclomaticComplexity
    def handle(ctx : HTTP::Server::Context, action : Action?, config : Athena::Config::Config) : Nil
      handle_next; return if ctx.request.method == "OPTIONS"
      halt ctx.response, 404, %({"code": 404, "message": "No route found for '#{ctx.request.method} #{ctx.request.path}'"}) if action.nil?

      # Set the current request/response on the controller
      # since it can now be assured an action was found.
      action.controller.request = ctx.request
      action.controller.response = ctx.response

      params = Hash(String, String?).new

      # Process action's parameters.
      action.params.each do |param|
        params[param.name] = param.process ctx
      end

      # Run `OnRequest` callbacks.
      action.callbacks.on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end

      # Call the action.
      response = action.action.call ctx, params

      # Run the `OnResponse` callbacks.
      action.callbacks.on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end

      # Render the response.
      ctx.response.print action.renderer.render response, ctx, action.groups
    rescue ex
      if a = action
        a.not_nil!.controller.handle_exception ex, a.method
      end
    end
  end
end
