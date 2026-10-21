class Athena::HTTP::Session::Storage; end

# Manages the lifecycle of an `AHTTP::Session`: loading and persisting its data and bags, as well as its ID.
module Athena::HTTP::Session::Storage::Interface
  # Starts the session, loading its data.
  # Returns `true` once the session is started.
  abstract def start : Bool

  # Returns `true` if the session is started, otherwise `false`.
  abstract def started? : Bool

  # Returns the ID of the session, or an empty string if it does not have one yet.
  abstract def id : String

  # Sets the ID of the session to load once it is started.
  abstract def id=(id : String)

  # Returns the name of the session, i.e. the name of its cookie.
  abstract def name : String

  # Sets the name of the session.
  abstract def name=(name : String)

  # Gives the session a new ID while keeping its data, optionally removing the persisted data of the current ID if *destroy* is `true`.
  # Optionally sets the *lifetime* of its cookie in seconds, `0` meaning until the browser is closed.
  #
  # Returns `true` if the session was given a new ID, otherwise `false`.
  abstract def regenerate(destroy : Bool = false, lifetime : Int32? = nil) : Bool

  # Persists the session data and closes the session.
  abstract def save : Nil

  # Clears all session data.
  abstract def clear : Nil

  # Returns the bag registered with the provided *name*, starting the session if needed.
  abstract def bag(name : String) : AHTTP::Session::BagInterface

  # Registers the provided *bag*, whose data is loaded and persisted along with the session.
  abstract def register_bag(bag : AHTTP::Session::BagInterface) : Nil

  # Returns the bag storing the session's metadata.
  abstract def metadata_bag : AHTTP::Session::Storage::MetadataBag
end
