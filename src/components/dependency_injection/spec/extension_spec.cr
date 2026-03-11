require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
  CR
end

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
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

             unless options.size == 2
               raise "#{options}"
             end

             unless options[0]["name"] == "id"
               raise "#{options}"
             end

             unless options[0]["type"] == Int32
               raise "#{options}"
             end

             unless options[0]["default"].nil?
               raise "#{options}"
             end

             unless options[1]["name"] == "name"
               raise "#{options}"
             end

             unless options[1]["type"] == String
               raise "#{options}"
             end

             unless options[1]["default"] == "Fred"
               raise "#{options}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"id","type":"`Int32`","default":"``"}, {"name":"name","type":"`String`","default":"`Fred`"}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
          %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "values"
               raise "#{options}"
             end

             unless options[0]["type"] == Array(Int32 | String)
               raise "#{options}"
             end

             unless options[0]["default"].stringify == "Array(Int32 | String).new"
               raise "#{options}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"values","type":"`Array(Int32 | String)`","default":"`Array(Int32 | String).new`"}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
          %}
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

               unless config["connection"]["username"] == "addminn"
                 raise "#{config}"
               end

               unless config["connection"]["password"] == "abc123"
                 raise "#{config}"
               end

               unless config["connection"]["port"] == 1234
                 raise "#{config}"
               end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rule"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "NamedTuple(T)"
               raise "#{options}"
             end

             unless options[0]["default"].nil?
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"``","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rule"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "NamedTuple(T)"
               raise "#{options}"
             end

             unless options[0]["default"] == {id: 999, stop: false}
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rule"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "(NamedTuple(T) | Nil)"
               raise "#{options}"
             end

             unless options[0]["default"].nil?
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rule"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "(NamedTuple(T) | Nil)"
               raise "#{options}"
             end

             unless options[0]["default"].nil?
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rules"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "Array(T)"
               raise "#{options}"
             end

             unless options[0]["default"].stringify == "[]"
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rules"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "Array(T)"
               raise "#{options}"
             end

             unless options[0]["default"] == [{id: 10, stop: false}]
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`Array(T)`","default":"`[{id: 10}]`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

             unless options.size == 1
               raise "#{options}"
             end

             unless options[0]["name"] == "rules"
               raise "#{options}"
             end

             unless options[0]["type"].stringify == "(Array(T) | Nil)"
               raise "#{options}"
             end

             unless options[0]["default"].nil?
               raise "#{options}"
             end

             members = options[0]["members"]
             unless members.size == 3 # Account for __nil
               raise "#{members}"
             end

             unless members["id"].type.stringify == "Int32"
               raise "#{members}"
             end

             unless members["id"].value.nil?
               raise "#{members}"
             end

             unless members["stop"].type.stringify == "Bool"
               raise "#{members}"
             end

             unless members["stop"].value == false
               raise "#{members}"
             end

             unless Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`(Array(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
               raise "#{Schema::CONFIG_DOCS}"
             end
            %}
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

               unless schemas.size == 1
                 raise "#{schemas}"
               end

               unless schemas["JwtConfig"] != nil
                 raise "#{schemas}"
               end

               jwt_schema = schemas["JwtConfig"]
               unless jwt_schema["members"].size == 3 # Account for __nil
                 raise "#{jwt_schema}"
               end

               unless jwt_schema["members"]["secret"].type.stringify == "String"
                 raise "#{jwt_schema}"
               end

               unless jwt_schema["members"]["secret"].value.nil?
                 raise "#{jwt_schema}"
               end

               unless jwt_schema["members"]["algorithm"].type.stringify == "String"
                 raise "#{jwt_schema}"
               end

               unless jwt_schema["members"]["algorithm"].value == "hmac.sha256"
                 raise "#{jwt_schema}"
               end
            %}
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

               # The inner member should have nested members from InnerConfig
               inner_member = outer_schema["members"]["inner"]
               unless inner_member["members"] != nil
                 raise "#{inner_member}"
               end

               unless inner_member["members"]["value"].type.stringify == "String"
                 raise "#{inner_member}"
               end

               # OuterConfig's members_string should include InnerConfig's nested members
               unless outer_schema["members_string"] == %([{"name":"name","type":"`String`","default":"``","doc":""},{"name":"inner","type":"`InnerConfig`","default":"``","doc":"","members":[{"name":"value","type":"`String`","default":"``","doc":""}]}])
                 raise "#{outer_schema["members_string"]}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               unless options[0]["name"] == "hubs"
                 raise "#{options}"
               end

               unless options[0]["type"].stringify == "Hash(K, V)"
                 raise "#{options}"
               end

               unless options[0]["default"].stringify == "{__nil: nil}"
                 raise "#{options}"
               end

               members = options[0]["members"]
               unless members.size == 3 # Account for __nil
                 raise "#{members}"
               end

               unless members["url"].type.stringify == "String"
                 raise "#{members}"
               end

               unless members["url"].value.nil?
                 raise "#{members}"
               end

               unless members["port"].type.stringify == "Int32"
                 raise "#{members}"
               end

               unless members["port"].value == 5432
                 raise "#{members}"
               end

               unless Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`Hash(K, V)`","default":"`{__nil: nil}`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"port","type":"`Int32`","default":"`5432`","doc":""}]}] of Nil)
                 raise "#{Schema::CONFIG_DOCS}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               unless options[0]["name"] == "hubs"
                 raise "#{options}"
               end

               unless options[0]["type"].stringify == "(Hash(K, V) | Nil)"
                 raise "#{options}"
               end

               unless options[0]["default"].nil?
                 raise "#{options}"
               end

               members = options[0]["members"]
               unless members.size == 3 # Account for __nil
                 raise "#{members}"
               end

               unless members["url"].type.stringify == "String"
                 raise "#{members}"
               end

               unless members["port"].type.stringify == "Int32"
                 raise "#{members}"
               end

               unless Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`(Hash(K, V) | Nil)`","default":"`nil`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"port","type":"`Int32`","default":"`5432`","doc":""}]}] of Nil)
                 raise "#{Schema::CONFIG_DOCS}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               jwt_member = options[0]["members"]["jwt"]
               unless jwt_member["members"] != nil
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["secret"].type.stringify == "String"
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["algorithm"].value == "hmac.sha256"
                 raise "#{jwt_member}"
               end

               unless Schema::CONFIG_DOCS.stringify == %([{"name":"hubs","type":"`Hash(K, V)`","default":"`{__nil: nil}`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil)
                 raise "#{Schema::CONFIG_DOCS}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               unless options[0]["name"] == "hubs"
                 raise "#{options}"
               end

               unless options[0]["type"].stringify == "Hash(K, V)"
                 raise "#{options}"
               end

               # Custom default should be preserved
               default = options[0]["default"]
               unless default["default"]["url"] == "localhost"
                 raise "#{default}"
               end

               unless default["default"]["port"] == 8080
                 raise "#{default}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               jwt_member = options[0]["members"]["jwt"]
               unless jwt_member["members"] != nil
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["secret"].type.stringify == "String"
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["algorithm"].value == "hmac.sha256"
                 raise "#{jwt_member}"
               end

               unless Schema::CONFIG_DOCS.stringify == %([{"name":"items","type":"`Array(T)`","default":"`[]`","members":[{"name":"name","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil)
                 raise "#{Schema::CONFIG_DOCS}"
               end
            %}
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

               unless options.size == 1
                 raise "#{options}"
               end

               jwt_member = options[0]["members"]["jwt"]
               unless jwt_member["members"] != nil
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["secret"].type.stringify == "String"
                 raise "#{jwt_member}"
               end

               unless jwt_member["members"]["algorithm"].value == "hmac.sha256"
                 raise "#{jwt_member}"
               end

               unless Schema::CONFIG_DOCS.stringify == %([{"name":"connection","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"url","type":"`String`","default":"``","doc":""},{"name":"jwt","type":"`JwtConfig`","default":"``","doc":"","members":[{"name":"secret","type":"`String`","default":"``","doc":""},{"name":"algorithm","type":"`String`","default":"`hmac.sha256`","doc":""}]}]}] of Nil)
                 raise "#{Schema::CONFIG_DOCS}"
               end
            %}
          end
        end
      CR
    end
  end
end
