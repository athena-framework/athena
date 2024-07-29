require "./spec_helper"

private def assert_success(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_success <<-CR, codegen: true, line: line
    require "./spec_helper.cr"
    #{code}
    Schema.validate
  CR
end

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::Extension do
  it "happy path" do
    assert_success <<-CR
      module Schema
        include ADI::Extension::Schema
        property id : Int32
        property name : String = "Fred"
        def self.validate
          it do
            {{OPTIONS.size}}.should eq 2
            {{OPTIONS[0]["name"].stringify}}.should eq "id"
            {{OPTIONS[0]["type"].stringify}}.should eq "Int32"
            {{OPTIONS[0]["default"].stringify}}.should be_empty
            {{OPTIONS[1]["name"].stringify}}.should eq "name"
            {{OPTIONS[1]["type"].stringify}}.should eq "String"
            {{OPTIONS[1]["default"].stringify}}.should eq %("Fred")

            {{CONFIG_DOCS.stringify}}.should eq <<-JSON
            [{"name":"id","type":"`Int32`","default":"``"}, {"name":"name","type":"`String`","default":"`Fred`"}] of Nil
            JSON
          end
        end
      end
      ADI.register_extension "test", Schema
      ADI.configure({
        test: {
          id: 10,
        },
      })
    CR
  end

  it "allows using NoReturn array default to inherit type of the array" do
    assert_success <<-CR
      module Schema
        include ADI::Extension::Schema
        property values : Array(Int32 | String) = [] of NoReturn
        def self.validate
          it do
            {{OPTIONS.size}}.should eq 1
            {{OPTIONS[0]["name"].stringify}}.should eq "values"
            {{OPTIONS[0]["type"].stringify}}.should eq "Array(Int32 | String)"
            {{OPTIONS[0]["default"].stringify}}.should eq "Array(Int32 | String).new"

            {{CONFIG_DOCS.stringify}}.should eq <<-JSON
            [{"name":"values","type":"`Array(Int32 | String)`","default":"`Array(Int32 | String).new`"}] of Nil
            JSON
          end
        end
      end
      ADI.register_extension "test", Schema
    CR
  end

  describe "object_of / object_of?" do
    it "is able to resolve parameters from the object value" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          object_of connection, username : String, password : String, port : Int32 = 1234
          macro finished
            macro finished
              def self.validate
                it { \\{{ADI::CONFIG["test"]["connection"]["username"]}}.should eq "addminn" }
                it { \\{{ADI::CONFIG["test"]["connection"]["password"]}}.should eq "abc123" }
                it { \\{{ADI::CONFIG["test"]["connection"]["port"]}}.should eq 1234 }
              end
            end
          end
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
      CR
    end

    it "errors if a required configuration value has not been provided" do
      assert_error "Configuration value 'test.connection' is missing required value for 'port' of type 'Int32'.", <<-CR
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
      assert_error "Expected configuration value 'test.connection.port' to be a 'Int32', but got 'Bool'.", <<-CR
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
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          object_of rule, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rule"
              {{OPTIONS[0]["type"].stringify}}.should eq "NamedTuple(T)"
              {{OPTIONS[0]["default"].stringify}}.should eq ""
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rule","type":"`NamedTuple(T)`","default":"``","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
        ADI.configure({
          test: {
            rule: {
              id: 10
            },
          },
        })
      CR
    end

    it "object_of with assign" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          object_of rule = {id: 999}, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rule"
              {{OPTIONS[0]["type"].stringify}}.should eq "NamedTuple(T)"
              {{OPTIONS[0]["default"].stringify}}.should eq "{id: 999, stop: false}"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rule","type":"`NamedTuple(T)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end

    it "object_of?" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          object_of? rule, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rule"
              {{OPTIONS[0]["type"].stringify}}.should eq "(NamedTuple(T) | Nil)"
              {{OPTIONS[0]["default"].stringify}}.should eq "nil"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end

    it "object_of? with assign" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          object_of? rule = {id: 999}, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rule"
              {{OPTIONS[0]["type"].stringify}}.should eq "(NamedTuple(T) | Nil)"
              {{OPTIONS[0]["default"].stringify}}.should eq "nil"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rule","type":"`(NamedTuple(T) | Nil)`","default":"`{id: 999}`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end
  end

  describe "array_of / array_of?" do
    it "array_of" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          array_of rules, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rules"
              {{OPTIONS[0]["type"].stringify}}.should eq "Array(T)"
              {{OPTIONS[0]["default"].stringify}}.should eq "[]"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end

    it "array_of with assign" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          array_of rules = [{id: 10}], id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rules"
              {{OPTIONS[0]["type"].stringify}}.should eq "Array(T)"
              {{OPTIONS[0]["default"].stringify}}.should eq "[{id: 10, stop: false}]"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rules","type":"`Array(T)`","default":"`[{id: 10}]`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end

    it "array_of?" do
      assert_success <<-CR
        module Schema
          include ADI::Extension::Schema
          array_of? rules, id : Int32, stop : Bool = false
          def self.validate
            it do
              {{OPTIONS.size}}.should eq 1
              {{OPTIONS[0]["name"].stringify}}.should eq "rules"
              {{OPTIONS[0]["type"].stringify}}.should eq "(Array(T) | Nil)"
              {{OPTIONS[0]["default"].stringify}}.should eq "nil"
              {{OPTIONS[0]["members"].size}}.should eq 3 # Account for __nil
              {{OPTIONS[0]["members"]["id"].type.stringify}}.should eq "Int32"
              {{OPTIONS[0]["members"]["id"].value.stringify}}.should eq ""
              {{OPTIONS[0]["members"]["stop"].type.stringify}}.should eq "Bool"
              {{OPTIONS[0]["members"]["stop"].value.stringify}}.should eq "false"

              {{CONFIG_DOCS.stringify}}.should eq <<-JSON
              [{"name":"rules","type":"`(Array(T) | Nil)`","default":"`nil`","members":[{"name":"id","type":"`Int32`","default":"``","doc":""},{"name":"stop","type":"`Bool`","default":"`false`","doc":""}]}] of Nil
              JSON
            end
          end
        end
        ADI.register_extension "test", Schema
      CR
    end
  end
end
