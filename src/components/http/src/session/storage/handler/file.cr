# A handler that stores each session in its own file, within the provided *save_path* directory.
#
# Sessions are only shared between processes that have access to the same directory.
# Use a handler backed by a shared data store instead when running multiple servers.
class Athena::HTTP::Session::Storage::Handler::File < Athena::HTTP::Session::Storage::Handler::AbstractHandler
  private PREFIX = "sess_"

  # Returns the directory sessions are stored in.
  getter save_path : String

  # Creates a new handler storing sessions in the provided *save_path* directory, creating it if needed.
  # Sessions expire once they were not used for *max_lifetime* seconds.
  #
  # Raises an `AHTTP::Exception::InvalidArgument` if the directory is not owned by the current user, or its group or others have permissions on it.
  # Otherwise they could read the session IDs from its file names, or add sessions of their own.
  def initialize(@save_path : String = ::File.join(Dir.tempdir, "athena_sessions"), @max_lifetime : Int32 = 1440)
    Dir.mkdir_p @save_path, 0o700

    {% unless flag? :windows %}
      # The directory may already exist, e.g. created by another user within the shared temporary directory.
      info = ::File.info @save_path

      unless info.owner_id == LibC.getuid.to_s && (info.permissions & (::File::Permissions::GroupAll | ::File::Permissions::OtherAll)).none?
        raise AHTTP::Exception::InvalidArgument.new "The session save path '#{@save_path}' must be owned by the current user, without permissions for its group and others."
      end
    {% end %}
  end

  # :inherit:
  #
  # Updates the session file's modification time, without creating it if it does not exist.
  def update_timestamp(session_id : String, data : String) : Bool
    return self.destroy session_id if data.empty?

    now = Time.utc
    ::File.utime now, now, self.path(session_id)

    true
  rescue ::File::NotFoundError
    false
  end

  # :inherit:
  def gc(max_lifetime : Int32) : Int32
    removed = 0

    Dir.each_child @save_path do |name|
      next unless name.starts_with? PREFIX

      path = ::File.join @save_path, name
      next unless (info = ::File.info?(path)) && expired?(info.modification_time, max_lifetime)

      removed += 1 if ::File.delete? path
    end

    removed
  end

  protected def do_read(session_id : String) : String
    ::File.open self.path(session_id) do |file|
      file.flock_shared do
        return "" if expired? file.info.modification_time, @max_lifetime

        file.gets_to_end
      end
    end
  rescue ::File::NotFoundError
    ""
  end

  # The data is written to a temporary file first, which is then linked into place.
  # Linking fails if the session file already exists, and the session file never contains partial data.
  protected def do_create(session_id : String, data : String) : Bool
    path = self.path session_id

    # The `.` of the suffix keeps it from ever being read as a session, as it is not allowed in session IDs.
    # The prefix lets `#gc` remove it should it be left behind.
    temporary_path = ::File.tempfile(PREFIX, ".tmp", dir: @save_path, &.print(data)).path

    ::File.link temporary_path, path

    true
  rescue ::File::AlreadyExistsError
    false
  ensure
    ::File.delete? temporary_path if temporary_path
  end

  # The `r+` mode does not create the file if it was destroyed in the meantime.
  protected def do_write(session_id : String, data : String) : Bool
    ::File.open self.path(session_id), "r+" do |file|
      file.flock_exclusive do
        file.truncate
        file.print data
        file.flush
      end
    end

    true
  rescue ::File::NotFoundError
    false
  end

  protected def do_destroy(session_id : String) : Bool
    ::File.delete? self.path(session_id)

    true
  end

  private def path(session_id : String) : String
    # Guards against path traversal, should a session ID not come from `AHTTP::Session::Storage`.
    unless session_id.matches? AHTTP::Session::Storage::VALID_ID
      raise AHTTP::Exception::InvalidArgument.new "Invalid session ID."
    end

    ::File.join @save_path, "#{PREFIX}#{session_id}"
  end

  private def expired?(modification_time : Time, max_lifetime : Int32) : Bool
    modification_time + max_lifetime.seconds < Time.utc
  end
end
