require "./abstract_types_guesser_test_case"
require "./spec_helper"

struct NativeTypesGuesserTest < AbstractTypesGuesserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::NativeTypesGuesser.new
  end

  include FileExtensionOnlyOverrides
end
