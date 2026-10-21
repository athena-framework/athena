# :nodoc:
struct Athena::Framework::Spec::Expectations::Browser::CookieValueEquals < Athena::Framework::Spec::Expectations::Browser::Base
  @name : String
  @value : String
  @path : String
  @domain : String?

  def initialize(
    @name : String,
    @value : String,
    @path : String = "/",
    @domain : String? = nil,
    description : String? = nil,
  )
    super description
  end

  def match(actual_value : ATH::Spec::AbstractBrowser) : Bool
    return false unless cookie = actual_value.cookie_jar.get(@name, @path, @domain)

    @value == cookie.value
  end

  private def failure_message : String
    String.build do |io|
      io << "has cookie '#{@name}'"

      io << " with path '#{@path}'" unless "/" == @path
      io << " for domain '#{@domain}'" unless @domain.nil?
      io << " with value '#{@value}'"
    end
  end

  private def negated_failure_message : String
    String.build do |io|
      io << "does not have cookie '#{@name}'"

      io << " with path '#{@path}'" unless "/" == @path
      io << " for domain '#{@domain}'" unless @domain.nil?
      io << " with value '#{@value}'"
    end
  end
end
