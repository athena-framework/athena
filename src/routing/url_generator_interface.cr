# Interface for URL generation types.
#
# Implementors must define a `#generate` method that accepts the route name, any params, and what type of URL should be generated and return the URL string.
module Athena::Routing::URLGeneratorInterface
  # Represents the type of URLs that are able to be generated via an `ART::URLGeneratorInterface`.
  enum ReferenceType
    # Includes an absolute URL including protocol, hostname, and path: `https://api.example.com/add/10/5`.
    #
    # By default the `Host` header of the request is used as the hostname, with the scheme being `https`.
    # This can be customized via the `ART::Parameters#base_uri` parameter.
    #
    # !!!note
    #     If the `base_uri` parameter is not set, and there is no `Host` header, the generated URL will fallback on `Absolute_Path`.
    Absolute_URL

    # The default type, includes an absolute path from the root to the generated route: `/add/10/5`.
    Absolute_Path

    # TODO: Implement this.
    Relative_Path

    # Similar to `Absolute_URL`, but reuses the current protocol: `//api.example.com/add/10/5`.
    Network_Path
  end

  # Generates a URL to the provided *route* with the provided *params*.
  #
  # By default the path is an `ART::URLGeneratorInterface::ReferenceType::Absolute_Path`,
  # but can be changed via the *reference_type* argument.
  #
  # Any *params* not related to an argument for the provided *route* will be added as query params.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ART::Controller
  #   @[ARTA::Get("/add/:value1/:value2", name: "add")]
  #   def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
  #     0
  #   end
  #
  #   @[ARTA::Get("/")]
  #   def get_link : String
  #     ""
  #   end
  # end
  #
  # generator.generate "add", value1: 10, value2: 5 # => /add/10/5
  # ```
  abstract def generate(route : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
end
