module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T, P)
    # :nodoc:
    include Athena::DI::Injectable

    # :nodoc:
    def initialize(@request_stack : Athena::Routing::RequestStack); end

    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    #
    # NOTE: Requires `T` to include `CrSerializer` or implements a `self.from_json(body : String) : self` method to instantiate the object from the request body.
    def convert(body : String) : T
      model = previous_def

      {% if T <= Granite::Base %}
        if "PUT" == @request_stack.request.method
          primary_key = JSON.parse(body)[T.primary_name]?
          raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found." unless primary_key
          primary_value = Athena::Types.convert_type(primary_key.to_s, T.primary_type)
          raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found." unless T.find(primary_value)
          model.id = primary_value
          model.new_record = false
        end
      {% end %}

      model
    end
  end

  # Resolves a path param into type `T`.
  struct Exists(T, P)
    # Resolves an object of `T` with an *id* of type `P`.
    # Raises a `NotFoundException` if the *find* method returns nil.
    #
    # NOTE: Requires `T` implements a `self.find(val : String) : self` method that returns the corresponding record, or nil.
    def convert(id : String) : T
      model = T.find Athena::Types.convert_type id, P
      raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found." if model.nil? || (model.responds_to?(:deleted_at) && !model.deleted_at.nil?)
      model.new_record = false
      model
    end
  end
end

class Athena::Routing::Controller
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context, location : String = "unknown")
    if msg = exception.message
      if parts = msg.match(/.*\#(.*) cannot be nil/)
        throw 400, %({"code": 400, "message": "'#{parts[1]}' cannot be null"})
      end
    end

    previous_def
  end
end
