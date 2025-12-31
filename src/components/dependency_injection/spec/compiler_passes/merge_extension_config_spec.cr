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
        assert_compile_time_error "Unexpected property 'test.name'.", <<-'CR'
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
        assert_compile_time_error "Unexpected property 'test.sub_config.defaults.name'.", <<-'CR'
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
        property color_global : ::Color = :red
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
            raise "#{config}" unless config["color_global"].stringify == "::Color.new(:red)"
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

  it "array_of with nested object_schema fills in nested defaults" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        object_schema JwtConfig,
          secret : String,
          algorithm : String = "hmac.sha256"

        array_of items,
          name : String,
          jwt : JwtConfig
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          items: [
            {name: "item1", jwt: {secret: "secret1"}},
            {name: "item2", jwt: {secret: "secret2"}},
          ],
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["items"][0]["name"] == "item1"
            raise "#{config}" unless config["items"][0]["jwt"]["secret"] == "secret1"
            raise "#{config}" unless config["items"][0]["jwt"]["algorithm"] == "hmac.sha256"

            raise "#{config}" unless config["items"][1]["name"] == "item2"
            raise "#{config}" unless config["items"][1]["jwt"]["secret"] == "secret2"
            raise "#{config}" unless config["items"][1]["jwt"]["algorithm"] == "hmac.sha256"
          %}
        end
      end
    CR
  end

  it "object_of with nested object_schema fills in nested defaults" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        object_schema JwtConfig,
          secret : String,
          algorithm : String = "hmac.sha256"

        object_of connection,
          url : String,
          jwt : JwtConfig
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          connection: {
            url: "localhost",
            jwt: {secret: "my-secret"},
          },
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]

            raise "#{config}" unless config["connection"]["url"] == "localhost"
            raise "#{config}" unless config["connection"]["jwt"]["secret"] == "my-secret"
            raise "#{config}" unless config["connection"]["jwt"]["algorithm"] == "hmac.sha256"
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

  describe "map_of" do
    it "merges missing map_of defaults for each value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {url: "localhost"},
              secondary: {url: "remote", port: 5433},
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              raise "#{config}" unless config["hubs"]["primary"]["url"] == "localhost"
              raise "#{config}" unless config["hubs"]["primary"]["port"] == 5432
              raise "#{config}" unless config["hubs"]["secondary"]["url"] == "remote"
              raise "#{config}" unless config["hubs"]["secondary"]["port"] == 5433
            %}
          end
        end
      CR
    end

    it "defaults to empty hash when not provided" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {} of Nil => Nil,
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              # Check that hubs key exists and is empty (when converted to string, looks like "{}" or "{hubs => {}}")
              found_hubs = false
              config.each do |k, v|
                if k.stringify == "hubs"
                  found_hubs = true
                  raise "Expected empty hash but got #{v}" unless v.keys.reject { |vk| vk.stringify == "__nil" }.empty?
                end
              end
              raise "hubs key not found in config: #{config}" unless found_hubs
            %}
          end
        end
      CR
    end

    it "map_of? defaults to nil when not provided" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema
          map_of? hubs, url : String
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {} of Nil => Nil,
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              raise "#{config}" unless config["hubs"].nil?
            %}
          end
        end
      CR
    end

    it "map_of with nested object_schema fills in nested defaults" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"

          map_of hubs,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {
                url: "localhost",
                jwt: {secret: "my-secret"},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              raise "#{config}" unless config["hubs"]["primary"]["url"] == "localhost"
              raise "#{config}" unless config["hubs"]["primary"]["jwt"]["secret"] == "my-secret"
              raise "#{config}" unless config["hubs"]["primary"]["jwt"]["algorithm"] == "hmac.sha256"
            %}
          end
        end
      CR
    end

    it "errors if a required hash value property is missing" do
      assert_compile_time_error "Configuration value 'test.hubs.primary' is missing required value for 'url' of type 'String'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {port: 5432},
            },
          },
        })
      CR
    end

    it "errors if a hash value has an unexpected key" do
      assert_compile_time_error "Expected configuration value 'test.hubs.primary' to be a '{url: url : String, port: port : Int32 = 5432}', but encountered unexpected key 'invalid'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {url: "localhost", invalid: "foo"},
            },
          },
        })
      CR
    end

    it "errors if a nested map value has an unexpected type" do
      assert_compile_time_error "Expected configuration value 'test.hubs.primary.jwt.secret' to be a 'String', but got 'Int32'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String

          map_of hubs,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {
                url: "localhost",
                jwt: {secret: 123},
              },
            },
          },
        })
      CR
    end

    it "errors if a hash value property has wrong type" do
      assert_compile_time_error "Expected configuration value 'test.hubs.primary.port' to be a 'Int32', but got 'String'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String, port : Int32
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {url: "localhost", port: "not-a-number"},
            },
          },
        })
      CR
    end

    it "fills in nested object_schema defaults for multiple map entries independently" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"

          map_of hubs,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {
                url: "localhost",
                jwt: {secret: "secret1"},
              },
              secondary: {
                url: "remote",
                jwt: {secret: "secret2"},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              # Verify both entries get their own independent defaults
              raise "#{config}" unless config["hubs"]["primary"]["jwt"]["algorithm"] == "hmac.sha256"
              raise "#{config}" unless config["hubs"]["secondary"]["jwt"]["algorithm"] == "hmac.sha256"

              # And their unique values are preserved
              raise "#{config}" unless config["hubs"]["primary"]["jwt"]["secret"] == "secret1"
              raise "#{config}" unless config["hubs"]["secondary"]["jwt"]["secret"] == "secret2"
            %}
          end
        end
      CR
    end

    it "errors if nested object_schema field is missing required value" do
      assert_compile_time_error "Configuration value 'test.hubs.primary.jwt' is missing required value for 'secret' of type 'String'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"

          map_of hubs,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {
                url: "localhost",
                jwt: {algorithm: "rsa"},
              },
            },
          },
        })
      CR
    end

    it "errors if nested object_schema has unexpected key" do
      assert_compile_time_error "Expected configuration value 'test.hubs.primary.jwt' to be a '{secret: secret : String, algorithm: algorithm : String = \"hmac.sha256\"}', but encountered unexpected key 'invalid'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"

          map_of hubs,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            hubs: {
              primary: {
                url: "localhost",
                jwt: {secret: "my-secret", invalid: "foo"},
              },
            },
          },
        })
      CR
    end

    it "uses custom default for map_of with assignment syntax" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        module Schema
          include ADI::Extension::Schema
          map_of hubs = {default: {url: "localhost", port: 8080}}, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        # Don't configure hubs at all - it should use the custom default

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]

              # Custom default entry should be present with its values
              raise "#{config}" unless config["hubs"]["default"]["url"] == "localhost"
              raise "#{config}" unless config["hubs"]["default"]["port"] == 8080
            %}
          end
        end
      CR
    end
  end
end
