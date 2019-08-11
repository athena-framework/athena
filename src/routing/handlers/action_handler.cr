module Athena::Routing::Handlers
  # Executes the controller action for the given route.
  class ActionHandler
    include HTTP::Handler

    def call(ctx : HTTP::Server::Context) : Nil
      call_next ctx; return if ctx.request.method == "OPTIONS"

      action = Athena::DI.get_container.get("request_stack").as(RequestStack).action
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
        ctx.response.print action.renderer.new.render response, action.groups
      end

      call_next ctx
    rescue ex
      location = "unknown"

      # Try to parse the location of the exception from the backtrace.
      if trace = ex.backtrace.find { |t| t.includes? action.not_nil!.method }
        if match = trace.match(/(.*) in/)
          location = match[1]
        end
      end

      action.not_nil!.controller.handle_exception ex, ctx, location
    end
  end
end
