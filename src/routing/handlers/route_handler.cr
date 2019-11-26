# # :nodoc:
# module HTTP::Handler
#   # :nodoc:
#   def call_next(ctx : HTTP::Server::Context) : Nil
#     if next_handler = @next
#       next_handler.call ctx
#     end
#   end
# end

# module Athena::Routing::Handlers
#   # Initializes the application's routes and kicks off the application's handlers.
#   class RouteHandler
#     include HTTP::Handler

#     # Entry-point of a request.
#     def call(ctx : HTTP::Server::Context)
#       method = ctx.request.method
#       search_key = '/' + method + ctx.request.path
#       route = @routes.find search_key

#       # Make sure there is an action to handle the incoming request
#       action = route.found? ? route.payload.not_nil! : raise Athena::Routing::Exceptions::NotFoundException.new "No route found for '#{ctx.request.method} #{ctx.request.path}'"

#       # DI isn't initialized until this point, so get the request_stack directly from the container after setting the container
#       request_stack = Athena::DI.container.request_stack

#       # Push the new request and action into the stack
#       request_stack.requests << ctx
#       request_stack.actions << action

#       # Handle the request
#       call_next ctx

#       # Pop the request and action from the stack since it is finished
#       request_stack.requests.pop
#       request_stack.actions.pop
#     end
#   end
# end
