# :nodoc:
struct Athena::Framework::Spec::Expectations::Request::SessionHasFlashMessage
  @type : String
  @messages : Array(String)?
  @description : String?

  def initialize(
    @type : String,
    @messages : Array(String)? = nil,
    @description : String? = nil,
  ); end

  def match(actual_value : AHTTP::Request) : Bool
    return false unless actual_value.has_session?

    flashes = actual_value.session.flash_bag.peek @type

    if messages = @messages
      flashes.any? &.in?(messages)
    else
      !flashes.empty?
    end
  end

  def match(actual_value : _) : Bool
    false
  end

  def failure_message(actual_value : AHTTP::Request) : String
    String.build do |io|
      if desc = @description
        io << desc << '\n' << '\n'
      end

      io << "Failed asserting that the session has flash message of type '#{@type}'"

      if messages = @messages
        io << " containing: " << messages.join(", ")
      end

      io << ", because the request does not have a session" unless actual_value.has_session?
      io << '.'
    end
  end
end
