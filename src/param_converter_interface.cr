# A param converter allows taking a request paramter and transforming it into another value/type.
#
# A few common examples could be converting a datetime string into a `Time` object,
# converting a user's id into an actual `User` object, or any other logic you wish.
#
# TODO:Have a converter directly accept the request to allow using a different argument names in the path versus the action.
#
# ### Examples
#
# ```
# # A converter can opt to not expose a generic argument, however it is then required to explicitally set the type
# # when including the param converter interface.
# struct DoubleConverter
#   include ART::ParamConverterInterface(Int32)
#
#   # :inherit:
#   def convert(value : String) : T
#     # Any possible exceptions should be handled here as well, otherwise they would
#     # bubble up and result in a 500.
#     value.to_i * 2
#   end
# end
#
# # Create a User object.  This could be an ORM model for example.
# class User
#   include JSON::Serializable
#
#   property name : String
#   property age : Int32
#
#   def initialize(@name, @age); end
#
#   # Mock an ORM find method
#   def self.find(id : Int64) : self?
#     # Mock the DB query not finding anything if the id != 10
#     id == 10 ? new("Jim", 23) : nil
#   end
# end
#
# # Converter that will attempt to resolve an instance of *T* from the database, handling the case where it does not exist.
# struct DBConverter(T)
#   include ART::ParamConverterInterface(T)
#
#   # :inherit:
#   def convert(value : String) : T
#     # This assumes that a `.find` method is defined on T
#     model = T.find value.to_i64
#     raise ART::Exceptions::NotFound.new "An item with the provided ID could not be found" unless model
#     model
#   end
# end
#
# class ParamConverterController < ART::Controller
#   @[ART::ParamConverter("num", converter: DoubleConverter)]
#   @[ART::Get(path: "/double/:num")]
#   def double(num : Int32) : Int32
#     num
#   end
#
#   @[ART::ParamConverter("user", converter: DBConverter(User))]
#   @[ART::Get("user/:user")]
#   def get_user(user : User) : User
#     user
#   end
# end
#
# ART.run
#
# CLIENT = HTTP::Client.new "localhost", 3000
#
# CLIENT.get("/double/10").body # => 20
# CLIENT.get("/user/10").body   # => {"name":"Jim","age":23}
# CLIENT.get("/user/49").body   # => {"code":404,"message":"An item with the provided ID could not be found"}
# ```
module Athena::Routing::ParamConverterInterface(T)
  # Responsible for turning the provided *value* into *T*.
  abstract def convert(value : String) : T
end
