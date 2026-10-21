# :nodoc:
abstract struct Athena::Framework::Spec::Expectations::Browser::Base
  @description : String?

  def initialize(@description : String? = nil); end

  abstract def match(actual_value : ATH::Spec::AbstractBrowser) : Bool
  abstract def failure_message : String
  abstract def negated_failure_message : String

  def match(actual_value : _) : Bool
    false
  end

  def failure_message(actual_value : ATH::Spec::AbstractBrowser) : String
    self.build_message self.failure_message
  end

  def negative_failure_message(actual_value : ATH::Spec::AbstractBrowser) : String
    self.build_message self.negated_failure_message
  end

  private def build_message(message : String) : String
    String.build do |io|
      if desc = @description
        io << desc << '\n' << '\n'
      end

      io << "Failed asserting that the browser #{message}."
    end
  end
end
