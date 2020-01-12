# A param converter allows consuming a `HTTP::Request` to turn a primitive request parameter into a more complex type.
#
# A few common examples could be converting a date-time string into a `Time` object,
# converting a user's id into an actual `User` object, or deserializing a request body into an instance of T.
#
# ### Example
#
# ```
# # Create a User object.  This could be an ORM model for example.
# class User
#   include JSON::Serializable
#
#   property name : String
#   property age : Int32
#
#   def initialize(@name : String, @age : Int32); end
#
#   # Mock an ORM find method
#   def self.find(id : Int64) : self?
#     # Mock the DB query not finding anything if the id != 10
#     id == 10 ? new("Jim", 23) : nil
#   end
# end
#
# # Generics can be used to parameterize the converter, allowing the same logic to be shared, such as for different ORM models.
# struct DBConverter(T)
#   include ART::ParamConverterInterface(T)
#
#   # :inherit:
#   def convert(request : HTTP::Request) : T
#     # This assumes that a `.find` method is defined on T
#     # Exceptions should be handled here as well, such as type casting errors, or anything else that may happen.  Otherwise they would bubble up and result in a 500.
#     model = T.find request.path_params["id"].to_i64
#     raise ART::Exceptions::NotFound.new "An item with the provided ID could not be found" unless model
#     model
#   end
# end
#
# # Using generics is not required, however it is then required to explicitly set the type when including the param converter interface.
# struct DoubleConverter
#   include ART::ParamConverterInterface(Int32)
#
#   # :inherit:
#   def convert(request : HTTP::Request) : T
#     num = request.path_params["num"]
#     num.to_i * 2
#   rescue ex : ArgumentError
#     raise ART::Exceptions::BadRequest.new "Invalid Int32: '#{num}'", cause: ex
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
#   @[ART::Get("user/:id")]
#   def get_user(user : User) : User
#     user
#   end
# end
#
# ART.run
#
# CLIENT = HTTP::Client.new "localhost", 3000
#
# CLIENT.get("/double/10").body  # => 20
# CLIENT.get("/double/foo").body # => {"code":400,"message":"Invalid Int32: 'foo'"}
# CLIENT.get("/user/10").body    # => {"name":"Jim","age":23}
# CLIENT.get("/user/49").body    # => {"code":404,"message":"An item with the provided ID could not be found"}
# ```
module Athena::Routing::ParamConverterInterface(T)
  # Consumes the *request* and converts it into *T*.
  abstract def convert(request : HTTP::Request) : T
end
