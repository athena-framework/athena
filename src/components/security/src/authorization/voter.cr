# The base type of voters, which decide whether a token is granted an attribute, optionally on a subject.
#
# The `ASEC::Authorization::AccessDecisionManager` asks each voter for its `ASEC::Authorization::Voter::Access`, then turns their votes into a decision via its `ASEC::Authorization::Strategy::Interface`.
#
# A voter includes either:
#
# * `ASEC::Authorization::Voter::Subject(T, A)`, to vote on subjects of type `T`, e.g. on whether the user may edit a `Post`
# * `ASEC::Authorization::Voter::AttributeOnly`, to vote on attributes alone, whatever the subject, e.g. on roles
#
# The attributes of a subject voter are usually a fixed set, listed by an enum:
#
# ```
# class PostVoter < ASEC::Authorization::Voter
#   enum Attribute
#     View
#     Edit
#   end
#
#   include ASEC::Authorization::Voter::Subject(Post, Attribute)
#
#   protected def supports?(attribute : Attribute, subject : Post) : Bool
#     true
#   end
#
#   protected def vote_on_attribute(attribute : Attribute, subject : Post, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
#     case attribute
#     in .view? then subject.published? || subject.author == token.user_identifier
#     in .edit? then subject.author == token.user_identifier
#     end
#   end
# end
#
# checker.granted? PostVoter::Attribute::Edit, post
# ```
#
# A voter whose attributes are free-form strings uses `String` instead, e.g. `ASEC::Authorization::Voter::Subject(Post, String)`.
#
# A voter is only asked to vote on subjects whose type it handles, which is known at compile time.
# A voter may handle multiple types by including `ASEC::Authorization::Voter::Subject(T, A)` once per type, with overloads of its methods for each of them.
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

  # Returns the string the provided *attribute* is decided as, e.g. `"PostVoter::Attribute::Edit"`.
  #
  # Voters including `ASEC::Authorization::Voter::Subject(T, A)` with an enum as `A` vote on these strings.
  def self.attribute_name(attribute : Enum) : String
    "#{attribute.class}::#{attribute}"
  end

  # :nodoc:
  #
  # Returns the member of the provided *type* whose `.attribute_name` is the provided *attribute*, if any.
  def self.parse_attribute(attribute : String, type : E.class) : E? forall E
    {% begin %}
      case attribute
      {% for member in E.constants %}
        when {{"#{E}::#{member}"}} then {{E}}::{{member}}
      {% end %}
      end
    {% end %}
  end

  # Returns `false` if this voter never votes on the provided *attribute*, otherwise `true`.
  #
  # The `ASEC::Authorization::AccessDecisionManager` caches the result, and no longer asks this voter to vote on the *attribute* when it is `false`.
  # Defaults to only supporting the members of the attribute enums of a voter whose `ASEC::Authorization::Voter::Subject(T, A)` all have one.
  def supports_attribute?(attribute : String) : Bool
    {% begin %}
      {%
        attribute_types = @type.ancestors
          .select(&.name.starts_with?("Athena::Security::Authorization::Voter::Subject("))
          .map(&.type_vars[1])
        supports_any_attribute = attribute_types.empty? || attribute_types.any?(&.<=(String))
      %}

      {% if supports_any_attribute %}
        true
      {% else %}
        {% for attribute_type in attribute_types %}
          return true if ASEC::Authorization::Voter.parse_attribute attribute, {{attribute_type}}
        {% end %}

        false
      {% end %}
    {% end %}
  end

  macro finished
    {%
      @type.all_subclasses.each do |voter|
        unless voter.abstract?
          attribute_only = voter.ancestors.includes? ASEC::Authorization::Voter::AttributeOnly
          subjects = voter.ancestors.select(&.name.starts_with?("Athena::Security::Authorization::Voter::Subject("))
          subject_types = subjects.map(&.type_vars.first)

          if attribute_only && !subject_types.empty?
            voter.raise "Voter '#{voter}' cannot include both 'ASEC::Authorization::Voter::AttributeOnly' and 'ASEC::Authorization::Voter::Subject(T, A)'."
          elsif !attribute_only && subject_types.empty?
            voter.raise "Voter '#{voter}' must include either 'ASEC::Authorization::Voter::AttributeOnly' or 'ASEC::Authorization::Voter::Subject(T, A)'."
          end

          subjects.each do |subject|
            attribute_type = subject.type_vars[1]

            if !(attribute_type <= String) && !(attribute_type <= Enum)
              voter.raise "Voter '#{voter}' must vote on 'String' attributes or on the members of an enum, but '#{subject}' votes on '#{attribute_type}'."
            end

            if attribute_type.annotation(Flags)
              voter.raise "Voter '#{voter}' must vote on the members of an enum that is not a flags enum, but '#{subject}' votes on '#{attribute_type}'."
            end
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
