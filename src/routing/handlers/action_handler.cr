module Athena::Routing::Handlers
  # Executes the controller action for the given route.
  class ActionHandler < Athena::Routing::Handlers::Handler
    def handle(ctx : HTTP::Server::Context, action : Action?, config : Athena::Config::Config) : Nil
      handle_next; return if ctx.request.method == "OPTIONS"
      raise Athena::Routing::Exceptions::NotFoundException.new "No route found for '#{ctx.request.method} #{ctx.request.path}'" if action.nil?

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
      action.callbacks.run_on_request_callbacks ctx, action

      # Call the action.
      response = action.action.call ctx, params

      # Run the `OnResponse` callbacks.
      action.callbacks.run_on_response_callbacks ctx, action

      # Render the response.
      ctx.response.print action.renderer.render response, ctx, action.groups
    rescue ex
      action.controller.handle_exception ex, action.method
    end
  end
end
