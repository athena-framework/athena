require "./router_interface"
require "./matcher/request_matcher_interface"

class Athena::Routing::Router
  include Athena::Routing::RouterInterface
  include Athena::Routing::Matcher::RequestMatcherInterface

  # :inherit:
  getter route_collection : ART::RouteCollection

  # :inherit:
  getter context : ART::RequestContext

  # TODO: Should the matcher/generator types be customizable?

  getter matcher : ART::Matcher::URLMatcherInterface do
    ART::Matcher::URLMatcher.new(@context)
  end

  getter generator : ART::Generator::Interface do
    generator = ART::Generator::URLGenerator.new @context, @default_locale
    generator.strict_requirements = @strict_requirements
    generator
  end

  def initialize(
    @route_collection : ART::RouteCollection,
    @default_locale : String? = nil,
    @strict_requirements : Bool? = true,
    context : ART::RequestContext? = nil
  )
    @context = context || ART::RequestContext.new
  end

  # :inherit:
  def generate(route : String, params : Hash(String, String?) = Hash(String, String?).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    self.generator.generate route, params, reference_type
  end

  # :inherit:
  def generate(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params) : String
    self.generate route, params.to_h.transform_keys(&.to_s), reference_type
  end

  # :inherit:
  def match(path : String) : Hash(String, String?)
    self.matcher.match path
  end

  # :inherit:
  def match(request : ART::Request) : Hash(String, String?)
    matcher = self.matcher

    unless matcher.is_a? ART::Matcher::RequestMatcherInterface
      return matcher.match request.path
    end

    matcher.match request
  end

  # :inherit:
  def match?(path : String) : Hash(String, String?)?
    self.matcher.match? path
  end

  # :inherit:
  def match?(request : ART::Request) : Hash(String, String?)?
    matcher = self.matcher

    unless matcher.is_a? ART::Matcher::RequestMatcherInterface
      return matcher.match? request.path
    end

    matcher.match? request
  end

  # :inherit:
  def context=(@context : ART::RequestContext)
    if matcher = @matcher
      matcher.context = context
    end

    if generator = @generator
      generator.context = context
    end
  end
end
