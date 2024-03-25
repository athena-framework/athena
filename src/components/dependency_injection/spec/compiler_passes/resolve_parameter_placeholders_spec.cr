require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::ResolveParameterPlaceholders do
  describe "compiler errors", tags: "compiled" do
    it "errors if a parameter references another undefined placeholder." do
      assert_error "Parameter 'parameters[app.name]' referenced unknown parameter 'app.version'.", <<-CR
        ADI.configure({
          parameters: {
            "app.name": "Testing v%app.version%"
          }
        })
      CR
    end

    it "errors if a parameter references another undefined placeholder within a hash." do
      assert_error "Parameter 'parameters[app.settings][\"thing\"]' referenced unknown parameter 'app.name'.", <<-CR
        ADI.configure({
          parameters: {
            "app.settings": {
              "thing" => "%app.name%",
            }
          }
        })
      CR
    end

    it "errors if a parameter references another undefined placeholder within an array." do
      assert_error "Parameter 'parameters[app.settings][0]' referenced unknown parameter 'app.name'.", <<-CR
        ADI.configure({
          parameters: {
            "app.settings": ["%app.name%"]
          }
        })
      CR
    end
  end
end
