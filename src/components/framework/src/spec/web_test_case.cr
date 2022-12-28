require "./expectations/*"

# Base `ASPEC::TestCase` for web based integration tests.
#
# NOTE: Currently only `API` based tests are supported. This type exists to allow for introduction of other types in the future.
abstract struct Athena::Framework::Spec::WebTestCase < ASPEC::TestCase
  include ATH::Spec::Expectations::HTTP

  protected getter client : AbstractBrowser

  def initialize
    @client = create_client
  end

  # Returns the `AbstractBrowser` instance to which requests should be made against.
  def create_client : AbstractBrowser
    HTTPBrowser.new
  end
end
