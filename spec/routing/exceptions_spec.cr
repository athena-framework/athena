require "./routing_spec_helper"

describe Athena::Routing::Exceptions do
  {% for exception, index in Athena::Routing::Exceptions::AthenaException.subclasses %}
    {% code = Athena::Routing::Exceptions::COMMON_EXCEPTIONS.keys[index] %}
    {% message = Athena::Routing::Exceptions::COMMON_EXCEPTIONS.values[index] %}

    describe {{code.id}} do
      it "should raise proper exception with proper default exception" do
        expect_raises {{exception.id}}, {{exception}} do
          raise {{exception.id}}.new 
       end
      end

      it "should raise proper custom error message" do
        expect_raises {{exception.id}}, "Error - {{code}}" do
          raise {{exception.id}}.new "Error - {{code}}"
        end
      end

      it "should serialize correctly" do
        e = {{exception.id}}.new
        e.to_json.should eq %({"code":{{code.id}},"message":{{message}}})
      end
    end
  {% end %}
end
