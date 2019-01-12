require "spec"
require "logger"

require "../../src/cli"
require "./commands/*"

struct SpecHelper
  class_property logger : Logger = Logger.new nil
end
