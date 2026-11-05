require "./spec_helper"

describe Athena::Security do
  describe "compiler errors", tags: "compiled" do
    it "when a voter includes neither voter module" do
      ASPEC::Methods.assert_compile_time_error "Voter 'NoModuleVoter' must include either 'ASEC::Authorization::Voter::AttributeOnly' or 'ASEC::Authorization::Voter::Subject(T, A)'.", <<-CR
        require "../src/athena-security"

        class NoModuleVoter < ASEC::Authorization::Voter; end
      CR
    end

    it "when a voter includes both voter modules" do
      ASPEC::Methods.assert_compile_time_error "Voter 'BothModulesVoter' cannot include both 'ASEC::Authorization::Voter::AttributeOnly' and 'ASEC::Authorization::Voter::Subject(T, A)'.", <<-CR
        require "../src/athena-security"

        class BothModulesVoter < ASEC::Authorization::Voter
          include ASEC::Authorization::Voter::AttributeOnly
          include ASEC::Authorization::Voter::Subject(String, String)

          def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
            ASEC::Authorization::Voter::Access::Abstain
          end

          protected def supports?(attribute : String, subject : String) : Bool
            true
          end

          protected def vote_on_attribute(attribute : String, subject : String, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
            true
          end
        end
      CR
    end

    it "when a voter votes on attributes that are neither strings nor an enum" do
      ASPEC::Methods.assert_compile_time_error "Voter 'SymbolVoter' must vote on 'String' attributes or on the members of an enum, but 'Athena::Security::Authorization::Voter::Subject(String, Symbol)' votes on 'Symbol'.", <<-CR
        require "../src/athena-security"

        class SymbolVoter < ASEC::Authorization::Voter
          include ASEC::Authorization::Voter::Subject(String, Symbol)

          protected def supports?(attribute : Symbol, subject : String) : Bool
            true
          end

          protected def vote_on_attribute(attribute : Symbol, subject : String, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
            true
          end
        end
      CR
    end

    it "when a voter votes on the members of a flags enum" do
      ASPEC::Methods.assert_compile_time_error "Voter 'FlagsVoter' must vote on the members of an enum that is not a flags enum, but 'Athena::Security::Authorization::Voter::Subject(String, FlagsVoter::Attribute)' votes on 'FlagsVoter::Attribute'.", <<-CR
        require "../src/athena-security"

        class FlagsVoter < ASEC::Authorization::Voter
          @[Flags]
          enum Attribute
            View
            Edit
          end

          include ASEC::Authorization::Voter::Subject(String, Attribute)

          protected def supports?(attribute : Attribute, subject : String) : Bool
            true
          end

          protected def vote_on_attribute(attribute : Attribute, subject : String, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
            true
          end
        end
      CR
    end
  end
end
