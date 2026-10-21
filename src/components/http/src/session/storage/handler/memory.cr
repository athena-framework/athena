# A handler that keeps sessions in memory.
#
# Sessions are lost when the process exits, and are not shared between processes.
# Mainly useful for testing.
class Athena::HTTP::Session::Storage::Handler::Memory < Athena::HTTP::Session::Storage::Handler::AbstractHandler
  private record Entry, data : String, updated_at : Time

  @sessions = Hash(String, Entry).new
  @mutex = Mutex.new

  # Creates a new handler whose sessions expire once they were not used for *max_lifetime* seconds.
  def initialize(@max_lifetime : Int32 = 1440); end

  # :inherit:
  def update_timestamp(session_id : String, data : String) : Bool
    return self.destroy session_id if data.empty?

    @mutex.synchronize do
      return false unless entry = @sessions[session_id]?

      @sessions[session_id] = entry.copy_with updated_at: Time.utc
      true
    end
  end

  # :inherit:
  def gc(max_lifetime : Int32) : Int32
    @mutex.synchronize do
      size = @sessions.size
      @sessions.reject! { |_, entry| expired? entry, max_lifetime }
      size - @sessions.size
    end
  end

  protected def do_read(session_id : String) : String
    @mutex.synchronize do
      return "" unless entry = @sessions[session_id]?
      return "" if expired? entry, @max_lifetime

      entry.data
    end
  end

  protected def do_create(session_id : String, data : String) : Bool
    @mutex.synchronize do
      return false if @sessions.has_key? session_id

      @sessions[session_id] = Entry.new data, Time.utc
      true
    end
  end

  protected def do_write(session_id : String, data : String) : Bool
    @mutex.synchronize do
      return false unless @sessions.has_key? session_id

      @sessions[session_id] = Entry.new data, Time.utc
      true
    end
  end

  protected def do_destroy(session_id : String) : Bool
    @mutex.synchronize do
      @sessions.delete session_id
      true
    end
  end

  private def expired?(entry : Entry, max_lifetime : Int32) : Bool
    entry.updated_at + max_lifetime.seconds < Time.utc
  end
end
