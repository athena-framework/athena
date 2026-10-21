# :nodoc:
struct Athena::Framework::Spec::Expectations::Browser::HasCookie < Athena::Framework::Spec::Expectations::Browser::Base
  @name : String
  @path : String
  @domain : String?

  def initialize(
    @name : String,
    @path : String = "/",
    @domain : String? = nil,
    description : String? = nil,
  )
    super description
  end

  def match(actual_value : ATH::Spec::AbstractBrowser) : Bool
    !actual_value.cookie_jar.get(@name, @path, @domain).nil?
  end

  private def failure_message : String
    String.build do |io|
      io << "has cookie '#{@name}'"

      io << " with path '#{@path}'" unless "/" == @path
      io << " for domain '#{@domain}'" unless @domain.nil?
    end
  end

  private def negated_failure_message : String
    String.build do |io|
      io << "does not have cookie '#{@name}'"

      io << " with path '#{@path}'" unless "/" == @path
      io << " for domain '#{@domain}'" unless @domain.nil?
    end
  end
end
