# `ASPEC::TestCase` provides a [Spec](https://crystal-lang.org/api/Spec.html) compliant
# alternative DSL for creating unit and integration tests.  It allows structuring tests
# in a more OOP fashion, with the main benefits of reusability and extendability.
#
# This type can be extended to share common testing logic with groups of similar types.
# Any tests defined within a parent will run for each child test case.
# `abstract def`, `super`, and other OOP features can be used as well to reduce duplication.
# Some additional features are also built in, such as the `DataProvider`.
#
# NOTE: This is _NOT_ a standalone testing framework.  Everything boils down to standard `describe`, `it`, and/or `pending` blocks.
#
# A test case consists of a `struct` inheriting from `self`, optionally with an `#initialize` method in order to
# initialize the state that should be used for each test.
#
# A test is a method that starts with `test_`, where the method name is used as the description.
# For example, `test_some_method_some_context` becomes `"some method some context"`.
# Internally each test method maps to an `it` block.
# All of the stdlib's `Spec` assertions methods are available, in addition to
# [#pending!](https://crystal-lang.org/api/Spec/Methods.html#pending!%28msg=%22Cannotrunexample%22,file=__FILE__,line=__LINE__%29-instance-method) and
# [#fail](https://crystal-lang.org/api/Spec/Methods.html#fail%28msg,file=__FILE__,line=__LINE__%29-instance-method).
#
# A method may be focused by either prefixing the method name with an `f`, or applying the `Focus` annotation.
#
# A method may be marked pending by either prefixing the method name with a `p`, or applying the `Pending` annotation.
# Internally this maps to a `pending` block.
#
# Tags may be applied to a method via the `Tags` annotation.
#
# The `Tags`, `Focus`, and `Pending` annotations may also be applied to the test case type as well, with a similar affect.
#
# ### Example
#
# ```
# # Require the stdlib's spec module.
# require "spec"
#
# # Define a class to test.
# class Calculator
#   def add(v1, v2)
#     v1 + v2
#   end
#
#   def subtract(v1, v2)
#     raise NotImplementedError.new "TODO"
#   end
# end
#
# # An example test case.
# struct ExampleSpec < ASPEC::TestCase
#   @target : Calculator
#
#   # Initialize the test target along with any dependencies.
#   def initialize : Nil
#     @target = Calculator.new
#   end
#
#   # All of the stdlib's `Spec` methods can be used,
#   # plus any custom methods defined in `ASPEC::Methods`.
#   def test_add : Nil
#     @target.add(1, 2).should eq 3
#   end
#
#   # A pending test.
#   def ptest_subtract : Nil
#     @target.subtract(10, 5).should eq 5
#   end
#
#   # Private/protected methods can be used to reduce duplication within the context of single test case.
#   private def helper_method
#     # ...
#   end
# end
# ```
#
# ## Inheritance
#
# Inheritance can be used to build reusable test cases for groups of similar objects
#
# ```
# abstract struct SomeTypeTestCase < ASPEC::TestCase
#   # Require children to define a method to get the object.
#   protected abstract def get_object : Calculator
#
#   # Test cases can use the abstract method for tests common to all test cases of this type.
#   def test_common : Nil
#     obj = self.get_object
#
#     # ...
#   end
# end
#
# struct CalculatorTest < SomeTypeTestCase
#   protected def get_object : Calculator
#     Calculator.new
#   end
#
#   # Additional tests specific to this type.
#   def test_specific : Nil
#     # ...
#   end
# end
# ```
#
# ## Data Providers
#
# A `DataProvider` can be used to reduce duplication, see the corresponding annotation or more information.
#
# ```
# struct DataProviderTest < ASPEC::TestCase
#   # Data Providers allow reusing a test's multiple times with different input.
#   @[DataProvider("get_values")]
#   def test_squares(value : Int32, expected : Int32) : Nil
#     (value ** 2).should eq expected
#   end
#
#   # Returns a hash where the key represents the name of the test,
#   # and the value is a Tuple of data that should be provided to the test.
#   def get_values : Hash
#     {
#       "two"   => {2, 4},
#       "three" => {3, 9},
#     }
#   end
# end
# ```
#
# ```
# # Run all the test cases
# ASPEC.run_all # =>
# # ExampleSpec
# #   add
# #   subtract
# #   a custom method name
# # CalculatorTest
# #   common
# #   specific
# # DataProviderTest
# #   squares two
# #   squares three
# #
# # Pending:
# # ExampleSpec subtract
# #
# # Finished in 172 microseconds
# # 7 examples, 0 failures, 0 errors, 1 pending
# ```
abstract struct Athena::Spec::TestCase
  include Athena::Spec::Methods

  # Defines the tags tied to a specific test case (describe block) or method (it block).
  #
  # Maps to [Tagging Specs](https://crystal-lang.org/reference/guides/testing.html#tagging-specs) in the stdlib.
  annotation Tags; end

  # Focuses a specific test case (describe block) or method (it block).
  #
  # Maps to [Focusing Specs](https://crystal-lang.org/reference/guides/testing.html#focusing-on-a-group-of-specs) in the stdlib.
  annotation Focus; end

  # Marks a specific test case (describe block) or method (it block) as `pending`.
  #
  # Maps to the stdlib's [#pending](https://crystal-lang.org/api/master/Spec/Methods.html#pending%28description=%22assert%22,file=__FILE__,line=__LINE__,end_line=__END_LINE__,focus:Bool=false,tags:String%7CEnumerable%28String%29%7CNil=nil,&%29-instance-method) method.
  annotation Pending; end

  # Can be applied to an `ASPEC::TestCase` type to denote it should be skipped when running tests via `ASPEC.run_all`.
  # Useful for creating mock types, or to have more control over when it should be ran.
  annotation Skip; end

  # Tests can be defined with arbitrary arguments.  These arguments are provided by one or more `DataProvider`.
  #
  # A data provider is a method that returns either a `Hash`, `NamedTuple`, `Array`, or `Tuple`.
  #
  # NOTE: The method's return type must be set to one of those types.
  #
  # If the return type is a `Hash` or `NamedTuple` then it is a keyed provider;
  # the key will be used as part of the description for each test.
  #
  # If the return type is an `Array` or `Tuple` it is considered a keyless provider;
  # the index will be used as part of the description for each test.
  #
  # NOTE: In both cases the value must be a `Tuple`; the values should be an ordered list of the arguments you want to provide to the test.
  #
  # One or more `DataProvider` annotations can be applied to a test
  # with a positional argument of the name of the providing methods.
  # An `it` block will be defined for each "set" of data.
  #
  # Data providers can be a very powerful tool when combined with inheritance and `abstract def`s.
  # A parent test case could define all the testing logic, and child implementations only provide the data.
  #
  # ### Example
  #
  # ```
  # require "athena-spec"
  #
  # struct DataProviderTest < ASPEC::TestCase
  #   @[DataProvider("get_values_hash")]
  #   @[DataProvider("get_values_named_tuple")]
  #   def test_squares(value : Int32, expected : Int32) : Nil
  #     (value ** 2).should eq expected
  #   end
  #
  #   # A keyed provider using a Hash.
  #   def get_values_hash : Hash
  #     {
  #       "two"   => {2, 4},
  #       "three" => {3, 9},
  #     }
  #   end
  #
  #   # A keyed provider using a NamedTuple.
  #   def get_values_named_tuple : NamedTuple
  #     {
  #       four: {4, 16},
  #       five: {5, 25},
  #     }
  #   end
  #
  #   @[DataProvider("get_values_array")]
  #   @[DataProvider("get_values_tuple")]
  #   def test_cubes(value : Int32, expected : Int32) : Nil
  #     (value ** 3).should eq expected
  #   end
  #
  #   # A keyless provider using an Array.
  #   def get_values_array : Array
  #     [
  #       {2, 8},
  #       {3, 27},
  #     ]
  #   end
  #
  #   # A keyless provider using a Tuple.
  #   def get_values_tuple : Tuple
  #     {
  #       {4, 64},
  #       {5, 125},
  #     }
  #   end
  # end
  #
  # DataProviderTest.run # =>
  # # DataProviderTest
  # #   squares two
  # #   squares three
  # #   squares four
  # #   squares five
  # #   cubes 0
  # #   cubes 1
  # #   cubes 2
  # #   cubes 3
  # ```
  annotation DataProvider; end

  # Instead of created a dedicated methods for use with `DataProvider`, you can define a data set using the `TestWith` annotation.
  # The annotations accepts a variadic amount of `Tuple` positional/named arguments and will create a `it` case for each "set" of data.
  #
  # ### Example
  #
  # ```
  # require "athena-spec"
  #
  # struct TestWithTest < ASPEC::TestCase
  #   @[TestWith(
  #     two: {2, 4},
  #     three: {3, 9},
  #     four: {4, 16},
  #     five: {5, 25},
  #   )]
  #   def test_squares(value : Int32, expected : Int32) : Nil
  #     (value ** 2).should eq expected
  #   end
  #
  #   @[TestWith(
  #     {2, 8},
  #     {3, 27},
  #     {4, 64},
  #     {5, 125},
  #   )]
  #   def test_cubes(value : Int32, expected : Int32) : Nil
  #     (value ** 3).should eq expected
  #   end
  # end
  #
  # TestWithTest.run # =>
  # # TestWithTest
  # #   squares two
  # #   squares three
  # #   squares four
  # #   squares five
  # #   cubes 0
  # #   cubes 1
  # #   cubes 2
  # #   cubes 3
  # ```
  annotation TestWith; end

  # Runs the tests contained within `self`.
  #
  # See `Athena::Spec.run_all` to run all test cases.
  def self.run : Nil
    instance = new

    {% begin %}
      {{!!@type.annotation(Pending) ? "pending".id : "describe".id}} {{@type.name.stringify}}, focus: {{!!@type.annotation Focus}}{% if (tags = @type.annotation(Tags)) %}, tags: {{tags.args}}{% end %} do
        before_all do
          instance.before_all
        end

        before_each do
          instance.initialize
        end

        after_each do
          instance.tear_down
        end

        after_all do
          instance.after_all
        end

        {% methods = [] of Nil %}

        {% for parent in @type.ancestors.select &.<(TestCase) %}
          {% for method in parent.methods.select { |m| m.name =~ /^(?:f|p)?test_/ } %}
            {% methods << method %}
          {% end %}
        {% end %}

        {% for test in methods + @type.methods.select { |m| m.name =~ /^(?:f|p)?test_/ } %}
          {% focus = test.name.starts_with?("ftest_") || !!test.annotation Focus %}
          {% tags = (tags = test.annotation(Tags)) ? tags.args : nil %}
          {% method = (test.name.starts_with?("ptest_") || !!test.annotation Pending) ? "pending" : "it" %}
          {% description = test.name.stringify.gsub(/^(?:f|p)?test_/, "").underscore.gsub(/_/, " ") %}

          {% if test_with = test.annotation(TestWith) %}
            # Treat args as Array/Tuple data providers
            {% for args, idx in test_with.args %}
              {% args.raise "Expected argument ##{idx} of the 'ASPEC::TestCase::TestWith' annotation applied to '#{@type}##{test.name.id}' to be a Tuple, but got '#{args.class_name.id}'." unless args.is_a? TupleLiteral %}
              {% args.raise "Expected argument ##{idx} of the 'ASPEC::TestCase::TestWith' annotation applied to '#{@type}##{test.name.id}' to contain #{test.args.size} values, but got #{args.size}." if test.args.size != args.size %}

              {{method.id}} "#{{{description}}} #{{{idx}}}", file: {{test.filename}}, line: {{test.line_number}}, end_line: {{test.end_line_number}}, focus: {{focus}}, tags: {{tags}} do
                instance.{{test.name.id}} *{{args}}
              end
            {% end %}

            # Treat named args as Hash/NamedTuple data providers
            {% for name, args in test_with.named_args %}
              {% args.raise "Expected the value of argument '#{name.id}' of the 'ASPEC::TestCase::TestWith' annotation applied to '#{@type}##{test.name.id}' to be a Tuple, but got '#{args.class_name.id}'." unless args.is_a? TupleLiteral %}
              {% args.raise "Expected the value of argument '#{name.id}' of the 'ASPEC::TestCase::TestWith' annotation applied to '#{@type}##{test.name.id}' to contain #{test.args.size} values, but got #{args.size}." if test.args.size != args.size %}

              {{method.id}} "#{{{description}}} #{{{name.stringify}}}", file: {{test.filename}}, line: {{test.line_number}}, end_line: {{test.end_line_number}}, focus: {{focus}}, tags: {{tags}} do
                instance.{{test.name.id}} *{{args}}
              end
            {% end %}
          {% elsif !test.annotations(DataProvider).empty? %}
            {% for data_provider in test.annotations DataProvider %}
              {% data_provider_method_name = data_provider[0] || data_provider.raise "One or more data provider for test '#{@type}##{test.name.id}' is missing its name." %}
              {% methods = @type.methods %}

              {% for ancestor in @type.ancestors.select &.<=(ASPEC::TestCase) %}
                {% methods += ancestor.methods %}
              {% end %}

              {% provider_method_return_type = (methods.find(&.name.stringify.==(data_provider_method_name)).return_type || raise "Data provider '#{@type}##{data_provider_method_name.id}' must have a return type of Hash, NamedTuple, Array, or Tuple.").resolve %}

              {% if provider_method_return_type == Hash || provider_method_return_type == NamedTuple %}
                instance.{{data_provider_method_name.id}}.each do |name, args|
                  {{method.id}} "#{{{description}}} #{name}", file: {{test.filename}}, line: {{test.line_number}}, end_line: {{test.end_line_number}}, focus: {{focus}}, tags: {{tags}} do
                    instance.{{test.name.id}} *args
                  end
                end
              {% elsif provider_method_return_type == Array || provider_method_return_type == Tuple %}
                instance.{{data_provider_method_name.id}}.each_with_index do |args, idx|
                  {{method.id}} "#{{{description}}} #{idx}", file: {{test.filename}}, line: {{test.line_number}}, end_line: {{test.end_line_number}}, focus: {{focus}}, tags: {{tags}} do
                    instance.{{test.name.id}} *args
                  end
                end
              {% else %}
                {% provider_method.raise "Unsupported data provider return type: '#{provider_method.return_type}'" %}
              {% end %}
            {% end %}
          {% else %}
            {{method.id}} {{description}}, file: {{test.filename}}, line: {{test.line_number}}, end_line: {{test.end_line_number}}, focus: {{focus}}, tags: {{tags}} do
              instance.{{test.name.id}}
            end
          {% end %}
        {% end %}
      end
    {% end %}
  end

  # Runs once before any tests within `self` have been executed.
  #
  # Can be used to initialize objects common to every test,
  # but that do not need to be reset before running each test.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # struct ExampleSpec < ASPEC::TestCase
  #   def before_all : Nil
  #     puts "This prints only once before anything else"
  #   end
  #
  #   def test_one : Nil
  #     true.should be_true
  #   end
  #
  #   def test_two : Nil
  #     1.should eq 1
  #   end
  # end
  #
  # ExampleSpec.run
  # ```
  def before_all : Nil
  end

  # Runs once after all tests within `self` have been executed.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # struct ExampleSpec < ASPEC::TestCase
  #   def after_all : Nil
  #     puts "This prints only once after anything else"
  #   end
  #
  #   def test_one : Nil
  #     true.should be_true
  #   end
  #
  #   def test_two : Nil
  #     1.should eq 1
  #   end
  # end
  #
  # ExampleSpec.run
  # ```
  def after_all : Nil
  end

  # Runs before each test.
  #
  # Used to create the objects that will be used within the tests.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # struct ExampleSpec < ASpec::TestCase
  #   @value : Int32
  #
  #   def initialize : Nil
  #     @value = 1
  #   end
  #
  #   def test_one : Nil
  #     @value += 1
  #
  #     @value # => 2
  #   end
  #
  #   def test_two : Nil
  #     @value # => 1
  #   end
  # end
  #
  # ExampleSpec.run
  # ```
  def initialize : Nil
  end

  # Runs after each test.
  #
  # Can be used to cleanup data in between tests, such as releasing a connection or closing a file.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # struct ExampleSpec < ASPEC::TestCase
  #   @file : File
  #
  #   def initialize : Nil
  #     @file = File.new "./foo.txt", "w"
  #   end
  #
  #   def tear_down : Nil
  #     @file.close
  #   end
  #
  #   def test_one : Nil
  #     @file.path # => "./foo.txt"
  #   end
  # end
  #
  # ExampleSpec.run
  # ```
  def tear_down : Nil
  end

  # Helper macro DSL for defining a test method.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # struct ExampleSpec < ASPEC::TestCase
  #   test "2 is even" do
  #     2.even?.should be_true
  #   end
  # end
  #
  # ExampleSpec.run
  # ```
  private macro test(name, focus = false, *tags)
    {% if focus %}@[Focus]{% end %}
    {% unless tags.empty? %}@[Tags({{tags.splat}})]{% end %}
    def test_{{name.gsub(/[^\w]/, "_").underscore.downcase.id}} : Nil
      {{yield}}
    end
  end
end
