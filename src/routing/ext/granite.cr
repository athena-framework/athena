module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T, P)
    # Special override for Granite ORM to check for existence of a record, and set the deserialized model as not a new record.  Will also handle non Granite classes.
    #
    # Will check the given record exists on PUT, returning a 404 error if it does not exist, or primary_key is not provided.
    def self.convert(ctx : HTTP::Server::Context, body : String) : T
      model = previous_def

      {% if T <= Granite::Base %}
        if "PUT" == ctx.request.method
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
    def self.convert(ctx : HTTP::Server::Context, id : String) : T
      model = T.find Athena::Types.convert_type id, P
      raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found." if model.nil?
      model.new_record = false
      model
    end
  end
end
