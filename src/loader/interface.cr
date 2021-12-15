# Normally the `ACON::Application#add` method requires instances of each command to be provided.
# `ACON::Loader::Interface` provides a way to lazily instantiate only the command(s) being called,
# which can be more performant since not every command needs instantiated.
module Athena::Console::Loader::Interface
  # Returns an `ACON::Command` with the provided *name*.
  # Raises `ACON::Exceptions::CommandNotFound` if it is not defined.
  abstract def get(name : String) : ACON::Command

  # Returns `true` if `self` has a command with the provided *name*, otherwise `false`.
  abstract def has?(name : String) : Bool

  # Returns all of the command names defined within `self`.
  abstract def names : Array(String)
end
