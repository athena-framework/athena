# Encompasses parameters related to the `Athena::Routing` component.
#
# For a higher level introduction to parameters see the [external documentation](/components/config#parameters).
struct Athena::Routing::Parameters
  def self.configure : self
    new
  end

  getter base_uri : String = ""
end

class Athena::Config::Parameters
  getter routing : ART::Parameters = ART::Parameters.configure
end

# Setup a binding for base_uri, since it's a built in parameter.
ADI.bind base_uri : String, "%routing.base_uri%"
