# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::HasCookie < Athena::Framework::Spec::Expectations::Response::Base
  @name : String
  @path : String?
  @domain : String?

  def initialize(
    @name : String,
    @path : String? = nil,
    @domain : String? = nil,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    return false unless cookie = actual_value.cookies[@name]?

    @path == cookie.path && @domain == cookie.domain
  end

  private def failure_message : String
    String.build do |io|
      io << "has cookie '#{@name}'"

      io << " with path '#{@path}'" unless @path.nil?
      io << " for domain '#{@domain}'" unless @domain.nil?
    end
  end

  private def negated_failure_message : String
    String.build do |io|
      io << "does not have cookie '#{@name}'"

      io << " with path '#{@path}'" unless @path.nil?
      io << " for domain '#{@domain}'" unless @domain.nil?
    end
  end

  private def include_response? : Bool
    false
  end
end
