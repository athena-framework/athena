module Athena::Routing::Converters
  # Resolves form data into type `T`.
  struct FormData(T, P) < Converter(T, P)
    # Deserializes the form data into an object of `T`.
    #
    # NOTE: Requires `T` implements a `self.from_form_data(form_data : HTTP::Params) : self` method to instantiate the object from the form data.
    def convert(form_data : String) : T
      T.from_form_data HTTP::Params.parse form_data
    end
  end
end
