require "spec"
require "../src/athena-dependency_injection"
# require "./service_mocks"

require "athena-spec"
require "../src/spec"

record DBConfig, username : String, password : String, host : String

@[ADI::RegisterExtension("blah")]
module ExampleExtension
  include ADI::Extension

  property id : Int32
  property float : Float64 = Math::PI
  property name : String = "fred"
end

ADI.configure({
  blah: {
    id: 123,
  },
  parameters: {
    "app.mapping": {
      10 => "%app.domain%",
      20 => "%app.placeholder%", # Resolves recursively out of order
    },
    "app.nested_mapping": {
      "string"       => "%app.domain%",
      "array"        => "%app.array%",
      "nested_array" => "%app.nested_array%",
      "bool"         => "%app.enable_v2_protocol%",
    },
    "app.nested_array": [
      "%app.array%",
      "%app.domain%",
    ],
    "app.array": [
      "%app.domain%",
      "%app.placeholder%",
      "%app.with_percent%",
      "%app.with_percent_placeholder%",
    ],
    "app.domain":                   "google.com",
    "app.with_percent":             "foo%%bar", # Escape `%`
    "app.with_percent_placeholder": "https://%app.domain%/path/t%%o/thing",
    "app.enable_v2_protocol":       false,
    "app.placeholder":              "https://%app.domain%/path/to/thing",
    "app.placeholders":             "https://%app.domain%/path/to/%app.enable_v2_protocol%",
  },
})
