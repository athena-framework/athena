# Base type of the built-in session handlers.
#
# Makes sure a session is never brought back after it was destroyed:
# the data of a session that did not exist when it was read is only ever created via `#do_create`, and the data of an existing session only ever updated via `#do_write`.
# E.g. a request still using a session that another request destroyed, such as when logging out, does not bring it back.
#
# Also removes the session when it is written with empty data, and skips removing a session that was never persisted.
#
# As it keeps track of the session it last read, an instance must not be shared between concurrent requests, e.g. by storing it in a class variable.
abstract class Athena::HTTP::Session::Storage::Handler::AbstractHandler
  include Athena::HTTP::Session::Storage::Handler::Interface

  # The ID of the session that did not exist when it was last read, as it has nothing to destroy or update yet.
  @new_session_id : String? = nil

  # Returns the data of the session with the provided *session_id*, or an empty string if it does not exist or has expired.
  protected abstract def do_read(session_id : String) : String

  # Creates the session with the provided *session_id* with the provided *data*.
  # Must not overwrite an existing session, returning `false` instead.
  protected abstract def do_create(session_id : String, data : String) : Bool

  # Replaces the data of the existing session with the provided *session_id* with the provided *data*.
  # Must not create the session if it does not exist, returning `false` instead.
  protected abstract def do_write(session_id : String, data : String) : Bool

  # Removes the session with the provided *session_id*.
  protected abstract def do_destroy(session_id : String) : Bool

  # :inherit:
  def read(session_id : String) : String
    data = self.do_read session_id
    @new_session_id = data.empty? ? session_id : nil

    data
  end

  # :inherit:
  def write(session_id : String, data : String) : Bool
    return self.destroy session_id if data.empty?

    is_new = @new_session_id == session_id
    @new_session_id = nil

    is_new ? self.do_create(session_id, data) : self.do_write(session_id, data)
  end

  # :inherit:
  def update_timestamp(session_id : String, data : String) : Bool
    return self.destroy session_id if data.empty?

    true
  end

  # :inherit:
  def destroy(session_id : String) : Bool
    @new_session_id == session_id || self.do_destroy(session_id)
  end

  # :inherit:
  def close : Nil
  end
end
