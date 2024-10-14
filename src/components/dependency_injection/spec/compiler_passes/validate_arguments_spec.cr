require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::ValidateArguments, tags: "compiled" do
  describe "compiler errors" do
    it "errors if a expects a string value parameter but it is not of that type" do
      assert_error "Parameter 'value : String' of service 'foo' (Foo) expects a String but got '123'.", <<-'CR'
        @[ADI::Register(_value: "%value%")]
        record Foo, value : String

        ADI.configure({
          parameters: {
            value: 123
          }
        })
      CR
    end

    it "errors if a parameter resolves to a service of the incorrect type" do
      assert_error "Parameter 'value : Int32' of service 'foo' (Foo) expects 'Int32' but the resolved service 'bar' is of type 'Bar'.", <<-'CR'
        @[ADI::Register]
        record Bar

        @[ADI::Register(_value: "@bar", public: true)]
        record Foo, value : Int32
      CR
    end

    describe NamedTuple do
      it "errors if configuration is missing a non-nilable property" do
        assert_error "Configuration value 'test.connection' is missing required value for 'port' of type 'Int32'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema

            property connection : NamedTuple(hostname: String, username: String, password: String, port: Int32)
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              connection: {
                hostname: "my-db",
                username: "user",
                password: "pass",
              },
            },
          })
        CR
      end

      it "errors if there is a type mismatch" do
        assert_error "Expected configuration value 'test.connection.hostname' to be a 'String', but got 'Int32'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema
            property connection : NamedTuple(hostname: String)
          end
          ADI.register_extension "test", Schema
          ADI.configure({
            test: {
              connection: {
                hostname: 10,
              },
            },
          })
        CR
      end

      it "errors if there is a type mismatch within an array type" do
        assert_error "Expected configuration value 'test.connection.ports[1]' to be a 'Int32', but got 'String'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema
            property connection : NamedTuple(ports: Array(Int32))
          end
          ADI.register_extension "test", Schema
          ADI.configure({
            test: {
              connection: {
                ports: [
                  10,
                  "blah"
                ]
              },
            },
          })
        CR
      end

      it "errors if there is a type mismatch within a nilable array type" do
        assert_error "Expected configuration value 'test.connection.ports[1]' to be a 'Int32', but got 'String'.", <<-'CR'
          module Schema
            include ADI::Extension::Schema
            property connection : NamedTuple(ports: Array(Int32)?)
          end
          ADI.register_extension "test", Schema
          ADI.configure({
            test: {
              connection: {
                ports: [
                  10,
                  "blah"
                ]
              },
            },
          })
        CR
      end
    end

    describe "array_of" do
      it "errors on type mismatch in array within array_of object" do
        assert_error "Expected configuration value 'test.rules[0].priorities[2]' to be a 'String', but got 'Int32'.", <<-'CR'
          require "../spec_helper"

          module Schema
            include ADI::Extension::Schema

            array_of rules,
              priorities : Array(String)? = nil
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              rules: [
                {priorities: ["json", "xml", 2]},
              ],
            },
          })
        CR
      end
    end

    describe "object_of" do
      it "errors on type mismatch in array within object_of object" do
        assert_error "Expected configuration value 'test.rule.priorities[2]' to be a 'String', but got 'Int32'.", <<-'CR'
          require "../spec_helper"

          module Schema
            include ADI::Extension::Schema

            object_of rule, priorities : Array(String)? = nil
          end

          ADI.register_extension "test", Schema

          ADI.configure({
            test: {
              rule: {priorities: ["json", "xml", 2]},
            },
          })
        CR
      end
    end
  end

  it "sets missing NT keys to `nil` if the type is nilable" do
    ASPEC::Methods.assert_success <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property connection : NamedTuple(hostname: String, username: String, password: String, port: Int32?)
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          connection: {
            hostname: "my-db",
            username: "user",
            password: "pass",
          },
        },
      })

      macro finished
        macro finished
          \{% raise "" unless ADI::CONFIG["test"]["connection"]["port"].nil? %}
        end
      end
    CR
  end

  it "properly checks type within array of array_of object" do
    ASPEC::Methods.assert_success <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        array_of rules,
          priorities : Array(String)? = nil
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          rules: [
            {priorities: ["json", "xml"]},
          ],
        },
      })
    CR
  end

  it "properly checks type within array of object_of object" do
    ASPEC::Methods.assert_success <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        object_of rule, priorities : Array(String)? = nil
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          rule: {priorities: ["json", "xml"]},
        },
      })
    CR
  end
end
