# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::CookieValueEquals < Athena::Framework::Spec::Expectations::Response::Base
  @name : String
  @value : String
  @path : String?
  @domain : String?

  def initialize(
    @name : String,
    @value : String,
    @path : String? = nil,
    @domain : String? = nil,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    return false unless (cookie = actual_value.cookies[@name]?)

    @path == cookie.path && @domain == cookie.domain && @value == cookie.value
  end

  private def failure_message : String
    String.build do |io|
      io << "has cookie '#{@name}'"

      io << " with path '#{@path}'" unless @path.nil?
      io << " for domain '#{@domain}'" unless @domain.nil?
      io << " with value '#{@value}'"
    end
  end

  private def negated_failure_message : String
    String.build do |io|
      io << "does not have cookie '#{@name}'"

      io << " with path '#{@path}'" unless @path.nil?
      io << " for domain '#{@domain}'" unless @domain.nil?
      io << " with value '#{@value}'"
    end
  end

  private def include_response? : Bool
    false
  end
end
