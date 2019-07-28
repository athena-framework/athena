require "./parameter"

module Athena::Routing::Parameters
  module Param; end

  abstract struct Parameter(T)
    include Param

    # The name of the parameter.
    getter name : String

    def initialize(@name : String, @type : T.class = T); end

    # Method to extract the value from server context.
    abstract def process(ctx : HTTP::Server::Context) : String?

    # If `nil` is a valid value for the parameter.
    def nilable? : Bool
      @type.nilable?
    end

    # If the parameter is required.
    def required? : Bool
      !nilable?
    end
  end
end
