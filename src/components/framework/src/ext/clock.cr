@[ADI::Register(name: "clock", alias: ACLK::Interface, factory: "create")]
class Athena::Clock
  # :nodoc:
  #
  # There a better way to handle this?
  # By default the `ACLK::Interface` causes some infinite recursion due to this service being aliased to the interface
  def self.create : self
    new
  end
end
