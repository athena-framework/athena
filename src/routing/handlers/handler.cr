# :nodoc:
module HTTP::Handler
  # :nodoc:
  def call_next(ctx : HTTP::Server::Context, action : Athena::Routing::Action, config : Athena::Config::Config) : Nil
    if next_handler = @next
      if next_handler.responds_to? :handle
        next_handler.handle ctx, action, config
      end
    end
  end
end

# Handlers that will be executed within each request's life-cycle.
module Athena::Routing::Handlers
  abstract class Handler
    include HTTP::Handler

    # :nodoc:
    def call(ctx : HTTP::Server::Context); end

    # Method that gets executed to handle some logic.
    abstract def handle(ctx : HTTP::Server::Context, action : Action, config : Athena::Config::Config) : Nil

    # Runs the next handler.
    macro handle_next
      call_next ctx, action, config
    end
  end
end
