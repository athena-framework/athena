require "./routing_spec_helper"

do_with_config do |client|
  describe Athena::Routing::Exceptions do
    describe Athena::Routing::Exceptions::AthenaException do
      {% for exception, index in Athena::Routing::Exceptions::AthenaException.subclasses %}
    {% code = Athena::Routing::Exceptions::COMMON_EXCEPTIONS.keys[index] %}
    {% message = Athena::Routing::Exceptions::COMMON_EXCEPTIONS.values[index] %}

    describe {{code.id}} do
      it "should raise proper exception with proper default exception" do
        expect_raises {{exception.id}}, {{message}} do
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

    describe ".handle_exception" do
      describe "for a controller that has a custom handler defined" do
        context "that handles the given error" do
          it "should use that handler" do
            response = client.get("/exception/custom")
            response.status_code.should eq 666
            response.body.should eq %({"code": 666, "message": "Division by 0"})
          end
        end

        context "that does not handle the given error" do
          it "should use use the default handler" do
            response = client.get("/exception/no_match")
            response.status_code.should eq 500
            response.body.should eq %({"code": 500, "message": "Internal Server Error"})
          end
        end
      end

      describe "for a controller that does not have custom handler defined" do
        it "should use use the default handler" do
          response = client.get("/exception/default")
          response.status_code.should eq 500
          response.body.should eq %({"code": 500, "message": "Internal Server Error"})
        end
      end
    end
  end
end
