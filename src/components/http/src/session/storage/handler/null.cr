# A handler that does not persist sessions, so each request starts with an empty session.
#
# Useful for applications that do not want sessions to be persisted, while still being able to use the session within a request.
class Athena::HTTP::Session::Storage::Handler::Null < Athena::HTTP::Session::Storage::Handler::AbstractHandler
  # :inherit:
  def gc(max_lifetime : Int32) : Int32
    0
  end

  protected def do_read(session_id : String) : String
    ""
  end

  protected def do_create(session_id : String, data : String) : Bool
    true
  end

  protected def do_write(session_id : String, data : String) : Bool
    true
  end

  protected def do_destroy(session_id : String) : Bool
    true
  end
end
