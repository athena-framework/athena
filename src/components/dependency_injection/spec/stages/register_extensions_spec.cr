require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::RegisterExtensions do
  describe "compiler errors" do
    describe "root level" do
      it "errors if a configuration value has the incorrect type" do
        assert_error "Required configuration property 'test.id : Int32' must be provided.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property id : Int32
            property name : String
          end

          ADI.configure({
            test: {
              name: "Fred"
            }
          })
        CR
      end

      it "errors if there is a collection type mismatch" do
        assert_error "Expected configuration value 'test.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [] of String
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array" do
        assert_error "Expected configuration value 'test.foo[0]' to be a 'Int32', but got 'UInt64'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [10_u64] of Int32
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_error "Encountered unexpected property 'test.name' with value '\"Fred\"'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property id : Int32
          end

          ADI.configure({
            test: {
              id: 10,
              name: "Fred"
            }
          })
        CR
      end

      it "errors if an array does not specify its type" do
        assert_error "Array configuration value 'test.foo' must specify its type: [10_u64] of Int32", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [10_u64]
            }
          })
        CR
      end
    end

    describe "nested level" do
      it "errors if a configuration value has the incorrect type" do
        assert_error "Required configuration property 'test.sub_config.defaults.id : Int32' must be provided.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property name : String
                property id : Int32
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  name: "Fred"
                }
              }
            }
          })
        CR
      end

      it "errors if there is a collection type mismatch" do
        assert_error "Expected configuration value 'test.sub_config.defaults.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [] of String
                }
              }
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array" do
        assert_error "Expected configuration value 'test.sub_config.defaults.foo[1]' to be a 'Int32', but got 'UInt64'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [1, 10_u64] of Int32
                }
              }
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_error "Encountered unexpected property 'test.sub_config.defaults.name' with value '\"Fred\"'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property id : Int32
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  id: 10,
                  name: "Fred"
                }
              }
            }
          })
        CR
      end

      it "errors if an array does not specify its type" do
        assert_error "Array configuration value 'test.sub_config.defaults.foo' must specify its type: [10_u64] of Int32", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [10_u64]
                }
              }
            }
          })
        CR
      end
    end

    it "errors if a configuration value has the incorrect type" do
      assert_error "Extension 'foo' is configured, but no extension with that name has been registered.", <<-CR
        ADI.configure({
          foo: {
            id: 1
          }
        })
      CR
    end
  end

  it "extension configuration value resolution", tags: "compiler" do
    ASPEC::Methods.assert_success <<-CR
      require "../spec_helper"

      enum Color
        Red
        Green
        Blue
      end

      @[ADI::RegisterExtension("blah")]
      module ExampleExtension
        include ADI::Extension

        ID = 10.0

        property id : Int32
        property float : Float64 = ExampleExtension::ID
        property name : String = "fred"
        property nilable : String?
        property color_type : Color
        property color_sym : Color
        property value : Hash(String, String)
      end

      ADI.configure({
        blah: {
          id:    123,
          color_type: Color::Red,
          color_sym: :blue,
          value: {"id" => "10", "name" => "fred"}
        },
      })

      macro finished
        macro finished
          it { \\{{ADI::CONFIG["blah"]["id"]}}.should eq 123 }
          it { \\{{ADI::CONFIG["blah"]["name"]}}.should eq "fred" }
          it { \\{{ADI::CONFIG["blah"]["float"]}}.should eq 10 }
          it { \\{{ADI::CONFIG["blah"]["nilable"]}}.should be_nil }
          it { \\{{ADI::CONFIG["blah"]["color_type"]}}.should eq Color::Red }
          it { \\{{ADI::CONFIG["blah"]["color_sym"]}}.should eq Color::Blue }
          it { \\{{ADI::CONFIG["blah"]["value"]}}.should eq({"id" => "10", "name" => "fred"}) }
        end
      end
    CR
  end
end
