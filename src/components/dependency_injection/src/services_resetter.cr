@[Athena::DependencyInjection::Autoconfigure(tags: ["athena.resettable"])]
module Athena::Contracts::Service::Resettable; end

# :nodoc:
#
# Resets each `ACTR::Service::Resettable` service between units of work sharing a container, such as the requests made within a test.
@[Athena::DependencyInjection::Register(public: true, _resettables: "!athena.resettable")]
struct Athena::DependencyInjection::ServicesResetter
  def initialize(@resettables : Array(ACTR::Service::Resettable)); end

  def reset : Nil
    @resettables.each &.reset
  end
end
