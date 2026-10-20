# Stores metadata about the session itself: when it was created, last used, and the lifetime of its cookie.
#
# Its timestamps use the provided [clock](/Clock/), if the Clock component is installed, otherwise the system time.
class Athena::HTTP::Session::Storage::MetadataBag
  include Athena::HTTP::Session::BagInterface

  CREATED  = "c"
  UPDATED  = "u"
  LIFETIME = "l"

  macro finished
    {% if @top_level.has_constant?("ACLK") %}
      # :nodoc:
      alias Clock = Athena::Clock::Interface
    {% else %}
      # :nodoc:
      alias Clock = NoReturn
    {% end %}
  end

  # :inherit:
  property name : String = "__metadata"

  # :inherit:
  getter storage_key : String

  @created : Int64 = 0
  @updated : Int64 = 0
  @lifetime : Int32 = 0
  @last_used : Int64 = 0
  @clock : Athena::HTTP::Session::Storage::MetadataBag::Clock?

  # Creates a new bag, persisted under the provided *storage_key*.
  #
  # The last used timestamp is only updated once at least *update_threshold* seconds passed since it was last updated, which avoids writing the session on each request.
  # The *cookie_lifetime* is the lifetime of new sessions in seconds, `0` meaning until the browser is closed.
  def initialize(
    @storage_key : String = "_athena_meta",
    @update_threshold : Int32 = 0,
    @cookie_lifetime : Int32 = 0,
    @clock : Athena::HTTP::Session::Storage::MetadataBag::Clock? = nil,
  )
  end

  # :inherit:
  def load(pull : JSON::PullParser?) : Nil
    @created = @updated = 0_i64
    @lifetime = 0

    pull.try do |parser|
      parser.read_object do |key|
        case key
        when CREATED  then @created = parser.read_int
        when UPDATED  then @updated = parser.read_int
        when LIFETIME then @lifetime = parser.read_int.to_i32
        else               parser.skip
        end
      end
    end

    unless @created.zero?
      @last_used = @updated
      timestamp = self.now

      if timestamp - @updated >= @update_threshold
        @updated = timestamp
      end

      return
    end

    self.stamp_created
  end

  # Always returns `false`, as the metadata is persisted along with the rest of the session.
  def empty? : Bool
    false
  end

  # :inherit:
  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      builder.field CREATED, @created
      builder.field UPDATED, @updated
      builder.field LIFETIME, @lifetime
    end
  end

  # Returns the lifetime of the session's cookie in seconds, `0` meaning until the browser is closed.
  def lifetime : Int32
    @lifetime
  end

  # Returns when the session was created.
  def created : Time
    Time.unix @created
  end

  # Returns when the session was last used before the current request.
  def last_used : Time
    Time.unix @last_used
  end

  # Stamps the session as being created now, optionally with the provided *lifetime* in seconds.
  def stamp_new(lifetime : Int32? = nil) : Nil
    self.stamp_created lifetime
  end

  # Does nothing, as the metadata is managed by the session itself.
  def clear : Nil
  end

  private def stamp_created(lifetime : Int32? = nil) : Nil
    @created = @updated = @last_used = self.now
    @lifetime = lifetime || @cookie_lifetime
  end

  private def now : Int64
    if clock = @clock
      return clock.now.to_unix
    end

    Time.utc.to_unix
  end
end
