require "./config"

struct Athena::Routing::Config
  @[ACFA::Resolvable("routing.content_negotiation")]
  # TODO: Add content negoitation docs.
  struct ContentNegotiation
    struct Rule
      # Returns the a `Regex` representing the paths this rule should be scoped to.
      getter path : Regex = /^\//

      # Returns the formats that should be considered for this set of routes.
      # Must contain at least one format.
      getter priorities : Array(String)? = nil

      # Returns the format that should be used if a request does not allow for any of the formats within `#priorities`.
      #
      # Can be set to `nil` to check the next rule in case of a priority mismatch.
      # Can be set to `false` to raise an `ART::Exceptions::NotAcceptable` exception in case of a priority mismatch.
      getter fallback_format : String | Bool | Nil = false

      # Returns the methods that this rule should optionally be scoped to.
      getter methods : Array(String)? = nil
    end

    # TODO: Add content negoitation docs.
    def self.configure : self?
      nil
    end

    # Returns the content negotiation rules that should be considered when determining the request's format.
    getter rules : Array(ART::Config::ContentNegotiation::Rule) = [] of ART::Config::ContentNegotiation::Rule
  end
end
