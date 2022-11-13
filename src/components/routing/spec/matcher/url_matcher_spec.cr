require "../spec_helper"
require "./abstract_url_matcher_test_case"

struct URLMatcherTest < AbstractURLMatcherTestCase
  private def get_matcher(routes : ART::RouteCollection, context : ART::RequestContext = ART::RequestContext.new) : ART::Matcher::URLMatcher
    ART.compile routes
    ART::Matcher::URLMatcher.new context
  end
end
