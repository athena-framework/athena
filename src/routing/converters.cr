module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T, P)
    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    #
    # NOTE: Requires `T` to include `CrSerializer` or implements a `self.from_json(body : String) : self` method to instantiate the object from the request body.
    def convert(body : String) : T
      model : T = T.from_json body
      raise CrSerializer::Exceptions::ValidationException.new model.@validator unless model.valid?
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
      T.find(Athena::Types.convert_type(id, P)) || raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found."
    end
  end

  # Resolves form data into type `T`.
  struct FormData(T, P)
    # Deserializes the form data into an object of `T`.
    #
    # NOTE: Requires `T` implements a `self.from_form_data(form_data : HTTP::Params) : self` method to instantiate the object from the form data.
    def convert(form_data : String) : T
      T.from_form_data HTTP::Params.parse form_data
    end
  end
end
