require "athena-spec"
require "athena-dependency_injection/spec"
require "./spec/*"

# :nodoc:
#
# Monkey patch HTTP::Server::Response to allow accessing the response body directly and string representation of it.
class HTTP::Server::Response
  @body_io : IO = IO::Memory.new
  @body : String? = nil

  def write(slice : Bytes) : Nil
    @body_io.write slice

    previous_def
  end

  def body : String
    @body ||= @body_io.to_s
  end

  def to_s(io : IO) : Nil
    io << @version << ' ' << self.status_code << ' ' << @status.description << '\n' << '\n'
    HTTP.serialize_headers_and_string_body io, @headers, self.body
  end
end

# A set of testing utilities/types to aid in testing `Athena::Framework` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec" and "athena-spec".
# require "athena/spec"
# ```
#
# Add `Athena::Spec` as a development dependency, then run a `shards install`.
# See the individual types for more information.
module Athena::Framework::Spec
  module Expectations
  end
end
