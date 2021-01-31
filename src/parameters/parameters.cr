# Encompasses parameters related to the `Athena::Routing` component.
#
# For a higher level introduction to parameters see the [external documentation](/components/config#parameters).
struct Athena::Routing::Parameters
  def self.configure : self
    new
  end

  getter base_uri : URI?

  def initialize(
    base_uri : URI | String | Nil = nil
  )
    @base_uri = case base_uri
                when String then URI.parse base_uri
                else             base_uri
                end

    @base_uri.try do |uri|
      raise ArgumentError.new "The base_uri must include a scheme." if uri.scheme.nil?
    end
  end
end

class Athena::Config::Parameters
  getter routing : ART::Parameters = ART::Parameters.configure
end

# Setup a binding for base_uri, since it's a built in parameter.
ADI.bind base_uri : URI?, "%routing.base_uri%"
