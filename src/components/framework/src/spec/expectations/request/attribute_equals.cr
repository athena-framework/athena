# :nodoc:
struct Athena::Framework::Spec::Expectations::Request::AttributeEquals(T)
  @name : String
  @value : T
  @description : String?

  def initialize(
    @name : String,
    @value : T,
    @description : String? = nil,
  ); end

  def match(actual_value : ATH::Request) : Bool
    @value == actual_value.attributes.get?(@name, T)
  end

  def match(actual_value : _) : Bool
    false
  end

  def failure_message(actual_value : ATH::Request) : String
    String.build do |io|
      if desc = @description
        io << desc << '\n' << '\n'
      end

      io << "Failed asserting that the request has attribute '#{@name}' with value '#{@value}'."
    end
  end

  def negative_failure_message(actual_value : ATH::Request) : String
    String.build do |io|
      if desc = @description
        io << desc << '\n' << '\n'
      end

      io << "Failed asserting that the request does not have attribute '#{@name}' with value '#{@value}'."
    end
  end
end
