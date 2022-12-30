# Encompasses parameters related to the `Athena::Framework` component.
#
# For a higher level introduction to using parameters, see the [external documentation](/components/config).
struct Athena::Framework::Parameters
  # This method should be overridden in order to customize the parameters for the `Athena::Framework` component.
  # See the [external documentation](/components/config#parameters) for more details.
  #
  # ```
  # # Returns an `ATH::Parameters` instance with customized parameter values.
  # def ATH::Parameters.configure
  #   new(
  #     base_uri: "https://myapp.com",
  #   )
  # end
  # ```
  def self.configure : self
    new
  end

  # Returns an optional `URI` instance for use within `ART::Generator::Interface#generate`.
  getter base_uri : URI?

  def initialize(
    base_uri : URI | String | Nil = nil
  )
    @base_uri = base_uri.is_a?(String) ? URI.parse base_uri : base_uri

    @base_uri.try do |uri|
      raise ArgumentError.new "The base_uri must include a scheme." if uri.scheme.nil?
    end
  end

  struct Framework
    def self.configure : self
      new
    end

    # Returns `true` if the application was built without the `--release` flag, otherwise `false`.
    getter debug : Bool = {{!flag? :release}}
  end
end

class Athena::Config::Parameters
  getter routing : ATH::Parameters = ATH::Parameters.configure
  getter framework : ATH::Parameters::Framework = ATH::Parameters::Framework.configure
end

# Setup bindings for built in parameters.
ADI.bind base_uri : URI?, "%routing.base_uri%"
ADI.bind debug : Bool, "%framework.debug%"
