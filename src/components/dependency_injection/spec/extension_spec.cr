require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line - 1 # Account for spec_helper require
    require "./spec_helper.cr"
    #{code}
  CR
end

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line - 1 # Account for spec_helper require
    require "./spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::Extension, tags: "compiled" do
  it "happy path" do
    assert_compiles <<-'CR'
      module Schema
        include ADI::Extension::Schema
        property id : Int32
        property name : String = "Fred"
      end

      ADI.register_extension "test", Schema
      ADI.configure({
        test: {
          id: 10,
        },
      })

      macro finished
        macro finished
          \{%
             options = Schema::OPTIONS
          %}
          ASPEC.compile_time_assert(\{{ options.size == 2 }}, "Expected options size to be 2")
          ASPEC.compile_time_assert(\{{ options[0]["name"] == "id" }}, "Expected first option name to be id")
          ASPEC.compile_time_assert(\{{ options[0]["type"] == Int32 }}, "Expected first option type to be Int32")
          ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected first option default to be nil")
          ASPEC.compile_time_assert(\{{ options[1]["name"] == "name" }}, "Expected second option name to be name")
          ASPEC.compile_time_assert(\{{ options[1]["type"] == String }}, "Expected second option type to be String")
          ASPEC.compile_time_assert(\{{ options[1]["default"] == "Fred" }}, "Expected second option default to be Fred")
          ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"id","type":"`Int32`","default":"``"}, {"name":"name","type":"`String`","default":"`Fred`"}] of Nil) }}, "Expected CONFIG_DOCS to match")
        end
      end
    CR
  end

  it "allows using NoReturn array default to inherit type of the array" do
    assert_compiles <<-'CR'
      module Schema
        include ADI::Extension::Schema
        property values : Array(Int32 | String) = [] of NoReturn
      end

      ADI.register_extension "test", Schema

      macro finished
        macro finished
          \{%
             options = Schema::OPTIONS
          %}
          ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
          ASPEC.compile_time_assert(\{{ options[0]["name"] == "values" }}, "Expected option name to be values")
          ASPEC.compile_time_assert(\{{ options[0]["type"] == Array(Int32 | String) }}, "Expected option type to be Array(Int32 | String)")
          ASPEC.compile_time_assert(\{{ options[0]["default"].stringify == "Array(Int32 | String).new" }}, "Expected option default to be Array(Int32 | String).new")
          ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"values","type":"`Array(Int32 | String)`","default":"`Array(Int32 | String).new`"}] of Nil) }}, "Expected CONFIG_DOCS to match")
        end
      end
    CR
  end

  describe "object_of / object_of?" do
    it "is able to resolve parameters from the object value" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          object_of connection, username : String, password : String, port : Int32 = 1234
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              username: "%app.username%",
              password: "abc123",
            },
          },
          parameters: {
            "app.username": "addminn",
          },
        })

        macro finished
          macro finished
            \{%
               config = ADI::CONFIG["test"]
            %}
            ASPEC.compile_time_assert(\{{ config["connection"]["username"] == "addminn" }}, "Expected connection username to be addminn")
            ASPEC.compile_time_assert(\{{ config["connection"]["password"] == "abc123" }}, "Expected connection password to be abc123")
            ASPEC.compile_time_assert(\{{ config["connection"]["port"] == 1234 }}, "Expected connection port to be 1234")
          end
        end
      CR
    end

    it "errors if a required configuration value has not been provided" do
      assert_compile_time_error "Configuration value 'test.connection' is missing required value for 'port' of type 'Int32'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_of connection, username : String, password : String, port : Int32
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              username: "admin",
              password: "abc123",
            },
          },
        })
      CR
    end

    it "errors if a configuration value has been provided a value of the wrong type" do
      assert_compile_time_error "Expected configuration value 'test.connection.port' to be a 'Int32', but got 'Bool'.", <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_of connection, username : String, password : String, port : Int32
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            connection: {
              username: "admin",
              password: "abc123",
              port: false,
            },
          },
        })
      CR
    end

    it "object_of" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          object_of rule, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        ADI.configure({
          test: {
            rule: {
              id: 10
            },
          },
        })

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rule" }}, "Expected option name to be rule")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "NamedTuple(T)" }}, "Expected option type to be NamedTuple(T)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected option default to be nil")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"``","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "object_of with assign" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          object_of rule = {id: 999}, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rule" }}, "Expected option name to be rule")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "NamedTuple(T)" }}, "Expected option type to be NamedTuple(T)")
            ASPEC.compile_time_assert(\{{ options[0]["default"] == {id: 999, stop: false} }}, "Expected option default to match")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "object_of?" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          object_of? rule, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rule" }}, "Expected option name to be rule")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "(NamedTuple(T) | Nil)" }}, "Expected option type to be (NamedTuple(T) | Nil)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected option default to be nil")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "object_of? with assign" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          object_of? rule = {id: 999}, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rule" }}, "Expected option name to be rule")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "(NamedTuple(T) | Nil)" }}, "Expected option type to be (NamedTuple(T) | Nil)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected option default to be nil")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end
  end

  describe "array_of / array_of?" do
    it "array_of" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          array_of rules, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rules" }}, "Expected option name to be rules")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "Array(T)" }}, "Expected option type to be Array(T)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].stringify == "[]" }}, "Expected option default to be empty array")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
          end
        end
      CR
    end

    it "array_of with assign" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          array_of rules = [{id: 10}], id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rules" }}, "Expected option name to be rules")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "Array(T)" }}, "Expected option type to be Array(T)")
            ASPEC.compile_time_assert(\{{ options[0]["default"] == [{id: 10, stop: false}] }}, "Expected option default to match")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`Array(T)`","default":"`[{id: 10}]`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "array_of?" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          array_of? rules, id : Int32, stop : Bool = false
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
             options = Schema::OPTIONS
             members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "rules" }}, "Expected option name to be rules")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "(Array(T) | Nil)" }}, "Expected option type to be (Array(T) | Nil)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected option default to be nil")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["id"].type.stringify == "Int32" }}, "Expected id type to be Int32")
            ASPEC.compile_time_assert(\{{ members["id"].value.nil? }}, "Expected id value to be nil")
            ASPEC.compile_time_assert(\{{ members["stop"].type.stringify == "Bool" }}, "Expected stop type to be Bool")
            ASPEC.compile_time_assert(\{{ members["stop"].value == false }}, "Expected stop value to be false")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`(Array(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end
  end

  describe "object_schema" do
    it "stores schema in OBJECT_SCHEMAS" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               schemas = Schema::OBJECT_SCHEMAS
               jwt_schema = schemas["JwtConfig"]
            %}
            ASPEC.compile_time_assert(\{{ schemas.size == 1 }}, "Expected schemas size to be 1")
            ASPEC.compile_time_assert(\{{ schemas["JwtConfig"] != nil }}, "Expected JwtConfig schema to exist")
            ASPEC.compile_time_assert(\{{ jwt_schema["members"].size == 3 }}, "Expected jwt_schema members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ jwt_schema["members"]["secret"].type.stringify == "String" }}, "Expected secret type to be String")
            ASPEC.compile_time_assert(\{{ jwt_schema["members"]["secret"].value.nil? }}, "Expected secret value to be nil")
            ASPEC.compile_time_assert(\{{ jwt_schema["members"]["algorithm"].type.stringify == "String" }}, "Expected algorithm type to be String")
            ASPEC.compile_time_assert(\{{ jwt_schema["members"]["algorithm"].value == "hmac.sha256" }}, "Expected algorithm value to be hmac.sha256")
          end
        end
      CR
    end

    it "supports nested object_schema references" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema InnerConfig,
            value : String

          object_schema OuterConfig,
            name : String,
            inner : InnerConfig
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               schemas = Schema::OBJECT_SCHEMAS
               outer_schema = schemas["OuterConfig"]
               inner_member = outer_schema["members"]["inner"]
            %}
            # The inner member should have nested members from InnerConfig
            ASPEC.compile_time_assert(\{{ inner_member["members"] != nil }}, "Expected inner member to have members")
            ASPEC.compile_time_assert(\{{ inner_member["members"]["value"].type.stringify == "String" }}, "Expected inner value type to be String")
            # OuterConfig's members_string should include InnerConfig's nested members
            ASPEC.compile_time_assert(\{{ outer_schema["members_string"] == %([{"name":"name","type":"`String`","default":"``","doc":""},{"name":"inner","type":"`InnerConfig`","default":"``","doc":"","members":[{"name":"value","type":"`String`","default":"``","doc":""}]}]) }}, "Expected members_string to match")
          end
        end
      CR
    end
  end

  describe "map_of / map_of?" do
    it "map_of" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of hubs, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "hubs" }}, "Expected option name to be hubs")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "Hash(K, V)" }}, "Expected option type to be Hash(K, V)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].stringify == "{__nil: nil}" }}, "Expected option default to be {__nil: nil}")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["url"].type.stringify == "String" }}, "Expected url type to be String")
            ASPEC.compile_time_assert(\{{ members["url"].value.nil? }}, "Expected url value to be nil")
            ASPEC.compile_time_assert(\{{ members["port"].type.stringify == "Int32" }}, "Expected port type to be Int32")
            ASPEC.compile_time_assert(\{{ members["port"].value == 5432 }}, "Expected port value to be 5432")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`Hash(K, V)`","default":"`{__nil: nil}`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"port","type":"`Int32`","default":"`5432`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "map_of?" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of? hubs, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               members = options[0]["members"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "hubs" }}, "Expected option name to be hubs")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "(Hash(K, V) | Nil)" }}, "Expected option type to be (Hash(K, V) | Nil)")
            ASPEC.compile_time_assert(\{{ options[0]["default"].nil? }}, "Expected option default to be nil")
            ASPEC.compile_time_assert(\{{ members.size == 3 }}, "Expected members size to be 3") # Account for __nil
            ASPEC.compile_time_assert(\{{ members["url"].type.stringify == "String" }}, "Expected url type to be String")
            ASPEC.compile_time_assert(\{{ members["port"].type.stringify == "Int32" }}, "Expected port type to be Int32")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`(Hash(K, V) | Nil)`","default":"`nil`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"port","type":"`Int32`","default":"`5432`","doc":""}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "map_of with object_schema reference" do
      assert_compiles <<-'CR'
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

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               jwt_member = options[0]["members"]["jwt"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ jwt_member["members"] != nil }}, "Expected jwt member to have members")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["secret"].type.stringify == "String" }}, "Expected secret type to be String")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["algorithm"].value == "hmac.sha256" }}, "Expected algorithm value to be hmac.sha256")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`Hash(K, V)`","default":"`{__nil: nil}`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end

    it "map_of with custom default using assignment syntax" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema
          map_of hubs = {default: {url: "localhost", port: 8080}}, url : String, port : Int32 = 5432
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               default = options[0]["default"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ options[0]["name"] == "hubs" }}, "Expected option name to be hubs")
            ASPEC.compile_time_assert(\{{ options[0]["type"].stringify == "Hash(K, V)" }}, "Expected option type to be Hash(K, V)")
            # Custom default should be preserved
            ASPEC.compile_time_assert(\{{ default["default"]["url"] == "localhost" }}, "Expected default url to be localhost")
            ASPEC.compile_time_assert(\{{ default["default"]["port"] == 8080 }}, "Expected default port to be 8080")
          end
        end
      CR
    end
  end

  describe "object_schema in array_of" do
    it "array_of with object_schema reference" do
      assert_compiles <<-'CR'
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

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               jwt_member = options[0]["members"]["jwt"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ jwt_member["members"] != nil }}, "Expected jwt member to have members")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["secret"].type.stringify == "String" }}, "Expected secret type to be String")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["algorithm"].value == "hmac.sha256" }}, "Expected algorithm value to be hmac.sha256")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"items","type":"`Array(T)`","default":"`[]`","members":[{"name":"name","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end
  end

  describe "object_schema in object_of" do
    it "object_of with object_schema reference" do
      assert_compiles <<-'CR'
        module Schema
          include ADI::Extension::Schema

          object_schema JwtConfig,
            secret : String,
            algorithm : String = "hmac.sha256"

          # Use object_of? since we're not providing config - just testing OPTIONS structure
          object_of? connection,
            url : String,
            jwt : JwtConfig
        end

        ADI.register_extension "test", Schema

        macro finished
          macro finished
            \{%
               options = Schema::OPTIONS
               jwt_member = options[0]["members"]["jwt"]
            %}
            ASPEC.compile_time_assert(\{{ options.size == 1 }}, "Expected options size to be 1")
            ASPEC.compile_time_assert(\{{ jwt_member["members"] != nil }}, "Expected jwt member to have members")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["secret"].type.stringify == "String" }}, "Expected secret type to be String")
            ASPEC.compile_time_assert(\{{ jwt_member["members"]["algorithm"].value == "hmac.sha256" }}, "Expected algorithm value to be hmac.sha256")
            ASPEC.compile_time_assert(\{{ Schema::CONFIG_DOCS.stringify == %([{"name":"connection","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil) }}, "Expected CONFIG_DOCS to match")
          end
        end
      CR
    end
  end
end
