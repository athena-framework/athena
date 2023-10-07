# TODO: Clean this up once https://github.com/crystal-lang/crystal/issues/12965 is resolved
{% skip_file unless @top_level.has_constant?("Athena") && Athena.has_constant?("Clock") && Athena::Clock.has_constant?("Interface") %}

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
