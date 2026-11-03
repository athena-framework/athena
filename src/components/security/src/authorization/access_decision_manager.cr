# Decides whether a token is granted an attribute, optionally on a subject, by asking its voters and turning their votes into a decision via its `ASEC::Authorization::Strategy::Interface`.
#
# ```
# access_decision_manager = ASEC::Authorization::AccessDecisionManager.new(
#   [ASEC::Authorization::Voter::Role.new, PostVoter.new] of ASEC::Authorization::Voter,
#   ASEC::Authorization::Strategy::Unanimous.new
# )
#
# access_decision_manager.decide token, "EDIT", post # => true
# ```
#
# Only the voters handling the type of the subject vote on it, see `ASEC::Authorization::Voter`.
class Athena::Security::Authorization::AccessDecisionManager
  @supported_voters = Hash(String, Array(ASEC::Authorization::Voter)).new
  @access_decision_stack = [] of ASEC::Authorization::AccessDecision

  def initialize(
    @voters : Array(ASEC::Authorization::Voter) = [] of ASEC::Authorization::Voter,
    @strategy : ASEC::Authorization::Strategy::Interface = ASEC::Authorization::Strategy::Affirmative.new,
  ); end

  # Returns `true` if the provided *token* is granted the provided *attribute*, optionally on the provided *subject*, otherwise `false`.
  #
  # The decision and the votes it was based on are stored in the provided *access_decision*, if any.
  # A decision made while another one is ongoing, e.g. by a voter, defaults to storing them in the ongoing *access_decision*.
  def decide(token : ASEC::Authentication::Token::Interface, attribute : String, subject = nil, access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    access_decision ||= @access_decision_stack.last? || ASEC::Authorization::AccessDecision.new
    @access_decision_stack << access_decision

    access_decision.strategy = @strategy.to_s

    begin
      access_decision.granted = @strategy.decide self.collect_results(token, attribute, subject, access_decision), access_decision
    ensure
      @access_decision_stack.pop
    end
  end

  private def collect_results(token : ASEC::Authentication::Token::Interface, attribute : String, subject : _, access_decision : ASEC::Authorization::AccessDecision) : Iterator(ASEC::Authorization::Voter::Access)
    self.voters(attribute).each.map do |voter|
      vote = ASEC::Authorization::Voter::Vote.new

      self.record_vote voter, self.vote(voter, token, attribute, subject, vote), vote, access_decision
    end
  end

  # Not generic, so that the name of the voter, which dispatches on each voter type, is only compiled once rather than once per subject type.
  private def record_vote(voter : ASEC::Authorization::Voter, result : ASEC::Authorization::Voter::Access, vote : ASEC::Authorization::Voter::Vote, access_decision : ASEC::Authorization::AccessDecision) : ASEC::Authorization::Voter::Access
    vote.voter = voter.class.name
    vote.result = result
    access_decision.votes << vote

    result
  end

  private def voters(attribute : String) : Array(ASEC::Authorization::Voter)
    @supported_voters[attribute] ||= @voters.select &.supports_attribute?(attribute)
  end

  # Asks the *voter* to vote if it handles one of the types the *subject* may be, otherwise abstains.
  private def vote(voter : ASEC::Authorization::Voter, token : ASEC::Authentication::Token::Interface, attribute : String, subject : T, vote : ASEC::Authorization::Voter::Vote) : ASEC::Authorization::Voter::Access forall T
    {% begin %}
      {%
        # The types the subject may be at runtime.
        members = [] of Nil
        modules = [] of Nil

        T.union_types.each do |member|
          if member.module?
            modules << member
          else
            members << member
            members = members + member.all_subclasses
          end
        end

        # Includes the types including a module via another module, as the modules found are iterated over too.
        modules.each do |mod|
          mod.includers.each do |includer|
            if includer.module?
              modules << includer unless modules.any? { |known_module| known_module == includer }
            else
              members << includer
              members = members + includer.all_subclasses
            end
          end
        end

        # The voter types handling those types, each with the subject types it handles, from the most specific type.
        voter_types = {} of Nil => Nil

        members.each do |member|
          ([member] + member.ancestors).each do |type|
            (ASEC::Authorization::Voter::SUBJECT_VOTERS[type.stringify] || [] of Nil).each do |voter_type|
              key = voter_type.stringify
              entry = voter_types[key] || {voter_type, [] of Nil}

              # `includes?` does not consider a virtual type equal to its non-virtual type, unlike `==`.
              voter_types[key] = {voter_type, entry[1] + [type]} unless entry[1].any? { |handled_type| handled_type == type }
            end
          end
        end

        # A voter type also matches its subtypes, so the subtypes must be checked first.
        voter_entries = voter_types.values.sort_by { |entry| -entry[0].ancestors.size }
      %}

      case voter
      {% for entry in voter_entries %}
        when {{entry[0]}}
          case subject
          {% for type in entry[1] %}
            when {{type}} then voter.vote token, subject, attribute, vote
          {% end %}
          else
            ASEC::Authorization::Voter::Access::Abstain
          end
      {% end %}
      {% unless ASEC::Authorization::Voter::ATTRIBUTE_VOTERS.empty? %}
        when {{ASEC::Authorization::Voter::ATTRIBUTE_VOTERS.splat}}
          voter.vote token, attribute, vote
      {% end %}
      else
        ASEC::Authorization::Voter::Access::Abstain
      end
    {% end %}
  end
end
