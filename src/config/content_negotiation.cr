require "./config"

struct Athena::Routing::Config
  @[ACFA::Resolvable("routing.content_negotiation")]
  # Configuration options for `ART::Listeners::Format`.  See `.configure`.
  struct ContentNegotiation
    struct Rule
      # Returns the a `Regex` representing the paths this rule should be scoped to.
      getter path : Regex

      # Returns the formats that should be considered for this set of routes.
      # Must contain at least one format.
      getter priorities : Array(String)?

      # Returns the format that should be used if a request does not allow for any of the formats within `#priorities`.
      #
      # Can be set to `nil` to check the next rule in case of a priority mismatch.
      # Can be set to `false` to raise an `ART::Exceptions::NotAcceptable` exception in case of a priority mismatch.
      getter fallback_format : String | Bool | Nil

      # Returns the methods that this rule should optionally be scoped to.
      getter methods : Array(String)?

      # Determines if `ART::Listeners::Format` should be enabled for this rule and any rule following it.
      getter? stop : Bool

      def initialize(
        @path : Regex = /^\//,
        @priorities : Array(String)? = nil,
        @fallback_format : String | Bool | Nil = false,
        @methods : Array(String)? = nil,
        @stop : Bool = false
      ); end
    end

    # This method should be overridden in order to provide the configuration for `ART::Listeners::Format`.
    # See the [external documentation](/components/negotiation) for more details.
    #
    # By default it returns `nil`, which disables the listener.
    #
    # ```
    # def ART::Config::ContentNegotiation.configure : ART::Config::ContentNegotiation?
    #   new(
    #     Rule.new(priorities: ["json"], fallback_format: false),
    #   )
    # end
    # ```
    def self.configure : self?
      nil
    end

    # Returns the content negotiation rules that should be considered when determining the request's format.
    getter rules : Array(ART::Config::ContentNegotiation::Rule)

    def self.new(*rules : ART::Config::ContentNegotiation::Rule)
      new rules.to_a
    end

    def initialize(@rules : Array(ART::Config::ContentNegotiation::Rule)); end
  end
end
