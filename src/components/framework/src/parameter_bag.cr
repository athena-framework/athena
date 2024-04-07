# A container for storing key/value pairs. Can be used to store arbitrary data within the context of a request.
# It can be accessed via `ATH::Request#attributes`.
#
# ### Example
#
# For example, an artbirary value can be stored in the attributes, and later provided as an action argument.
#
# ```
# require "athena"
#
# # Define a request listener to add our value before the action is executed.
# @[ADI::Register]
# struct TestListener
#   @[AEDA::AsEventListener]
#   def on_request(event : ATH::Events::Request) : Nil
#     # Store our value within the request's attributes, restricted to a `String`.
#     event.request.attributes.set "my_arg", "foo", String
#   end
# end
#
# class ExampleController < ATH::Controller
#   # Define an action parameter with the same name of the parameter stored in attributes.
#   #
#   # The argument to pass is resolved via `ATHR::RequestAttribute`.
#   get "/", my_arg : String do
#     my_arg
#   end
# end
#
# ATH.run
#
# # GET / # => "foo"
# ```
struct Athena::Framework::ParameterBag
  private abstract struct Param
    abstract def value
  end

  private record Parameter(T) < Param, value : T

  @parameters : Hash(String, Param) = Hash(String, Param).new

  # Returns `true` if a parameter with the provided *name* exists, otherwise `false`.
  def has?(name : String) : Bool
    @parameters.has_key? name
  end

  # Returns `true` if a parameter with the provided *name* exists and is of the provided *type*, otherwise `false`.
  def has?(name : String, type : T.class) : Bool forall T
    self.has?(name) && @parameters[name].value.class == T
  end

  # Returns the value of the parameter with the provided *name* if it exists, otherwise `nil`.
  def get?(name : String)
    @parameters[name]?.try &.value
  end

  # Returns the value of the parameter with the provided *name* casted to the provided *type* if it exists, otherwise `nil`.
  def get?(name : String, type : T?.class) : T? forall T
    self.get?(name).as? T?
  end

  # Returns the value of the parameter with the provided *name*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String)
    @parameters.fetch(name) { raise KeyError.new "No parameter exists with the name '#{name}'." }.value
  end

  # Returns the value of the parameter with the provided *name*, casted to the provided *type*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String, type : T.class) : T forall T
    self.get(name).as T
  end

  {% for type in [Bool, String] + Number::Primitive.union_types %}
    # Returns the value of the parameter with the provided *name* as a `{{type}}`.
    def get(name : String, _type : {{type}}.class) : {{type}}
      {{type}}.from_parameter(self.get(name)).as {{type}}
    end

    # Returns the value of the parameter with the provided *name* as a `{{type}}`, or `nil` if it does not exist.
    def get?(name : String, _type : {{type}}?.class) : {{type}}?
      return nil unless (value = self.get? name)
      {{type}}.from_parameter?(value).as? {{type}}?
    end
  {% end %}

  def set(hash : Hash) : Nil
    hash.each do |key, value|
      self.set key, value
    end
  end

  # Sets a parameter with the provided *name* to *value*.
  def set(name : String, value : T) : Nil forall T
    self.set name, value, T
  end

  # Sets a parameter with the provided *name* to *value*, restricted to the given *type*.
  def set(name : String, value : T, type : T.class) : Nil forall T
    @parameters[name] = Parameter(T).new value
  end

  # Removes the parameter with the provided *name*.
  def remove(name : String) : Nil
    @parameters.delete name
  end
end
