require "mime"

class Athena::Validator::Constraints::File < Athena::Validator::Constraint
  NOT_FOUND_ERROR         = "b6ae563c-4aec-4dfa-b268-2bb282912ed8"
  NOT_READABLE_ERROR      = "e9f18a3d-f968-469f-868e-2331c8c982c2"
  EMPTY_ERROR             = "de1a4b3c-a69f-46bd-b017-4a60361a1765"
  TOO_LARGE_ERROR         = "4ce61d7c-43a0-44c2-bfe0-a59072b6cd17"
  INVALID_MIME_TYPE_ERROR = "96c8591c-e990-48f6-b82b-75c878ae9fd9"

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
  }

  getter not_found_message : String
  getter not_readable_message : String
  getter empty_message : String
  getter max_size_message : String
  getter mime_type_message : String

  getter max_size : Int64?
  getter mime_types : Set(String)?

  @binary_format : Bool?

  def initialize(
    max_size : Int | String | Nil = nil,
    @not_found_message : String = "The file could not be found.",
    @not_readable_message : String = "The file is not readable.",
    @empty_message : String = "An empty file is not allowed.",
    @max_size_message : String = "The file is too large ({{ size }} {{ suffix }}). Allowed maximum size is {{ limit }} {{ suffix }}.",
    @mime_type_message : String = "The mime type of the file is invalid ({{ type }}). Allowed mime types are {{ types }}.",
    mime_types : Enumerable(String)? = nil,
    @binary_format : Bool? = nil,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super "", groups, payload

    mime_types.try do |types|
      @mime_types = types.to_set
    end

    max_size.try do |bytes|
      @max_size = self.normalize_binary_format bytes
    end
  end

  def binary_format? : Bool
    @binary_format.not_nil!
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

    raise ArgumentError.new "'#{max_size}' is not a valid maximum size."
  end

  struct Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::File) : Nil
      return if value.nil? || value == ""

      # TODO: Support UploadedFile

      path = case value
             when Path   then value
             when ::File then value.path
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

      unless ::File.readable? path
        self
          .context
          .build_violation(constraint.not_readable_message, NOT_READABLE_ERROR)
          .add_parameter("{{ file }}", path)
          .add

        return
      end

      size_in_bytes = ::File.size path
      base_name = ::File.basename path

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
        size_as_string, limit_as_string, suffix = self.factorize_sizes size_in_bytes, max_size_in_bytes, constraint.binary_format?

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

      if (mime_types = constraint.mime_types) && (mime = MIME.from_filename? path)
        mime_types.each do |mime_type|
          return if mime == mime_type

          t, matched, st = mime_type.partition "/*"

          unless matched.blank?
            t2, _, st2 = mime.partition "/"

            return if t2 == t
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
