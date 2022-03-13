require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Image

struct ImageValidatorTestCase < AVD::Spec::ConstraintValidatorTestCase
  def initialize
    super

    @image = "#{__DIR__}/fixtures/2x2.gif"
    @image_landscape = "#{__DIR__}/fixtures/landscape.gif"
    @image_portrait = "#{__DIR__}/fixtures/portrait.gif"
    @image_4x3 = "#{__DIR__}/fixtures/4x3.gif"
    @image_16x9 = "#{__DIR__}/fixtures/16x9.gif"
  end

  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_blank_is_valid : Nil
    self.validator.validate "", self.new_constraint
    self.assert_no_violation
  end

  def test_valid_image : Nil
    self.validator.validate @image, self.new_constraint
    self.assert_no_violation
  end

  def test_image_not_found : Nil
    self.validator.validate "foo", self.new_constraint not_found_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_FOUND_ERROR)
      .add_parameter("{{ file }}", "foo")
      .assert_violation
  end

  def test_valid_sizes : Nil
    self.validator.validate @image, self.new_constraint min_width: 1, max_width: 2, min_height: 1, max_height: 2
    self.assert_no_violation
  end

  def test_width_too_small : Nil
    self.validator.validate @image, self.new_constraint min_width: 3, min_width_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_NARROW_ERROR)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ min_width }}", 3)
      .assert_violation
  end

  def test_width_too_big : Nil
    self.validator.validate @image, self.new_constraint max_width: 1, max_width_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_WIDE_ERROR)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ max_width }}", 1)
      .assert_violation
  end

  def test_height_too_small : Nil
    self.validator.validate @image, self.new_constraint min_height: 3, min_height_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LOW_ERROR)
      .add_parameter("{{ height }}", 2)
      .add_parameter("{{ min_height }}", 3)
      .assert_violation
  end

  def test_height_too_big : Nil
    self.validator.validate @image, self.new_constraint max_height: 1, max_height_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_HIGH_ERROR)
      .add_parameter("{{ height }}", 2)
      .add_parameter("{{ max_height }}", 1)
      .assert_violation
  end

  def test_too_few_pixels : Nil
    self.validator.validate @image, self.new_constraint min_pixels: 5.0, min_pixels_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_FEW_PIXEL_ERROR)
      .add_parameter("{{ pixels }}", 4)
      .add_parameter("{{ min_pixels }}", 5.0)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ height }}", 2)
      .assert_violation
  end

  def test_too_many_pixels : Nil
    self.validator.validate @image, self.new_constraint max_pixels: 3.0, max_pixels_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_MANY_PIXEL_ERROR)
      .add_parameter("{{ pixels }}", 4)
      .add_parameter("{{ max_pixels }}", 3.0)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ height }}", 2)
      .assert_violation
  end

  def test_ratio_too_small : Nil
    self.validator.validate @image, self.new_constraint min_ratio: 2.0, min_ratio_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::RATIO_TOO_SMALL_ERROR)
      .add_parameter("{{ ratio }}", 1.0)
      .add_parameter("{{ min_ratio }}", 2.0)
      .assert_violation
  end

  def test_ratio_too_big : Nil
    self.validator.validate @image, self.new_constraint max_ratio: 0.5, max_ratio_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::RATIO_TOO_BIG_ERROR)
      .add_parameter("{{ ratio }}", 1.0)
      .add_parameter("{{ max_ratio }}", 0.5)
      .assert_violation
  end

  def test_max_ratio_uses_two_decimals : Nil
    self.validator.validate @image_4x3, self.new_constraint max_ratio: 1.33
    self.assert_no_violation
  end

  def test_min_ratio_uses_input_more_decimals : Nil
    self.validator.validate @image_4x3, self.new_constraint min_ratio: 4 / 3
    self.assert_no_violation
  end

  def test_max_ratio_uses_input_more_decimals : Nil
    self.validator.validate @image_16x9, self.new_constraint min_ratio: 16 / 9
    self.assert_no_violation
  end

  def test_square_not_allowed : Nil
    self.validator.validate @image, self.new_constraint allow_square: false, allow_square_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::SQUARE_NOT_ALLOWED_ERROR)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ height }}", 2)
      .assert_violation
  end

  def test_landscape_not_allowed : Nil
    self.validator.validate @image_landscape, self.new_constraint allow_landscape: false, allow_landscape_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::LANDSCAPE_NOT_ALLOWED_ERROR)
      .add_parameter("{{ width }}", 2)
      .add_parameter("{{ height }}", 1)
      .assert_violation
  end

  def test_portrait_not_allowed : Nil
    self.validator.validate @image_portrait, self.new_constraint allow_portrait: false, allow_portrait_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::PORTRAIT_NOT_ALLOWED_ERROR)
      .add_parameter("{{ width }}", 1)
      .add_parameter("{{ height }}", 2)
      .assert_violation
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
