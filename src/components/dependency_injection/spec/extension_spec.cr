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

             raise "#{options}" unless options.size == 2

             raise "#{options}" unless options[0]["name"] == "id"
             raise "#{options}" unless options[0]["type"] == Int32
             raise "#{options}" unless options[0]["default"].nil?

             raise "#{options}" unless options[1]["name"] == "name"
             raise "#{options}" unless options[1]["type"] == String
             raise "#{options}" unless options[1]["default"] == "Fred"

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"id","type":"`Int32`","default":"``"}, {"name":"name","type":"`String`","default":"`Fred`"}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "values"
             raise "#{options}" unless options[0]["type"] == Array(Int32 | String)
             raise "#{options}" unless options[0]["default"].stringify == "Array(Int32 | String).new"

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"values","type":"`Array(Int32 | String)`","default":"`Array(Int32 | String).new`"}] of Nil)
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

               raise "#{config}" unless config["connection"]["username"] == "addminn"
               raise "#{config}" unless config["connection"]["password"] == "abc123"
               raise "#{config}" unless config["connection"]["port"] == 1234
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rule"
             raise "#{options}" unless options[0]["type"].stringify == "NamedTuple(T)"
             raise "#{options}" unless options[0]["default"].nil?

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"``","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rule"
             raise "#{options}" unless options[0]["type"].stringify == "NamedTuple(T)"
             raise "#{options}" unless options[0]["default"] == {id: 999, stop: false}

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`NamedTuple(T)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rule"
             raise "#{options}" unless options[0]["type"].stringify == "(NamedTuple(T) | Nil)"
             raise "#{options}" unless options[0]["default"].nil?

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rule"
             raise "#{options}" unless options[0]["type"].stringify == "(NamedTuple(T) | Nil)"
             raise "#{options}" unless options[0]["default"].nil?

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rules"
             raise "#{options}" unless options[0]["type"].stringify == "Array(T)"
             raise "#{options}" unless options[0]["default"].stringify == "[]"

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rules"
             raise "#{options}" unless options[0]["type"].stringify == "Array(T)"
             raise "#{options}" unless options[0]["default"] == [{id: 10, stop: false}]

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`Array(T)`","default":"`[{id: 10}]`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
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

             raise "#{options}" unless options.size == 1

             raise "#{options}" unless options[0]["name"] == "rules"
             raise "#{options}" unless options[0]["type"].stringify == "(Array(T) | Nil)"
             raise "#{options}" unless options[0]["default"].nil?

             members = options[0]["members"]
             raise "#{members}" unless members.size == 3 # Account for __nil

             raise "#{members}" unless members["id"].type.stringify == "Int32"
             raise "#{members}" unless members["id"].value.nil?
             raise "#{members}" unless members["stop"].type.stringify == "Bool"
             raise "#{members}" unless members["stop"].value == false

             raise "#{Schema::CONFIG_DOCS}" unless Schema::CONFIG_DOCS.stringify == %([{"name":"rules","type":"`(Array(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil)
            %}
          end
        end
      CR
    end
  end
end
