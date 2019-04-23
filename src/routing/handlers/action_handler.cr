require "./handler"

module Athena::Routing::Handlers
  # Executes the controller action for the given route.
  class ActionHandler < Athena::Routing::Handlers::Handler
    def handle(ctx : HTTP::Server::Context, action : Action, config : Athena::Config::Config) : Nil
      handle_next; return if ctx.request.method == "OPTIONS"

      params = Hash(String, String?).new

      # Process action's parameters.
      if parameters = action.params
        parameters.each do |p|
          params[p.name] = p.process ctx
        end
      end

      # Run `OnRequest` callbacks.
      action.callbacks.run_on_request_callbacks ctx, action

      # Call the action.
      response = action.action.call ctx, params

      # Run the `OnResponse` callbacks.
      action.callbacks.run_on_response_callbacks ctx, action

      # If the response is a `Noop`
      if response.is_a?(Noop)
        # set the 204 no content status if the status has not been changed.
        ctx.response.status = HTTP::Status::NO_CONTENT if ctx.response.status.ok?
      else
        # otherwise render the response.
        ctx.response.print action.renderer.render response, ctx, action.groups
      end

      handle_next
    rescue ex
      action.controller.handle_exception ex, ctx
    end
  end
end
