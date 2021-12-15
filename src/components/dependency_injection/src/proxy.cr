# Represents a lazily initialized service.
# See the "Service Proxies" section within `ADI::Register`.
struct Athena::DependencyInjection::Proxy(O)
  forward_missing_to self.instance

  # :nodoc:
  delegate :==, :===, :=~, :hash, :tap, :not_nil!, :dup, :clone, :try, to: self.instance

  # Returns proxied service `O`; instantiating it if it has not already been.
  getter instance : O { @instantiated = true; @loader.call }

  # Returns the service ID (name) of the proxied service.
  getter service_id : String

  # Returns whether the proxied service has been instantiated yet.
  getter? instantiated : Bool = false

  def initialize(@service_id : String, @loader : Proc(O)); end

  # Returns the type of the proxied service.
  def service_type : O.class
    O
  end
end
