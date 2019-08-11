require "./converter"

module Athena::Routing::Converters
  # Resolves a path param into type `T`.
  struct Exists(T, P) < Converter(T, P)
    # Resolves an object of `T` with an *id* of type `P`.
    # Raises a `NotFoundException` if the *find* method returns nil.
    #
    # NOTE: Requires `T` implements a `self.find(val : String) : self` method that returns the corresponding record, or nil.
    def convert(id : String) : T
      T.find(Athena::Types.convert_type(id, P)) || raise Athena::Routing::Exceptions::NotFoundException.new "An item with the provided ID could not be found."
    end
  end
end
