require "./definition"

# `Athena::Console` uses a dedicated interface for representing an input source.
# This allows it to have multiple more specialized implementations as opposed to
# being tightly coupled to `STDIN` or a raw [IO](https://crystal-lang.org/api/IO.html).
# This interface represents the methods that _must_ be implemented, however implementations can add additional functionality.
#
# All input sources follow the [docopt](http://docopt.org) standard, used by many CLI utility tools.
# Documentation on this type covers functionality/logic common to all inputs.
# See each type for more specific information.
#
# Option and argument values can be accessed via `ACON::Input::Interface#option` and `ACON::Input::Interface#argument` respectively.
# There are two overloads, the first accepting just the name of the option/argument as a `String`, returning the raw value as a `String?`,
# with arrays being represented as a comma separated list.
# The other two overloads accept a `T.class` representing the desired type the value should be parsed as.
# For example, given a command with two required and one array arguments:
#
# ```
# protected def configure : Nil
#   self
#     .argument("bool", :required)
#     .argument("int", :required)
#     .argument("floats", :is_array)
# end
# ```
#
# Assuming the invocation is  `./console test false 10 3.14 172.0 123.7777`, the values could then be accessed like:
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   input.argument "bool"       # => "false" : String
#   input.argument "bool", Bool # => false : Bool
#   input.argument "int", Int8  # => 10 : Int8
#
#   input.argument "floats"                 # => "3.14,172.0,123.7777" : String
#   input.argument "floats", Array(Float64) # => [3.14, 172.0, 123.7777] : Array(Float64)
#
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# The latter syntax is preferred since it correctly types the value.
# If a provided value cannot be converted to the expected type,
# an `ACON::Exception::Logic` exception will be raised.
# E.g. `'123' is not a valid 'Bool'.`.
#
# TIP: Argument/option modes can be combined.
# E.g.`ACON::Input::Argument::Mode[:required, :is_array]` for a required array argument.
#
# There are a lot of possible combinations in regards to what options are defined versus those are provided.
# To better illustrate how these cases are handled, let's look at an example of a command with three `ACON::Input::Option`s:
#
# ```
# protected def configure : Nil
#   self
#     .option("foo", "f")
#     .option("bar", "b", :required)
#     .option("baz", "z", :optional)
# end
# ```
#
# The value of `foo` will either be `true` if provided, otherwise `false`; this is the default behavior of `ACON::Input::Option`s.
# The `bar` (`b`) option is required to have a value.
# A value can be separated from the option's long name by either a space or `=` or by its short name by an optional space.
# Finally, the `baz` (`z`) option's value is optional.
#
# This table shows how the value of each option based on the provided input:
#
# |        Input        |   foo   |    bar     |    baz     |
# | :-----------------: | :-----: | :--------: | :--------: |
# |    `--bar=Hello`    | `false` | `"Hello"`  |   `nil`    |
# |    `--bar Hello`    | `false` | `"Hello"`  |   `nil`    |
# |     `-b=Hello`      | `false` | `"=Hello"` |   `nil`    |
# |     `-b Hello`      | `false` | `"Hello"`  |   `nil`    |
# |      `-bHello`      | `false` | `"Hello"`  |   `nil`    |
# | `-fzWorld -b Hello` | `true`  | `"Hello"`  | `"World"`  |
# | `-zfWorld -b Hello` | `false` | `"Hello"`  | `"fWorld"` |
# |     `-zbWorld`      | `false` |   `nil`    | `"bWorld"` |
#
# Things get a bit trickier when an optional `ACON::Input::Argument`:
#
# ```
# protected def configure : Nil
#   self
#     .option("foo", "f")
#     .option("bar", "b", :required)
#     .option("baz", "z", :optional)
#     .argument("arg", :optional)
# end
# ```
#
# In some cases you may need to use the special `--` option in order to denote later values should be parsed as arguments, not as a value to an option:
#
# |            Input             |      bar        |   baz     |   arg     |
# | :--------------------------: | :-------------: | :-------: | :-------: |
# |        `--bar Hello`         |    `"Hello"`    |   `nil`   |   `nil`   |
# |     `--bar Hello World`      |    `"Hello"`    |   `nil`   | `"World"` |
# |    `--bar "Hello World"`     | `"Hello World"` |   `nil`   |   `nil`   |
# |  `--bar Hello --baz World`   |    `"Hello"`    | `"World"` |   `nil`   |
# | `--bar Hello --baz -- World` |    `"Hello"`    |   `nil`   | `"World"` |
# |     `-b Hello -z World`      |    `"Hello"`    | `"World"` |   `nil`   |
#
# ## Argument/Option Value Completion
#
# If the [completion script](/Console#console-completion) is installed, command and option names will be auto completed by the shell.
# However, value completion may also be implemented in custom commands by providing the suggested values for a particular option/argument.
#
# ```
# @[ACONA::AsCommand("greet")]
# class GreetCommand < ACON::Command
#   protected def configure : Nil
#     # The suggested values do not need to be a static array,
#     # they could be sourced via a class/instance method, a constant, etc.
#     self
#       .argument("name", suggested_values: ["Jim", "Bob", "Sally"])
#   end
#
#   # ...
# end
# ```
#
# Additionally, a block version of `ACON::Command#argument(name,mode,description,default,&)` and `ACON::Command#option(name,shortcut,value_mode,description,default,&)` may be used if more complex logic is required.
#
# ```
# @[ACONA::AsCommand("greet")]
# class GreetCommand < ACON::Command
#   protected def configure : Nil
#     self
#       .argument("name") do |input|
#         # The value the user already typed, e.g. the value the user already typed,
#         # e.g. when typing "greet Ge" before pressing Tab, this will contain "Ge".
#         current_value = input.completion_value
#
#         # Get the list of username names from somewhere (e.g. the database)
#         # you may use current_value to filter down the names
#         available_usernames = ...
#
#         # then suggested the usernames as values
#         return available_usernames
#       end
#   end
#
#   # ...
# end
# ```
#
# TIP: The shell completion script is able to handle huge amounts of suggestions and will automatically filter
# the values based on existing input from the user.
# You do not have to implement any filter logic in the command.
# `input.completion_value` can still be used to filter if it helps with performance, such as reducing amount of rows the DB returns.
module Athena::Console::Input::Interface
  # Returns the first argument from the raw un-parsed input.
  # Mainly used to get the command that should be executed.
  abstract def first_argument : String?

  # Returns `true` if the raw un-parsed input contains one of the provided *values*.
  #
  # This method is to be used to introspect the input parameters before they have been validated.
  # It must be used carefully.
  # It does not necessarily return the correct result for short options when multiple flags are combined in the same option.
  #
  # If *only_params* is `true`, only real parameters are checked. I.e. skipping those that come after the `--` option.
  abstract def has_parameter?(*values : String, only_params : Bool = false) : Bool

  # Returns the value of a raw un-parsed parameter for the provided *value*..
  #
  # This method is to be used to introspect the input parameters before they have been validated.
  # It must be used carefully.
  # It does not necessarily return the correct result for short options when multiple flags are combined in the same option.
  #
  # If *only_params* is `true`, only real parameters are checked. I.e. skipping those that come after the `--` option.
  abstract def parameter(value : String, default : _ = false, only_params : Bool = false)

  # Binds the provided *definition* to `self`.
  # Essentially provides what should be parsed from `self`.
  abstract def bind(definition : ACON::Input::Definition) : Nil

  # Validates the input, asserting all of the required parameters are provided.
  # Raises `ACON::Exception::Runtime` when not enough arguments are given.
  abstract def validate : Nil

  # Returns a `::Hash` representing the keys and values of the parsed arguments of `self`.
  abstract def arguments : ::Hash

  # Returns the raw string value of the argument with the provided *name*, or `nil` if is optional and was not provided.
  abstract def argument(name : String) : String?

  # Returns the value of the argument with the provided *name* converted to the desired *type*.
  # This method is preferred over `#argument` since it provides better typing.
  #
  # Raises an `ACON::Exception::Logic` if the actual argument value could not be converted to a *type*.
  abstract def argument(name : String, type : T.class) forall T

  # Sets the *value* of the argument with the provided *name*.
  abstract def set_argument(name : String, value : _) : Nil

  # Returns `true` if `self` has an argument with the provided *name*, otherwise `false`.
  abstract def has_argument?(name : String) : Bool

  # Returns a `::Hash` representing the keys and values of the parsed options of `self`.
  abstract def options : ::Hash

  # Returns the raw string value of the option with the provided *name*, or `nil` if is optional and was not provided.
  abstract def option(name : String) : String?

  # Returns the value of the option with the provided *name* converted to the desired *type*.
  # This method is preferred over `#option` since it provides better typing.
  #
  # Raises an `ACON::Exception::Logic` if the actual option value could not be converted to a *type*.
  abstract def option(name : String, type : T.class) forall T

  # Sets the *value* of the option with the provided *name*.
  abstract def set_option(name : String, value : _) : Nil

  # Returns `true` if `self` has an option with the provided *name*, otherwise `false`.
  abstract def has_option?(name : String) : Bool

  # Returns `true` if `self` represents an interactive input, such as a TTY.
  abstract def interactive? : Bool

  # Sets if `self` is `#interactive?`.
  abstract def interactive=(interactive : Bool)

  # Returns a string representation of the args passed to the command.
  abstract def to_s(io : IO) : Nil
end
