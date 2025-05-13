require "./abstract_types_guesser_test_case"
require "./spec_helper"

struct MagicTypesGuesserTest < AbstractTypesGusserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::MagicTypesGuesser.new
  end
end
