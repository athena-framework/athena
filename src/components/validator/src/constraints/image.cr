require "athena-image_size"

# An extension of `AVD::Constraints::File` whose `AVD::Constraints::File#mime_types` and `AVD::Constraints::File#mime_type_message` are setup to specifically handle image files.
# This constraint also provides the ability to validate against various image specific parameters.
#
# See `AVD::Constraints::File` for common documentation.
#
# # Configuration
#
# ## Optional Arguments
#
# ### mime_types
#
# **Type:** `Enumerable(String)?` **Default:** `{"image/*"}`
#
# Requires the file to have a valid image MIME type.
# See [IANA website](https://www.iana.org/assignments/media-types/media-types.xhtml) for the full listing.
#
# ### mime_type_message
#
# **Type:** `String` **Default:** `This file is not a valid image.`
#
# The message that will be shown if the file is not an image.
#
# ### min_height
#
# **Type:** `Int32` **Default:** `nil`
#
# If set, the image's height in pixels must be greater than or equal to this value.
#
# ### min_height_message
#
# **Type:** `String` **Default:** `The image height is too small ({{ height }}px). Minimum height expected is {{ min_height }}px.`
#
# The message that will be shown if the height of the image is less than `#min_height`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The current (invalid) height.
# * `{{ min_height }}` - The minimum required height.
#
# ### max_height
#
# **Type:** `Int32` **Default:** `nil`
#
# If set, the image's height in pixels must be less than or equal to this value.
#
# ### max_height_message
#
# **Type:** `String` **Default:** `The image height is too big ({{ height }}px). Allowed maximum height is {{ max_height }}px.`
#
# The message that will be shown if the height of the image exceeds `#max_height`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The current (invalid) height.
# * `{{ max_height }}` - The maximum allowed height.
#
# ### min_width
#
# **Type:** `Int32` **Default:** `nil`
#
# If set, the image's width in pixels must be greater than or equal to this value.
#
# ### min_width_message
#
# **Type:** `String` **Default:** `The image width is too small ({{ width }}px). Minimum width expected is {{ min_width }}px.`
#
# The message that will be shown if the width of the image is less than `#min_width`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ width }}` - The current (invalid) width.
# * `{{ min_width }}` - The minimum required width.
#
# ### max_width
#
# **Type:** `Int32` **Default:** `nil`
#
# If set, the image's width in pixels must be less than or equal to this value.
#
# ### max_width_message
#
# **Type:** `String` **Default:** `The image width is too big ({{ width }}px). Allowed maximum width is {{ max_width }}px.`
#
# The message that will be shown if the width of the image exceeds `#max_width`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ width }}` - The current (invalid) width.
# * `{{ max_width }}` - The maximum allowed width.
#
# ### size_not_detected_message
#
# **Type:** `String` **Default:** `The size of the image could not be detected.`
#
# The message that will be shown if the size of the image is unable to be determined.
# Will only occur if at least one of the size related options has been set.
#
# ### min_ratio
#
# **Type:** `Float64` **Default:** `nil`
#
# If set, the image's aspect ratio (`width / height`) must be greater than or equal to this value.
#
# ### min_ratio_message
#
# **Type:** `String` **Default:** `The image ratio is too small ({{ ratio }}). Minimum ratio expected is {{ min_ratio }}.`
#
# The message that will be shown if the aspect ratio of the image is less than `#min_ratio`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ ratio }}` - The current (invalid) ratio.
# * `{{ min_ratio }}` - The minimum required ratio.
#
# ### max_ratio
#
# **Type:** `Float64` **Default:** `nil`
#
# If set, the image's aspect ratio (`width / height`) must be less than or equal to this value.
#
# ### max_ratio_message
#
# **Type:** `String` **Default:** `The image ratio is too big ({{ ratio }}). Allowed maximum ratio is {{ max_ratio }}.`
#
# The message that will be shown if the aspect ratio of the image exceeds `#max_ratio`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ ratio }}` - The current (invalid) ratio.
# * `{{ max_ratio }}` - The maximum allowed ratio.
#
# ### min_pixels
#
# **Type:** `Float64` **Default:** `nil`
#
# If set, the amount of pixels of the image file must be greater than or equal to this value.
#
# ### min_pixels_message
#
# **Type:** `String` **Default:** `The image has too few pixels ({{ pixels }} pixels). Minimum amount expected is {{ min_pixels }} pixels.`
#
# The message that will be shown if the amount of pixels of the image is less than `#min_pixels`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The image's height.
# * `{{ width }}` - The image's width.
# * `{{ pixels }}` - The image's pixels.
# * `{{ min_pixels }}` - The minimum required pixels.
#
# ### max_pixels
#
# **Type:** `Float64` **Default:** `nil`
#
# If set, the amount of pixels of the image file must be less than or equal to this value.
#
# ### max_pixels_message
#
# **Type:** `String` **Default:** `The image has too many pixels ({{ pixels }} pixels). Maximum amount expected is {{ max_pixels }} pixels.`
#
# The message that will be shown if the amount of pixels of the image is greater than `#max_pixels`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The image's height.
# * `{{ width }}` - The image's width.
# * `{{ pixels }}` - The image's pixels.
# * `{{ max_pixels }}` - The maximum allowed pixels.
#
# ### allow_landscape
#
# **Type:** `Bool` **Default:** `true`
#
# If `false`, the image cannot be landscape oriented.
#
# ### allow_landscape_message
#
# **Type:** `String` **Default:** `The image is landscape oriented ({{ width }}x{{ height }}px). Landscape oriented images are not allowed.`
#
# The message that will be shown if the `#allow_landscape` is `false` and the image is landscape oriented.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The image's height.
# * `{{ width }}` - The image's width.
#
# ### allow_portrait
#
# **Type:** `Bool` **Default:** `true`
#
# If `false`, the image cannot be portrait oriented.
#
# ### allow_portrait_message
#
# **Type:** `String` **Default:** `The image is portrait oriented ({{ width }}x{{ height }}px). Portrait oriented images are not allowed.`
#
# The message that will be shown if the `#allow_portrait` is `false` and the image is portrait oriented.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The image's height.
# * `{{ width }}` - The image's width.
#
# ### allow_square
#
# **Type:** `Bool` **Default:** `true`
#
# If `false`, the image cannot be a square.
# If you want to force the image to be a square, keep this as is and set `#allow_landscape` and `#allow_portrait` to `false`.
#
# ### allow_square_message
#
# **Type:** `String` **Default:** `The image is square ({{ width }}x{{ height }}px). Square images are not allowed.`
#
# The message that will be shown if the `#allow_square` is `false` and the image is square.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ height }}` - The image's height.
# * `{{ width }}` - The image's width.
#
# ### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# ### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
class Athena::Validator::Constraints::Image < Athena::Validator::Constraints::File
  SIZE_NOT_DETECTED_ERROR     = "6d55c3f4-e58e-4fe3-91ee-74b492199956"
  TOO_WIDE_ERROR              = "7f87163d-878f-47f5-99ba-a8eb723a1ab2"
  TOO_NARROW_ERROR            = "9afbd561-4f90-4a27-be62-1780fc43604a"
  TOO_HIGH_ERROR              = "7efae81c-4877-47ba-aa65-d01ccb0d4645"
  TOO_LOW_ERROR               = "aef0cb6a-c07f-4894-bc08-1781420d7b4c"
  TOO_FEW_PIXEL_ERROR         = "1b06b97d-ae48-474e-978f-038a74854c43"
  TOO_MANY_PIXEL_ERROR        = "ee0804e8-44db-4eac-9775-be91aaf72ce1"
  RATIO_TOO_BIG_ERROR         = "70cafca6-168f-41c9-8c8c-4e47a52be643"
  RATIO_TOO_SMALL_ERROR       = "59b8c6ef-bcf2-4ceb-afff-4642ed92f12e"
  SQUARE_NOT_ALLOWED_ERROR    = "5d41425b-facb-47f7-a55a-de9fbe45cb46"
  LANDSCAPE_NOT_ALLOWED_ERROR = "6f895685-7cf2-4d65-b3da-9029c5581d88"
  PORTRAIT_NOT_ALLOWED_ERROR  = "65608156-77da-4c79-a88c-02ef6d18c782"
  CORRUPTED_IMAGE_ERROR       = "5d4163f3-648f-4e39-87fd-cc5ea7aad2d1"

  @@error_names = {
    AVD::Constraints::File::NOT_FOUND_ERROR         => "NOT_FOUND_ERROR",
    AVD::Constraints::File::NOT_READABLE_ERROR      => "NOT_READABLE_ERROR",
    AVD::Constraints::File::EMPTY_ERROR             => "EMPTY_ERROR",
    AVD::Constraints::File::TOO_LARGE_ERROR         => "TOO_LARGE_ERROR",
    AVD::Constraints::File::INVALID_MIME_TYPE_ERROR => "INVALID_MIME_TYPE_ERROR",
    SIZE_NOT_DETECTED_ERROR                         => "SIZE_NOT_DETECTED_ERROR",
    TOO_WIDE_ERROR                                  => "TOO_WIDE_ERROR",
    TOO_NARROW_ERROR                                => "TOO_NARROW_ERROR",
    TOO_HIGH_ERROR                                  => "TOO_HIGH_ERROR",
    TOO_LOW_ERROR                                   => "TOO_LOW_ERROR",
    TOO_FEW_PIXEL_ERROR                             => "TOO_FEW_PIXEL_ERROR",
    TOO_MANY_PIXEL_ERROR                            => "TOO_MANY_PIXEL_ERROR",
    RATIO_TOO_BIG_ERROR                             => "RATIO_TOO_BIG_ERROR",
    RATIO_TOO_SMALL_ERROR                           => "RATIO_TOO_SMALL_ERROR",
    SQUARE_NOT_ALLOWED_ERROR                        => "SQUARE_NOT_ALLOWED_ERROR",
    LANDSCAPE_NOT_ALLOWED_ERROR                     => "LANDSCAPE_NOT_ALLOWED_ERROR",
    PORTRAIT_NOT_ALLOWED_ERROR                      => "PORTRAIT_NOT_ALLOWED_ERROR",
    CORRUPTED_IMAGE_ERROR                           => "CORRUPTED_IMAGE_ERROR",
  }

  getter min_width : Int32?
  getter max_width : Int32?
  getter min_height : Int32?
  getter max_height : Int32?
  getter min_ratio : Float64?
  getter max_ratio : Float64?
  getter min_pixels : Float64?
  getter max_pixels : Float64?
  getter? allow_square : Bool
  getter? allow_landscape : Bool
  getter? allow_portrait : Bool

  getter size_not_detected_message : String
  getter min_width_message : String
  getter max_width_message : String
  getter min_height_message : String
  getter max_height_message : String
  getter min_pixels_message : String
  getter max_pixels_message : String
  getter min_ratio_message : String
  getter max_ratio_message : String
  getter allow_square_message : String
  getter allow_landscape_message : String
  getter allow_portrait_message : String

  def initialize(
    @min_width : Int32? = nil,
    @max_width : Int32? = nil,
    @min_height : Int32? = nil,
    @max_height : Int32? = nil,
    @min_ratio : Float64? = nil,
    @max_ratio : Float64? = nil,
    @min_pixels : Float64? = nil,
    @max_pixels : Float64? = nil,
    @allow_square : Bool = true,
    @allow_landscape : Bool = true,
    @allow_portrait : Bool = true,
    @size_not_detected_message : String = "The size of the image could not be detected.",
    @min_width_message : String = "The image width is too small ({{ width }}px). Minimum width expected is {{ min_width }}px.",
    @max_width_message : String = "The image width is too big ({{ width }}px). Allowed maximum width is {{ max_width }}px.",
    @min_height_message : String = "The image height is too small ({{ height }}px). Minimum height expected is {{ min_height }}px.",
    @max_height_message : String = "The image height is too big ({{ height }}px). Allowed maximum height is {{ max_height }}px.",
    @min_pixels_message : String = "The image has too few pixels ({{ pixels }} pixels). Minimum amount expected is {{ min_pixels }} pixels.",
    @max_pixels_message : String = "The image has too many pixels ({{ pixels }} pixels). Maximum amount expected is {{ max_pixels }} pixels.",
    @min_ratio_message : String = "The image ratio is too small ({{ ratio }}). Minimum ratio expected is {{ min_ratio }}.",
    @max_ratio_message : String = "The image ratio is too big ({{ ratio }}). Allowed maximum ratio is {{ max_ratio }}.",
    @allow_square_message : String = "The image is square ({{ width }}x{{ height }}px). Square images are not allowed.",
    @allow_landscape_message : String = "The image is landscape oriented ({{ width }}x{{ height }}px). Landscape oriented images are not allowed.",
    @allow_portrait_message : String = "The image is portrait oriented ({{ width }}x{{ height }}px). Portrait oriented images are not allowed.",
    max_size : Int | String | Nil = nil,
    binary_format : Bool? = nil,
    mime_types : Enumerable(String)? = {"image/*"},
    not_found_message : String = "The file could not be found.",
    not_readable_message : String = "The file is not readable.",
    empty_message : String = "An empty file is not allowed.",
    max_size_message : String = "The file is too large ({{ size }} {{ suffix }}). Allowed maximum size is {{ limit }} {{ suffix }}.",
    mime_type_message : String = "This file is not a valid image.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super max_size, binary_format, mime_types, not_found_message, not_readable_message, empty_message, max_size_message, mime_type_message, groups, payload
  end

  class Validator < Athena::Validator::Constraints::File::Validator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Image) : Nil
      violations = self.context.violations.size

      super

      failed = self.context.violations.size != violations

      return if failed || value.nil? || value == ""

      # Return early is no extra validation is being applied.
      return if {
                  constraint.min_width, constraint.max_width, constraint.min_height, constraint.max_height,
                  constraint.min_pixels, constraint.max_pixels, constraint.min_ratio, constraint.max_ratio,
                  !constraint.allow_square?, !constraint.allow_landscape?, !constraint.allow_portrait?,
                }.none?

      path = case value
             when Path   then value
             when ::File then value.path
             else
               value.to_s
             end

      image_size = AIS::Image.from_file_path? path

      if image_size.nil? || image_size.width.zero? || image_size.height.zero?
        self
          .context
          .add_violation(constraint.size_not_detected_message, SIZE_NOT_DETECTED_ERROR)

        return
      end

      self.validate_size image_size, constraint
      self.validate_pixels image_size, constraint
      self.validate_ratios image_size, constraint
      self.validate_shape image_size, constraint

      # TODO: Somehow check if image is actually valid?
    end

    private def validate_size(image_size : AIS::Image, constraint : AVD::Constraints::Image) : Nil
      if (min_width = constraint.min_width) && (image_size.width < min_width)
        self
          .context
          .build_violation(constraint.min_width_message, TOO_NARROW_ERROR)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ min_width }}", constraint.min_width)
          .add
      end

      if (max_width = constraint.max_width) && (image_size.width > max_width)
        self
          .context
          .build_violation(constraint.max_width_message, TOO_WIDE_ERROR)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ max_width }}", constraint.max_width)
          .add
      end

      if (min_height = constraint.min_height) && (image_size.height < min_height)
        self
          .context
          .build_violation(constraint.min_height_message, TOO_LOW_ERROR)
          .add_parameter("{{ height }}", image_size.height)
          .add_parameter("{{ min_height }}", constraint.min_height)
          .add
      end

      if (max_height = constraint.max_height) && (image_size.height > max_height)
        self
          .context
          .build_violation(constraint.max_height_message, TOO_HIGH_ERROR)
          .add_parameter("{{ height }}", image_size.height)
          .add_parameter("{{ max_height }}", constraint.max_height)
          .add
      end
    end

    private def validate_pixels(image_size : AIS::Image, constraint : AVD::Constraints::Image) : Nil
      pixels = image_size.width * image_size.height

      if (min_pixels = constraint.min_pixels) && (pixels < min_pixels)
        self
          .context
          .build_violation(constraint.min_pixels_message, TOO_FEW_PIXEL_ERROR)
          .add_parameter("{{ pixels }}", pixels)
          .add_parameter("{{ min_pixels }}", min_pixels)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ height }}", image_size.height)
          .add
      end

      if (max_pixels = constraint.max_pixels) && (pixels > max_pixels)
        self
          .context
          .build_violation(constraint.max_pixels_message, TOO_MANY_PIXEL_ERROR)
          .add_parameter("{{ pixels }}", pixels)
          .add_parameter("{{ max_pixels }}", max_pixels)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ height }}", image_size.height)
          .add
      end
    end

    private def validate_ratios(image_size : AIS::Image, constraint : AVD::Constraints::Image) : Nil
      ratio = (image_size.width / image_size.height).round 2, mode: :ties_away

      if (min_ratio = constraint.min_ratio) && (ratio < min_ratio.round(2, mode: :ties_away))
        self
          .context
          .build_violation(constraint.min_ratio_message, RATIO_TOO_SMALL_ERROR)
          .add_parameter("{{ ratio }}", ratio)
          .add_parameter("{{ min_ratio }}", min_ratio)
          .add
      end

      if (max_ratio = constraint.max_ratio) && (ratio > max_ratio.round(2, mode: :ties_away))
        self
          .context
          .build_violation(constraint.max_ratio_message, RATIO_TOO_BIG_ERROR)
          .add_parameter("{{ ratio }}", ratio)
          .add_parameter("{{ max_ratio }}", max_ratio)
          .add
      end
    end

    private def validate_shape(image_size : AIS::Image, constraint : AVD::Constraints::Image) : Nil
      if !constraint.allow_square? && image_size.width == image_size.height
        self
          .context
          .build_violation(constraint.allow_square_message, SQUARE_NOT_ALLOWED_ERROR)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ height }}", image_size.height)
          .add
      end

      if !constraint.allow_landscape? && image_size.width > image_size.height
        self
          .context
          .build_violation(constraint.allow_landscape_message, LANDSCAPE_NOT_ALLOWED_ERROR)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ height }}", image_size.height)
          .add
      end

      if !constraint.allow_portrait? && image_size.width < image_size.height
        self
          .context
          .build_violation(constraint.allow_portrait_message, PORTRAIT_NOT_ALLOWED_ERROR)
          .add_parameter("{{ width }}", image_size.width)
          .add_parameter("{{ height }}", image_size.height)
          .add
      end
    end
  end
end
