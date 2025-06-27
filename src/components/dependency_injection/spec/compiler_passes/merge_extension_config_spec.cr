require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::MergeExtensionConfig, tags: "compiled" do
  describe "compiler errors" do
    describe "root level" do
      it "errors if a required configuration value has not been provided" do
        assert_compile_time_error "Required configuration property 'test.id : Int32' must be provided.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            property id : Int32
            property name : String
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              name: "Fred"
            }
          })
        CR
      end

      it "errors if there is a collection type mismatch" do
        assert_compile_time_error "Expected configuration value 'test.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            property foo : Array(Int32)
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              foo: [] of String
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array" do
        assert_compile_time_error "Expected configuration value 'test.foo[0]' to be a 'Int32', but got 'UInt64'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            property foo : Array(Int32)
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              foo: [10_u64] of Int32
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_compile_time_error "Encountered unexpected property 'test.name' with value '\"Fred\"'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            property id : Int64
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              id: 10,
              name: "Fred"
            }
          })
        CR
      end
    end

    describe "nested level" do
      it "errors if a configuration value has the incorrect type" do
        assert_compile_time_error "Required configuration property 'test.sub_config.defaults.id : Int32' must be provided.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property name : String
                property id : Int32
              end
            end
          end

          ADI.register_extension "test", Schema

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
        assert_compile_time_error "Expected configuration value 'test.sub_config.defaults.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property foo : Array(Int32)
              end
            end
          end

          ADI.register_extension "test", Schema

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
        assert_compile_time_error "Expected configuration value 'test.sub_config.defaults.foo[1]' to be a 'Int32', but got 'UInt64'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property foo : Array(Int32)
              end
            end
          end

          ADI.register_extension "test", Schema

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

      it "errors if there is a type mismatch within an array without type hint" do
        assert_compile_time_error "Expected configuration value 'test.sub_config.defaults.foo[1]' to be a 'Int32', but got 'UInt64'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property foo : Array(Int32)
              end
            end
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [1, 10_u64]
                }
              }
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array using NoReturn schema default" do
        assert_compile_time_error "Expected configuration value 'test.sub_config.defaults.foo[1]' to be a 'Int32', but got 'UInt64'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property foo : Array(Int32)
              end
            end
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [1, 10_u64]
                }
              }
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_compile_time_error "Encountered unexpected property 'test.sub_config.defaults.name' with value '\"Fred\"'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            module SubConfig
              include ADI::Extension::Schema

              module Defaults
                include ADI::Extension::Schema

                property id : Int32
              end
            end
          end

          ADI.register_extension "test", Schema

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
    end

    it "errors if a configuration value has the incorrect type" do
      assert_compile_time_error "Extension 'foo' is configured, but no extension with that name has been registered.", <<-'CR'
        ADI.configure({
          foo: {
            id: 1
          }
        })
      CR
    end

    it "errors if nothing is configured, but a property is required" do
      assert_compile_time_error "Required configuration property 'test.id : Int32' must be provided.", <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema

          property id : Int32
        end

        ADI.register_extension "test", Schema
      CR
    end
  end

  it "extension configuration value resolution" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      enum Color
        Red
        Green
        Blue
      end

      module Schema
        include ADI::Extension::Schema

        ID = 10.0

        property id : Int32
        property float : Float64 = Schema::ID
        property name : String = "fred"
        property nilable : String?
        property color_type : Color
        property color_sym : Color
        property color_default : Color = :green
        property value : Hash(String, String)
        property regex : Regex
      end

      ADI.register_extension "blah", Schema

      ADI.configure({
        blah: {
          id:    123,
          color_type: Color::Red,
          color_sym: :blue,
          value: {"id" => "10", "name" => "fred"},
          regex: /foo/
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["blah"]

            raise "#{config}" unless config["id"] == 123
            raise "#{config}" unless config["name"] == "fred"
            raise "#{config}" unless config["float"] == 10.0
            raise "#{config}" unless config["nilable"].nil?
            raise "#{config}" unless config["color_type"].stringify == "Color.new(0)"
            raise "#{config}" unless config["color_sym"].stringify == "Color.new(:blue)"
            raise "#{config}" unless config["color_default"].stringify == "Color.new(:green)"
            raise "#{config}" unless config["value"] == {"id" => "10", "name" => "fred"}
            raise "#{config}" unless config["regex"] == /foo/
          %}
        end
      end
    CR
  end

  it "does not error if nothing is configured, but all properties have defaults or are nilable" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property id : Int32 = 123
      end

      ADI.register_extension "blah", Schema

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["blah"]

            raise "#{config}" unless config["id"] == 123
          %}
        end
      end
    CR
  end

  it "inherits type of arrays from property if not explicitly set" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property foo : Array(Int32)
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          foo: [1, 2]
        }
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["foo"] == [1, 2]
          %}
        end
      end
    CR
  end

  it "allows using NoReturn to type empty arrays in schema" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property foo : Array(Int32 | String) = [] of NoReturn
      end

      ADI.register_extension "test", Schema

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["foo"].stringify == "Array(Int32 | String).new"
          %}
        end
      end
    CR
  end

  it "allows customizing values when using NoReturn to type empty arrays defaults in schema" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property foo : Array(Int32 | String) = [] of NoReturn
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          foo: [1, 2]
        }
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["foo"] == [1, 2]
          %}
        end
      end
    CR
  end

  it "expands schema to include expected structure/defaults if not configuration is provided" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        module One
          include ADI::Extension::Schema

          property enabled : Bool = false
        end

        module Two
          include ADI::Extension::Schema

          property enabled : Bool = false
        end
      end

      ADI.register_extension "test", Schema

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["one"]["enabled"] == false
            raise "#{config}" unless config["two"]["enabled"] == false
          %}
        end
      end
    CR
  end

  it "expands schema to include expected structure/defaults if not explicitly provided" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        module One
          include ADI::Extension::Schema

          property enabled : Bool = false
          property id : Int32
        end

        module Two
          include ADI::Extension::Schema

          property enabled : Bool = false

          module Three
            include ADI::Extension::Schema

            property enabled : Bool = false
          end
        end
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          one: {
            id: 10,
          },
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["one"]["enabled"] == false
            raise "#{config}" unless config["one"]["id"] == 10

            raise "#{config}" unless config["two"]["enabled"] == false
            raise "#{config}" unless config["two"]["three"]["enabled"] == false
          %}
        end
      end
    CR
  end

  it "merges missing array_of defaults" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema
        array_of rules, id : Int32, stop : Bool = false
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          rules: [
            {id: 10},
          ],
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["rules"][0]["id"] == 10
            raise "#{config}" unless config["rules"][0]["stop"] == false
          %}
        end
      end
    CR
  end

  it "merges missing array_of defaults in time for other compiler passes" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema
        array_of rules, id : Int32, stop : Bool = false
      end

      module MyExtension
        macro included
            macro finished
              {% verbatim do %}
                {%
                  ADI::CONFIG["parameters"]["stop"] = ADI::CONFIG["test"]["rules"][0]["stop"]
                %}
              {% end %}
            end
          end
      end

      ADI.register_extension "test", Schema
      ADI.add_compiler_pass MyExtension, :before_optimization, 500 # Ensure the Config passes run first

      ADI.configure({
        test: {
          rules: [
            {id: 10},
          ],
        },
      })

      macro finished
        macro finished
          \{%
            parameters = ADI::CONFIG["parameters"]

            raise "#{parameters}" unless parameters["stop"] == false
          %}
        end
      end
    CR
  end

  it "fills in missing nilable keys with `nil`" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        object_of config, id : Int32, name : String?
      end

      ADI.register_extension "blah", Schema

      ADI.configure({
        blah: {
          config: {id: 10},
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["blah"]

            raise "#{config}" unless config["config"].keys.stringify == %([__nil, id, name])
            raise "#{config}" unless config["config"]["id"] == 10
            raise "#{config}" unless config["config"]["name"].nil?
          %}
        end
      end
    CR
  end

  it "fills in missing nilable keys with `nil` when missing from default value" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        object_of config = {id: 123}, id : Int32, name : String?
      end

      ADI.register_extension "blah", Schema

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["blah"]

            raise "#{config}" unless config["config"].keys.stringify == %([id, name])
            raise "#{config}" unless config["config"]["id"] == 123
            raise "#{config}" unless config["config"]["name"].nil?
          %}
        end
      end
    CR
  end
end
