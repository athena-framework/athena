require "athena-mime"
require "athena-http"

# Validates that a value is a valid file.
# If the underlying value is a [::File](https://crystal-lang.org/api/File.html), then its path is used as the value.
# Otherwise the value is converted to a string via `#to_s` before being validated, which is assumed to be a path to a file.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ```
# class Profile
#   include AVD::Validatable
#
#   def initialize(@resume : ::File); end
#
#   @[Assert::File]
#   property resume : ::File
# end
# ```
#
# # Configuration
#
# ## Optional Arguments
#
# ### max_size
#
# **Type:** `Int | String | Nil` **Default:** `nil`
#
# Defines that maximum size the file must be in order to be considered valid.
# The value may be an integer representing the size in bytes, or a format string in one of the following formats:
#
# | Suffix | Unit Name | Value           | Example |
# | :----- | :-------- | :-------------- | :------ |
# | (none) | byte      | 1 byte          | `4096`  |
# | `k`    | kilobyte  | 1,000 bytes     | `"200k"`  |
# | `M`    | megabyte  | 1,000,000 bytes | `"2M"`    |
# | `Ki`   | kibibyte  | 1,024 bytes     | `"32Ki"`  |
# | `Mi`   | mebibyte  | 1,048,576 bytes | `"8Mi"`   |
#
# ### mime_types
#
# **Type:** `Enumerable(String)?` **Default:** `nil`
#
# If set, allows checking that the MIME type of the file is one of an allowed set of types.
# This value is ignored if the MIME type of the file could not be determined.
#
# ### binary_format
#
# **Type:** `Bool?` **Default:** `nil`
#
# When `true`, the sizes will be displayed in messages with binary-prefixed units (KiB, MiB).
# When `false`, the sizes will be displayed with SI-prefixed units (kB, MB).
# When `nil`, then the binaryFormat will be guessed from the value defined in the [max_size](#max_size) option.
#
# ### max_size_message
#
# **Type:** `String` **Default:** `The file is too large ({{ size }} {{ suffix }}). Allowed maximum size is {{ limit }} {{ suffix }}.`
#
# The message that will be shown if the file is greater than the [max_size](#max_size).
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ file }}` - Absolute path to the invalid file.
# * `{{ limit }}` - Maximum file size allowed.
# * `{{ name }}` - Basename of the invalid file.
# * `{{ size }}` - The size of the invalid file.
# * `{{ suffix }}` - Suffix for the used file size unit.
#
# ### not_found_message
#
# **Type:** `String` **Default:** `The file could not be found.`
#
# The message that will be shown if no file could be found at the given path.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ file }}` - Absolute path to the invalid file.
#
# ### empty_message
#
# **Type:** `String` **Default:** `An empty file is not allowed.`
#
# The message that will be shown if the file is empty.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ file }}` - Absolute path to the invalid file.
# * `{{ name }}` - Basename of the invalid file.
#
# ### not_readable_message
#
# **Type:** `String` **Default:** `The file is not readable.`
#
# The message that will be shown if the file is not readable.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ file }}` - Absolute path to the invalid file.
# * `{{ name }}` - Basename of the invalid file.
#
# ### mime_type_message
#
# **Type:** `String` **Default:** `The mime type of the file is invalid ({{ type }}). Allowed mime types are {{ types }}.`
#
# The message that will be shown if the MIME type of the file is not one of the valid [mime_types](#mime_types).
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ file }}` - Absolute path to the invalid file.
# * `{{ name }}` - Basename of the invalid file.
# * `{{ type }}` - The MIME type of the invalid file.
# * `{{ types }}` - The list of allowed MIME types.
#
# ### upload_file_size_message
#
# **Type:** `String` **Default:** `The file is too large. Allowed maximum size is {{ limit }} {{ suffix }}.`
#
# The message that will be shown if the uploaded file is larger than the configured [max allowed size](/Framework/Bundle/Schema/FileUploads/#Athena::Framework::Bundle::Schema::FileUploads#max_file_size).
# See the [Getting Started](/getting_started/routing/#file-uploads) docs for more information.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ limit }}` - The maximum file size allowed.
# * `{{ suffix }}` - Suffix for the used file size unit.
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
class Athena::Validator::Constraints::File < Athena::Validator::Constraint
  NOT_FOUND_ERROR         = "b6ae563c-4aec-4dfa-b268-2bb282912ed8"
  NOT_READABLE_ERROR      = "e9f18a3d-f968-469f-868e-2331c8c982c2"
  EMPTY_ERROR             = "de1a4b3c-a69f-46bd-b017-4a60361a1765"
  TOO_LARGE_ERROR         = "4ce61d7c-43a0-44c2-bfe0-a59072b6cd17"
  INVALID_MIME_TYPE_ERROR = "96c8591c-e990-48f6-b82b-75c878ae9fd9"
  UPLOAD_FILE_SIZE_ERROR  = "6b06e7c7-2f21-46ef-b6ec-1dac08a1af7e"

  private KB_BYTES  =     1_000
  private MB_BYTES  = 1_000_000
  private KIB_BYTES =     1_024
  private MIB_BYTES = 1_048_576

  private SUFFICES = {
            1 => "bytes",
    KB_BYTES  => "kB",
    MB_BYTES  => "MB",
    KIB_BYTES => "KiB",
    MIB_BYTES => "MiB",
  }

  @@error_names = {
    NOT_FOUND_ERROR         => "NOT_FOUND_ERROR",
    NOT_READABLE_ERROR      => "NOT_READABLE_ERROR",
    EMPTY_ERROR             => "EMPTY_ERROR",
    TOO_LARGE_ERROR         => "TOO_LARGE_ERROR",
    INVALID_MIME_TYPE_ERROR => "INVALID_MIME_TYPE_ERROR",
    UPLOAD_FILE_SIZE_ERROR  => "UPLOAD_FILE_SIZE_ERROR",
  }

  getter not_found_message : String
  getter not_readable_message : String
  getter empty_message : String
  getter max_size_message : String
  getter mime_type_message : String

  getter upload_file_size_message : String

  getter max_size : Int64?
  getter mime_types : Set(String)?
  getter! binary_format : Bool?

  def initialize(
    max_size : Int | String | Nil = nil,
    @binary_format : Bool? = nil,
    mime_types : Enumerable(String)? = nil,

    @not_found_message : String = "The file could not be found.",
    @not_readable_message : String = "The file is not readable.",
    @empty_message : String = "An empty file is not allowed.",
    @max_size_message : String = "The file is too large ({{ size }} {{ suffix }}). Allowed maximum size is {{ limit }} {{ suffix }}.",
    @mime_type_message : String = "The mime type of the file is invalid ({{ type }}). Allowed mime types are {{ types }}.",

    @upload_file_size_message : String = "The file is too large. Allowed maximum size is {{ limit }} {{ suffix }}.",

    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super "", groups, payload

    mime_types.try do |types|
      @mime_types = types.to_set
    end

    max_size.try do |bytes|
      @max_size = self.normalize_binary_format bytes
    end
  end

  private def normalize_binary_format(max_size : Int) : Int64
    @binary_format = @binary_format.nil? ? false : @binary_format
    max_size.to_i64
  end

  private def normalize_binary_format(max_size : String) : Int64
    if number = max_size.to_i64?
      return self.normalize_binary_format number
    end

    factors = {
      "k"  => 1_000,
      "ki" => 1 << 10,
      "m"  => 1000 * 1000,
      "mi" => 1 << 20,
      "g"  => 1000 * 1000 * 1000,
      "gi" => 1 << 30,
    }

    if match = max_size.match /^(\d++)(#{factors.each_key.join('|')})$/i
      unit = match[2].downcase
      @binary_format = @binary_format.nil? ? 2 == unit.size : @binary_format
      return match[1].to_i64 * factors[unit].to_i64
    end

    raise AVD::Exception::InvalidArgument.new "'#{max_size}' is not a valid maximum size."
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    #
    # ameba:disable Metrics/CyclomaticComplexity
    def validate(value : _, constraint : AVD::Constraints::File) : Nil
      return if value.nil? || value == ""

      if value.is_a?(Athena::HTTP::UploadedFile) && !value.valid?
        case value.status
        when .size_limit_exceeded?
          max_allowed_file_size = Athena::HTTP::UploadedFile.max_file_size
          if (constraint_max_size = constraint.max_size) && (constraint_max_size < max_allowed_file_size)
            limit_in_bytes = constraint_max_size
            binary_format = constraint.binary_format
          else
            limit_in_bytes = max_allowed_file_size
            binary_format = (bf = constraint.binary_format?).nil? ? true : bf
          end

          _, limit_as_string, suffix = self.factorize_sizes 0, limit_in_bytes, binary_format

          self
            .context
            .build_violation(constraint.upload_file_size_message, UPLOAD_FILE_SIZE_ERROR)
            .add_parameter("{{ limit }}", limit_as_string)
            .add_parameter("{{ suffix }}", suffix)
            .add

          return
        end
      end

      path = case value
             when Path                               then value
             when ::File, Athena::HTTP::AbstractFile then value.path
             else
               value.to_s
             end

      unless ::File.file? path
        self
          .context
          .build_violation(constraint.not_found_message, NOT_FOUND_ERROR)
          .add_parameter("{{ file }}", path)
          .add

        return
      end

      unless ::File::Info.readable? path
        self
          .context
          .build_violation(constraint.not_readable_message, NOT_READABLE_ERROR)
          .add_parameter("{{ file }}", path)
          .add

        return
      end

      size_in_bytes = ::File.size path
      base_name = value.is_a?(Athena::HTTP::UploadedFile) ? value.client_original_name : ::File.basename path

      if size_in_bytes.zero?
        self
          .context
          .build_violation(constraint.empty_message, EMPTY_ERROR)
          .add_parameter("{{ file }}", path)
          .add_parameter("{{ name }}", base_name)
          .add

        return
      end

      if (max_size_in_bytes = constraint.max_size) && size_in_bytes > max_size_in_bytes
        size_as_string, limit_as_string, suffix = self.factorize_sizes size_in_bytes, max_size_in_bytes, constraint.binary_format

        self
          .context
          .build_violation(constraint.max_size_message, TOO_LARGE_ERROR)
          .add_parameter("{{ file }}", path)
          .add_parameter("{{ size }}", size_as_string)
          .add_parameter("{{ limit }}", limit_as_string)
          .add_parameter("{{ suffix }}", suffix)
          .add_parameter("{{ name }}", base_name)
          .add

        return
      end

      if mime_types = constraint.mime_types
        mime = if value.is_a? Athena::HTTP::AbstractFile
                 value.mime_type
               else
                 AMIME::Types.default.guess_mime_type path
               end

        if mime
          mime_types.each do |mime_type|
            return if mime == mime_type

            t, matched, _ = mime_type.partition "/*"

            unless matched.blank?
              t2, _, _ = mime.partition "/"

              return if t2 == t
            end
          end
        end

        self
          .context
          .build_violation(constraint.mime_type_message, INVALID_MIME_TYPE_ERROR)
          .add_parameter("{{ file }}", path)
          .add_parameter("{{ type }}", mime)
          .add_parameter("{{ types }}", mime_types)
          .add_parameter("{{ name }}", base_name)
          .add
      end
    end

    private def more_decimals_than(double : String, number_of_decimals : Int) : Bool
      double.size > double.to_f.round(2).to_s.size
    end

    # TODO: Can we use `#humaize_bytes` for this?
    def factorize_sizes(size : Int, limit : Int, binary_format : Bool) : Tuple(String, String, String)
      coef, coef_factor = binary_format ? {MIB_BYTES, KIB_BYTES} : {MB_BYTES, KB_BYTES}

      # If limit < coef, limit_as_string could be < 1 with less than 3 decimals.
      # In this case, we would end up displaying an allowed size < 1 (eg: 0.1 MB).
      # It looks better to keep on factorizing (to display 100 kB for example).
      while limit < coef
        coef /= coef_factor
      end

      limit_as_string = (limit / coef).to_s

      while self.more_decimals_than limit_as_string, 2
        coef /= coef_factor
        limit_as_string = (limit / coef).to_s
      end

      size_as_string = (size / coef).round(2).to_s

      while size_as_string == limit_as_string
        coef /= coef_factor
        limit_as_string = (limit / coef).to_s
        size_as_string = (size / coef).round(2).to_s
      end

      {size_as_string, limit_as_string, SUFFICES[coef]}
    end
  end
end
