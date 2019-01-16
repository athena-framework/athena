module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T)
    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    #
    # NOTE: Requires `T` to include `CrSerializer` or implements a `self.deserialize(body : String) : self` method to instantiate the object from the request body.
    def self.convert(body : String) : T
      model : T = T.deserialize body
      raise CrSerializer::Exceptions::ValidationException.new model.validator unless model.validator.valid?
      model
    end
  end

  # Resolves a path param into type `T`.
  struct Exists(T)
    # Resolves an object of `T` with an id of *id*.
    # Raises a `NotFoundException` if the *find* method returns nil.
    #
    # NOTE: Requires `T` implements a `self.find(val : String) : self` method that returns the corresponding record, or nil.
    def self.convert(id : String) : T
      model = T.find id.to_i64(strict: true)
      raise NotFoundException.new "An item with the provided ID could not be found." if model.nil?
      model
    end
  end

  # Resolves form data into type `T`.
  struct FormData(T)
    # Deserializes the form data into an object of `T`.
    #
    # NOTE: Requires `T` implements a `self.from_form_data(form_data : HTTP::Params) : self` method to instantiate the object from the form data.
    def self.convert(form_data : String) : T
      T.from_form_data HTTP::Params.parse form_data
    end
  end
end
