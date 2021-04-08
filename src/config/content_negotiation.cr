require "./config"

struct Athena::Routing::Config
  @[ACFA::Resolvable("routing.content_negotiation")]
  # Configuration options for `ART::Listeners::Format`.  See `.configure`.
  struct ContentNegotiation
    # Represents a rule that should be considered when determine the request's format.
    #
    # Contains configuration options to control when the content negotiation logic should be applied.
    struct Rule
      # Returns the a `Regex` representing the paths this rule should be scoped to.
      getter path : Regex

      # Returns a `Regex` representing the hostname that this rule should be scoped to.
      #
      # [parameters](/components/config#parameters) may be used to generalize this.
      getter host : Regex?

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
        host : Regex | String | Nil = nil,
        @priorities : Array(String)? = nil,
        @fallback_format : String | Bool | Nil = false,
        @methods : Array(String)? = nil,
        @stop : Bool = false
      )
        @host = case host
                when Regex  then host
                when String then Regex.new host
                end
      end
    end

    # This method should be overridden in order to provide the configuration for `ART::Listeners::Format`.
    # See the [external documentation](/components/negotiation) for more details.
    #
    # By default it returns `nil`, which disables the listener.
    #
    # ```
    # def ART::Config::ContentNegotiation.configure : ART::Config::ContentNegotiation?
    #   new(
    #     # Setting fallback_format to json means that instead of considering
    #     # the next rule in case of a priority mismatch, json will be used.
    #     Rule.new(priorities: ["json", "xml"], host: "api.example.com", fallback_format: "json"),
    #     # Setting fallback_format to false means that instead of considering
    #     # the next rule in case of a priority mismatch, a 406 will be returned.
    #     Rule.new(path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false),
    #     # Setting fallback_format to nil (or not including it) means that
    #     # in case of a priority mismatch the next rule will be considered.
    #     Rule.new(path: /^\/admin/, priorities: ["xml", "html"]),
    #     # Setting a priority to */* basically means any format will be matched.
    #     Rule.new(priorities: ["text/html", "*/*"], fallback_format: "html"),
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
