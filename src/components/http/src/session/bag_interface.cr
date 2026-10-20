# A named container of session data, persisted under its own `#storage_key` within the session.
#
# Custom bags can be registered via `AHTTP::Session#register_bag`.
module Athena::HTTP::Session::BagInterface
  # Returns the name of this bag, used to retrieve it via `AHTTP::Session#bag`.
  abstract def name : String

  # Returns the key this bag's data is persisted under within the session.
  abstract def storage_key : String

  # Loads this bag's data from the provided *pull* parser, positioned at the value persisted under `#storage_key`.
  # Resets this bag to empty if *pull* is `nil`, i.e. nothing was persisted under it.
  abstract def load(pull : JSON::PullParser?) : Nil

  # Returns `true` if this bag has no data to persist, otherwise `false`.
  abstract def empty? : Bool

  # Writes this bag's data to the provided *builder*, to be persisted under `#storage_key`.
  abstract def to_json(builder : JSON::Builder) : Nil

  # Removes all of this bag's data.
  abstract def clear : Nil
end
