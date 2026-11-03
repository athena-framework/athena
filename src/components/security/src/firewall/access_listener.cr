# Denies the access to requests whose user is not granted the attribute that the `ASEC::AccessMap` requires for them, e.g. a role.
#
# Runs after the other listeners of a firewall, once its user is authenticated.
# Raises an `ASEC::Exception::AccessDenied` to deny the access, which the `ASEC::Firewall::ExceptionListener` of the firewall handles.
class Athena::Security::Firewall::AccessListener
  include Athena::Security::Firewall::ListenerInterface

  def initialize(
    @token_storage : ASEC::Authentication::Token::Storage::Interface,
    @access_decision_manager : ASEC::Authorization::AccessDecisionManager,
    @access_map : ASEC::AccessMap,
  ); end

  # :inherit:
  #
  # Only returns `true` if the *request* requires an attribute other than `ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS`.
  def supports?(request : AHTTP::Request) : Bool?
    attribute = @access_map.attribute request

    return unless attribute

    request.attributes.set "_access_control_attribute", attribute

    attribute == ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS ? nil : true
  end

  # :inherit:
  #
  # Raises an `ASEC::Exception::AccessDenied` if the user is not granted the attribute required for the request, which is the subject of the decision.
  def authenticate(event : AHK::Events::Request) : Nil
    request = event.request

    attribute = request.attributes.get? "_access_control_attribute", String
    request.attributes.remove "_access_control_attribute"

    return unless attribute

    token = @token_storage.token || ASEC::Authentication::Token::Null.new
    access_decision = ASEC::Authorization::AccessDecision.new

    return if @access_decision_manager.decide token, attribute, request, access_decision

    exception = ASEC::Exception::AccessDenied.new access_decision.message
    exception.attribute = attribute
    exception.access_decision = access_decision

    raise exception
  end

  # :inherit:
  def priority : Int32
    -255
  end
end
