@[Athena::DependencyInjection::Autoconfigure(tags: ["athena.closeable"])]
module Athena::Contracts::Service::Closeable; end

# :nodoc:
#
# Closes each `ACTR::Service::Closeable` service once a unit of work, such as a request, is done.
@[Athena::DependencyInjection::Register(public: true, _closeables: "!athena.closeable")]
struct Athena::DependencyInjection::ServicesCloser
  def initialize(@closeables : Array(ACTR::Service::Closeable)); end

  def close : Nil
    @closeables.each &.close
  end
end
