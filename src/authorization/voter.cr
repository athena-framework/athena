# The base type of voters, which decide whether a token is granted an attribute, optionally on a subject.
#
# The `ASEC::Authorization::AccessDecisionManager` asks each voter for its `ASEC::Authorization::Voter::Access`, then turns their votes into a decision via its `ASEC::Authorization::Strategy::Interface`.
#
# A voter includes either:
#
# * `ASEC::Authorization::Voter::Subject(T)`, to vote on subjects of type `T`, e.g. on whether the user may edit a `Post`
# * `ASEC::Authorization::Voter::AttributeOnly`, to vote on attributes alone, whatever the subject, e.g. on roles
#
# ```
# class PostVoter < ASEC::Authorization::Voter
#   include ASEC::Authorization::Voter::Subject(Post)
#
#   protected def supports?(attribute : String, subject : Post) : Bool
#     attribute.in? "VIEW", "EDIT"
#   end
#
#   protected def vote_on_attribute(attribute : String, subject : Post, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
#     return true if attribute == "VIEW" && subject.published?
#
#     subject.author == token.user
#   end
# end
# ```
#
# A voter is only asked to vote on subjects whose type it handles, which is known at compile time.
# A voter may handle multiple types by including `ASEC::Authorization::Voter::Subject(T)` once per type, with overloads of its methods for each of them.
# A module may also be used as the type, which includes each of the types including it.
abstract class Athena::Security::Authorization::Voter
  # The vote of a voter.
  enum Access
    # The voter denies the access.
    Denied = -1

    # The voter does not vote, e.g. because it does not handle the attribute.
    Abstain = 0

    # The voter grants the access.
    Granted = 1
  end

  # Maps the name of a subject type to the voter types voting on it, built once all types are known.
  #
  # :nodoc:
  SUBJECT_VOTERS = {} of Nil => Nil

  # The voter types voting on attributes alone, built once all types are known.
  #
  # :nodoc:
  ATTRIBUTE_VOTERS = [] of Nil

  # Returns `false` if this voter never votes on the provided *attribute*, otherwise `true`.
  #
  # The `ASEC::Authorization::AccessDecisionManager` caches the result, and no longer asks this voter to vote on the *attribute* when it is `false`.
  def supports_attribute?(attribute : String) : Bool
    true
  end

  macro finished
    {%
      @type.all_subclasses.each do |voter|
        unless voter.abstract?
          attribute_only = voter.ancestors.includes? ASEC::Authorization::Voter::AttributeOnly
          subject_types = voter.ancestors.select(&.name.starts_with?("Athena::Security::Authorization::Voter::Subject(")).map(&.type_vars.first)

          if attribute_only && !subject_types.empty?
            voter.raise "Voter '#{voter}' cannot include both 'ASEC::Authorization::Voter::AttributeOnly' and 'ASEC::Authorization::Voter::Subject(T)'."
          elsif !attribute_only && subject_types.empty?
            voter.raise "Voter '#{voter}' must include either 'ASEC::Authorization::Voter::AttributeOnly' or 'ASEC::Authorization::Voter::Subject(T)'."
          end

          ATTRIBUTE_VOTERS << voter if attribute_only

          subject_types.each do |subject_type|
            key = subject_type.stringify
            SUBJECT_VOTERS[key] = (SUBJECT_VOTERS[key] || [] of Nil) + [voter]
          end
        end
      end
    %}
  end
end
