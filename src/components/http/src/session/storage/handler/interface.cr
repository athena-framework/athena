# Persists the data of sessions, identified by their ID.
#
# Handlers only store the data; `AHTTP::Session::Storage` manages the session's lifecycle.
module Athena::HTTP::Session::Storage::Handler::Interface
  # Returns the data of the session with the provided *session_id*, or an empty string if it does not exist or has expired.
  abstract def read(session_id : String) : String

  # Persists the provided *data* as that of the session with the provided *session_id*.
  # Returns `true` if it was persisted, otherwise `false`.
  abstract def write(session_id : String, data : String) : Bool

  # Updates when the session with the provided *session_id* was last used, without changing its *data*.
  # Returns `true` if it was updated, otherwise `false`.
  abstract def update_timestamp(session_id : String, data : String) : Bool

  # Removes the session with the provided *session_id*.
  # Returns `true` if it no longer exists, otherwise `false`.
  abstract def destroy(session_id : String) : Bool

  # Removes the sessions that were not used in the last *max_lifetime* seconds.
  # Returns how many sessions were removed.
  abstract def gc(max_lifetime : Int32) : Int32

  # Releases any resources held for the current session.
  abstract def close : Nil
end
