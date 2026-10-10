@[ADI::Autoconfigure(tags: ["athena.resettable"])]
module Athena::Contracts::Service::Resettable; end

# :nodoc:
#
# Resets each `ACTR::Service::Resettable` service after each request made within a test.
@[ADI::Register(public: true, _resettables: "!athena.resettable")]
struct Athena::Framework::ServicesResetter
  def initialize(@resettables : Array(ACTR::Service::Resettable)); end

  def reset : Nil
    @resettables.each &.reset
  end
end
