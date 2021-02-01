# Encompasses parameters related to the `Athena::Routing` component.
#
# For a higher level introduction to using parameters, see the [external documentation](/components/config).
struct Athena::Routing::Parameters
  # This method should be overridden in order to customize the parameters for the `Athena::Routing` component.
  # See the [external documentation](/components/config#parameters) for more details.
  #
  # ```
  # # Returns an `ART::Parameters` instance with customized parameter values.
  # def ART::Parameters.configure
  #   new(
  #     base_uri: "https://myapp.com",
  #   )
  # end
  # ```
  def self.configure : self
    new
  end

  # Returns an optional `URI` instance that should be used for within `ART::URLGeneratorInterface#generate`.
  getter base_uri : URI?

  def initialize(
    base_uri : URI | String | Nil = nil
  )
    @base_uri = base_uri.is_a?(String) ? URI.parse base_uri : base_uri

    @base_uri.try do |uri|
      raise ArgumentError.new "The base_uri must include a scheme." if uri.scheme.nil?
    end
  end
end

class Athena::Config::Parameters
  getter routing : ART::Parameters = ART::Parameters.configure
end

# Setup bindings for built in parameters.
ADI.bind base_uri : URI?, "%routing.base_uri%"
