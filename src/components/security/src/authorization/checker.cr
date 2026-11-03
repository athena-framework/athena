# Checks whether the user of the token held by an `ASEC::Authentication::Token::Storage::Interface` is granted an attribute, via an `ASEC::Authorization::AccessDecisionManager`.
#
# Decides for an `ASEC::Authentication::Token::Null` if there is no token, or its token has no user.
#
# ```
# checker = ASEC::Authorization::Checker.new token_storage, access_decision_manager
#
# checker.granted? "ROLE_ADMIN"
# checker.granted? "EDIT", post
# ```
class Athena::Security::Authorization::Checker
  include Athena::Security::Authorization::CheckerInterface

  @access_decision_stack = [] of ASEC::Authorization::AccessDecision

  def initialize(
    @token_storage : ASEC::Authentication::Token::Storage::Interface,
    @access_decision_manager : ASEC::Authorization::AccessDecisionManager,
  ); end

  # :inherit:
  def granted?(attribute : String, subject = nil, access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    token = @token_storage.token
    token = ASEC::Authentication::Token::Null.new if token.nil? || token.user.nil?

    access_decision ||= @access_decision_stack.last? || ASEC::Authorization::AccessDecision.new
    @access_decision_stack << access_decision

    begin
      access_decision.granted = @access_decision_manager.decide token, attribute, subject, access_decision
    ensure
      @access_decision_stack.pop
    end
  end
end
