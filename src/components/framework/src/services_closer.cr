@[ADI::Autoconfigure(tags: ["athena.closeable"])]
module Athena::Contracts::Service::Closeable; end

# :nodoc:
#
# Closes each `ACTR::Service::Closeable` service once a request is done.
@[ADI::Register(public: true, _closeables: "!athena.closeable")]
struct Athena::Framework::ServicesCloser
  def initialize(@closeables : Array(ACTR::Service::Closeable)); end

  def close : Nil
    @closeables.each &.close
  end
end
