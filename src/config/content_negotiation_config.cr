require "./routing_config"

# :nodoc:
class Regex
  def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : self
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end

    new node.value
  end
end

struct Athena::Routing::Config
  struct ContentNegotiation
    include ACF::Configuration

    struct Rule
      include ACF::Configuration

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

    # Returns the content negotiation rules that should be considered when determining the request's format.
    getter rules : Array(ART::Config::ContentNegotiation::Rule) = [] of ART::Config::ContentNegotiation::Rule
  end
end

struct Athena::Config::ConfigurationResolver
  # :inherit:
  def resolve(_type : Athena::Routing::Config::ContentNegotiation.class) : ART::Config::ContentNegotiation?
    base.routing.content_negotiation
  end
end
