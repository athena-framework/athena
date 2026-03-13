require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: %(require "../spec_helper.cr"), postamble: "ADI::ServiceContainer.new"
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
          %}
          ASPEC.compile_time_assert(\{{ config["id"] == 123 }}, "Expected id to be 123")
          ASPEC.compile_time_assert(\{{ config["name"] == "fred" }}, "Expected name to be fred")
          ASPEC.compile_time_assert(\{{ config["float"] == 10.0 }}, "Expected float to be 10.0")
          ASPEC.compile_time_assert(\{{ config["nilable"].nil? }}, "Expected nilable to be nil")
          ASPEC.compile_time_assert(\{{ config["color_type"].stringify == "Color.new(0)" }}, "Expected color_type to be Color.new(0)")
          ASPEC.compile_time_assert(\{{ config["color_sym"].stringify == "Color.new(:blue)" }}, "Expected color_sym to be Color.new(:blue)")
          ASPEC.compile_time_assert(\{{ config["color_default"].stringify == "Color.new(:green)" }}, "Expected color_default to be Color.new(:green)")
          ASPEC.compile_time_assert(\{{ config["color_global"].stringify == "::Color.new(:red)" }}, "Expected color_global to be ::Color.new(:red)")
          ASPEC.compile_time_assert(\{{ config["value"] == {"id" => "10", "name" => "fred"} }}, "Expected value to be the expected hash")
          ASPEC.compile_time_assert(\{{ config["regex"] == /foo/ }}, "Expected regex to be /foo/")
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
          %}
          ASPEC.compile_time_assert(\{{ config["id"] == 123 }}, "Expected id to be 123")
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
          %}
          ASPEC.compile_time_assert(\{{ config["foo"] == [1, 2] }}, "Expected foo to be [1, 2]")
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
          %}
          ASPEC.compile_time_assert(\{{ config["foo"].stringify == "Array(Int32 | String).new" }}, "Expected foo to stringify as empty array")
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
          %}
          ASPEC.compile_time_assert(\{{ config["foo"] == [1, 2] }}, "Expected foo to be [1, 2]")
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
          %}
          ASPEC.compile_time_assert(\{{ config["one"]["enabled"] == false }}, "Expected one.enabled to be false")
          ASPEC.compile_time_assert(\{{ config["two"]["enabled"] == false }}, "Expected two.enabled to be false")
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
          %}
          ASPEC.compile_time_assert(\{{ config["one"]["enabled"] == false }}, "Expected one.enabled to be false")
          ASPEC.compile_time_assert(\{{ config["one"]["id"] == 10 }}, "Expected one.id to be 10")
          ASPEC.compile_time_assert(\{{ config["two"]["enabled"] == false }}, "Expected two.enabled to be false")
          ASPEC.compile_time_assert(\{{ config["two"]["three"]["enabled"] == false }}, "Expected two.three.enabled to be false")
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
          %}
          ASPEC.compile_time_assert(\{{ config["rules"][0]["id"] == 10 }}, "Expected rules[0].id to be 10")
          ASPEC.compile_time_assert(\{{ config["rules"][0]["stop"] == false }}, "Expected rules[0].stop to be false")
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
          %}
          ASPEC.compile_time_assert(\{{ parameters["stop"] == false }}, "Expected parameters stop to be false")
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
          %}
          ASPEC.compile_time_assert(\{{ config["items"][0]["name"] == "item1" }}, "Expected items[0].name to be item1")
          ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["secret"] == "secret1" }}, "Expected items[0].jwt.secret to be secret1")
          ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected items[0].jwt.algorithm to be hmac.sha256")
          ASPEC.compile_time_assert(\{{ config["items"][1]["name"] == "item2" }}, "Expected items[1].name to be item2")
          ASPEC.compile_time_assert(\{{ config["items"][1]["jwt"]["secret"] == "secret2" }}, "Expected items[1].jwt.secret to be secret2")
          ASPEC.compile_time_assert(\{{ config["items"][1]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected items[1].jwt.algorithm to be hmac.sha256")
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
          %}
          ASPEC.compile_time_assert(\{{ config["connection"]["url"] == "localhost" }}, "Expected connection.url to be localhost")
          ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["secret"] == "my-secret" }}, "Expected connection.jwt.secret to be my-secret")
          ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected connection.jwt.algorithm to be hmac.sha256")
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
          %}
          ASPEC.compile_time_assert(\{{ config["config"].keys.stringify == %([__nil, id, name]) }}, "Expected config keys to be [__nil, id, name]")
          ASPEC.compile_time_assert(\{{ config["config"]["id"] == 10 }}, "Expected config.id to be 10")
          ASPEC.compile_time_assert(\{{ config["config"]["name"].nil? }}, "Expected config.name to be nil")
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
          %}
          ASPEC.compile_time_assert(\{{ config["config"].keys.stringify == %([id, name]) }}, "Expected config keys to be [id, name]")
          ASPEC.compile_time_assert(\{{ config["config"]["id"] == 123 }}, "Expected config.id to be 123")
          ASPEC.compile_time_assert(\{{ config["config"]["name"].nil? }}, "Expected config.name to be nil")
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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["url"] == "localhost" }}, "Expected hubs.primary.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["port"] == 5432 }}, "Expected hubs.primary.port to be 5432")
            ASPEC.compile_time_assert(\{{ config["hubs"]["secondary"]["url"] == "remote" }}, "Expected hubs.secondary.url to be remote")
            ASPEC.compile_time_assert(\{{ config["hubs"]["secondary"]["port"] == 5433 }}, "Expected hubs.secondary.port to be 5433")
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
              hubs_empty = false
              config.each do |k, v|
                if k.stringify == "hubs"
                  found_hubs = true
                  hubs_empty = v.keys.reject { |vk| vk.stringify == "__nil" }.empty?
                end
              end
            %}
            ASPEC.compile_time_assert(\{{ found_hubs }}, "Expected hubs key to exist in config")
            ASPEC.compile_time_assert(\{{ hubs_empty }}, "Expected empty hash for hubs")
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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"].nil? }}, "Expected hubs to be nil")
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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["url"] == "localhost" }}, "Expected hubs.primary.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["secret"] == "my-secret" }}, "Expected hubs.primary.jwt.secret to be my-secret")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected hubs.primary.jwt.algorithm to be hmac.sha256")
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

    it "errors if map_of direct member has wrong type when object_schema also present" do
      assert_compile_time_error "Expected configuration value 'test.hubs.primary.url' to be a 'String', but got 'Int32'.", <<-'CR'
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
                url: 123,
                jwt: {secret: "valid"},
              },
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
            %}
            # Verify both entries get their own independent defaults
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected hubs.primary.jwt.algorithm to be hmac.sha256")
            ASPEC.compile_time_assert(\{{ config["hubs"]["secondary"]["jwt"]["algorithm"] == "hmac.sha256" }}, "Expected hubs.secondary.jwt.algorithm to be hmac.sha256")
            # And their unique values are preserved
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["secret"] == "secret1" }}, "Expected hubs.primary.jwt.secret to be secret1")
            ASPEC.compile_time_assert(\{{ config["hubs"]["secondary"]["jwt"]["secret"] == "secret2" }}, "Expected hubs.secondary.jwt.secret to be secret2")
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
            %}
            # Custom default entry should be present with its values
            ASPEC.compile_time_assert(\{{ config["hubs"]["default"]["url"] == "localhost" }}, "Expected hubs.default.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["hubs"]["default"]["port"] == 8080 }}, "Expected hubs.default.port to be 8080")
          end
        end
      CR
    end

    it "object_schema enum member with symbol default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["url"] == "localhost" }}, "Expected hubs.primary.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["secret"] == "my-secret" }}, "Expected hubs.primary.jwt.secret to be my-secret")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs256)" }}, "Expected hubs.primary.jwt.algorithm to be Algorithm.new(:hs256)")
          end
        end
      CR
    end

    it "object_schema enum member with user-provided symbol value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

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
                jwt: {secret: "my-secret", algorithm: :hs512},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["url"] == "localhost" }}, "Expected hubs.primary.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["secret"] == "my-secret" }}, "Expected hubs.primary.jwt.secret to be my-secret")
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs512)" }}, "Expected hubs.primary.jwt.algorithm to be Algorithm.new(:hs512)")
          end
        end
      CR
    end

    it "object_schema enum member with global type" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : ::Algorithm = :hs256

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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"].stringify == "::Algorithm.new(:hs256)" }}, "Expected hubs.primary.jwt.algorithm to be ::Algorithm.new(:hs256)")
          end
        end
      CR
    end

    it "errors for invalid enum symbol in object_schema" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for default value of 'test.hubs.primary.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :invalid_algo

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
      CR
    end

    it "errors for invalid user-provided enum symbol in object_schema" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for 'test.hubs.primary.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

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
                jwt: {secret: "my-secret", algorithm: :invalid_algo},
              },
            },
          },
        })
      CR
    end

    it "array_of object_schema enum member with symbol default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret"}},
            ],
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["items"][0]["name"] == "item1" }}, "Expected items[0].name to be item1")
            ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["secret"] == "my-secret" }}, "Expected items[0].jwt.secret to be my-secret")
            ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs256)" }}, "Expected items[0].jwt.algorithm to be Algorithm.new(:hs256)")
          end
        end
      CR
    end

    it "array_of object_schema enum member with user-provided symbol value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret", algorithm: :hs512}},
            ],
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs512)" }}, "Expected items[0].jwt.algorithm to be Algorithm.new(:hs512)")
          end
        end
      CR
    end

    it "errors for invalid enum symbol in array_of object_schema default" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for default value of 'test.items.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :invalid_algo

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret"}},
            ],
          },
        })
      CR
    end

    it "errors for invalid user-provided enum symbol in array_of object_schema" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for 'test.items.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret", algorithm: :invalid_algo}},
            ],
          },
        })
      CR
    end

    it "object_of object_schema enum member with symbol default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

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
            %}
            ASPEC.compile_time_assert(\{{ config["connection"]["url"] == "localhost" }}, "Expected connection.url to be localhost")
            ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["secret"] == "my-secret" }}, "Expected connection.jwt.secret to be my-secret")
            ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs256)" }}, "Expected connection.jwt.algorithm to be Algorithm.new(:hs256)")
          end
        end
      CR
    end

    it "object_of object_schema enum member with user-provided symbol value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          object_of connection,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              url: "localhost",
              jwt: {secret: "my-secret", algorithm: :hs512},
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["algorithm"].stringify == "Algorithm.new(:hs512)" }}, "Expected connection.jwt.algorithm to be Algorithm.new(:hs512)")
          end
        end
      CR
    end

    it "errors for invalid enum symbol in object_of object_schema default" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for default value of 'test.connection.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :invalid_algo

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
      CR
    end

    it "errors for invalid user-provided enum symbol in object_of object_schema" do
      assert_compile_time_error "Unknown 'Algorithm' enum member for 'test.connection.jwt.algorithm'.", <<-'CR'
        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          object_of connection,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              url: "localhost",
              jwt: {secret: "my-secret", algorithm: :invalid_algo},
            },
          },
        })
      CR
    end

    it "map_of object_schema enum member with number default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = 0

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
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"].stringify == "Algorithm.new(0)" }}, "Expected hubs.primary.jwt.algorithm to be Algorithm.new(0)")
          end
        end
      CR
    end

    it "map_of object_schema enum member with user-provided number value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

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
                jwt: {secret: "my-secret", algorithm: 2},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["hubs"]["primary"]["jwt"]["algorithm"].stringify == "Algorithm.new(2)" }}, "Expected hubs.primary.jwt.algorithm to be Algorithm.new(2)")
          end
        end
      CR
    end

    it "array_of object_schema enum member with number default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = 0

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret"}},
            ],
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["algorithm"].stringify == "Algorithm.new(0)" }}, "Expected items[0].jwt.algorithm to be Algorithm.new(0)")
          end
        end
      CR
    end

    it "array_of object_schema enum member with user-provided number value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          array_of items,
            name : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            items: [
              {name: "item1", jwt: {secret: "my-secret", algorithm: 2}},
            ],
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["items"][0]["jwt"]["algorithm"].stringify == "Algorithm.new(2)" }}, "Expected items[0].jwt.algorithm to be Algorithm.new(2)")
          end
        end
      CR
    end

    it "object_of object_schema enum member with number default value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = 0

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
            %}
            ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["algorithm"].stringify == "Algorithm.new(0)" }}, "Expected connection.jwt.algorithm to be Algorithm.new(0)")
          end
        end
      CR
    end

    it "object_of object_schema enum member with user-provided number value" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../spec_helper"

        enum Algorithm
          Hs256
          Hs384
          Hs512
        end

        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : Algorithm = :hs256

          object_of connection,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              url: "localhost",
              jwt: {secret: "my-secret", algorithm: 2},
            },
          },
        })

        macro finished
          macro finished
            \{%
              config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["connection"]["jwt"]["algorithm"].stringify == "Algorithm.new(2)" }}, "Expected connection.jwt.algorithm to be Algorithm.new(2)")
          end
        end
      CR
    end
  end

  it "handles multiple extensions where one has nested schemas" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      # First extension with nested schema modules
      module FirstSchema
        include ADI::Extension::Schema

        property root_prop : String = "root"

        module Nested
          include ADI::Extension::Schema

          property nested_prop : Int32 = 42
        end
      end

      # Second extension without nested schemas
      module SecondSchema
        include ADI::Extension::Schema

        property other_prop : Bool = true
      end

      ADI.register_extension "first", FirstSchema
      ADI.register_extension "second", SecondSchema

      macro finished
        macro finished
          \{%
            first_config = ADI::CONFIG["first"]
            second_config = ADI::CONFIG["second"]
          %}
          ASPEC.compile_time_assert(\{{ first_config["root_prop"] == "root" }}, "Expected first.root_prop to be root")
          ASPEC.compile_time_assert(\{{ first_config["nested"]["nested_prop"] == 42 }}, "Expected first.nested.nested_prop to be 42")
          ASPEC.compile_time_assert(\{{ second_config["other_prop"] == true }}, "Expected second.other_prop to be true")
          ASPEC.compile_time_assert(\{{ second_config["nested"] == nil }}, "Expected second to not have nested key")
        end
      end
    CR
  end
end
