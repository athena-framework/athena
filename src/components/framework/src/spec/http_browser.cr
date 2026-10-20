# Simulates a browser and makes a requests to `ATH::RouteHandler`.
class Athena::Framework::Spec::HTTPBrowser < ATH::Spec::AbstractBrowser
  # Returns a reference to an `ADI::Spec::MockableServiceContainer` to allow configuring the container before a test.
  def container : ADI::Spec::MockableServiceContainer
    ADI.container.as(ADI::Spec::MockableServiceContainer)
  end

  # Returns the session of the browser, starting a new one if the browser does not have one yet.
  # Requires [sessions](/Framework/Bundle/Schema/Session/) and [framework.test](/Framework/Bundle/Schema/#Athena::Framework::Bundle::Schema#test) to be enabled.
  #
  # Allows setting up the session before making a request, or checking its data afterwards.
  #
  # ```
  # session = self.client.session
  # session.set "cart", [1, 2, 3]
  # session.save
  #
  # self.get "/cart"
  # ```
  def session : AHTTP::Session
    {% if !(factory = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_factory"]) %}
      {% raise "'ATH::Spec::HTTPBrowser#session' requires sessions to be enabled via 'framework.session.enabled'." %}
    {% elsif !factory["public"] %}
      {% raise "'ATH::Spec::HTTPBrowser#session' requires 'framework.test' to be enabled." %}
    {% end %}

    session = ADI.container.athena_http_session_factory.create_session

    cookie = @cookie_jar.get session.name

    if cookie
      session.id = cookie.value
    end

    session.start

    if cookie.nil?
      domains = @cookie_jar.all.map { |c| c.name == session.name ? c.domain : nil }.uniq!
      domains = [nil] of String? if domains.empty?

      domains.each do |domain|
        @cookie_jar.set ::HTTP::Cookie.new session.name, session.id, domain: domain
      end
    elsif cookie.value != session.id
      # The session gets a new ID if the one from the cookie does not exist.
      cookie.value = session.id
    end

    session
  end

  protected def do_request(request : AHTTP::Request) : ::HTTP::Server::Response
    response = ::HTTP::Server::Response.new IO::Memory.new

    handler = ADI.container.athena_http_kernel
    athena_response = handler.handle request

    athena_response.send request, response

    handler.terminate request, athena_response

    response
  ensure
    # The requests of a test share its container, so each request starts from reset services.
    # They're closed once the test is done, see `ADI::Spec::ContainerTestCase#tear_down`.
    ADI.container.athena_dependency_injection_services_resetter.reset
  end
end
