require "spec"
require "../src/athena-dependency_injection"
require "./service_mocks"

require "athena-spec"
require "../src/spec"

record DBConfig, username : String, password : String, host : String

class ACF::Parameters
  getter db : DBConfig = DBConfig.new "USER", "PASS", "HOST"
end
