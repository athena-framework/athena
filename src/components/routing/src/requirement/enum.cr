# Provides an easier way to define a [route requirement][Athena::Routing::Route--parameter-validation] for all, or a subset of, Enum members.
#
# For example:
# ```
# require "athena"
#
# enum Color
#   Red
#   Blue
#   Green
#   Black
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get(
#     "/color/{color}",
#     requirements: {"color" => ART::Requirement::Enum(Color).new},
#   )]
#   def get_color(color : Color) : Color
#     color
#   end
#
#   @[ARTA::Get(
#     "/rgb-color/{color}",
#     requirements: {"color" => ART::Requirement::Enum(Color).new(:red, :green, :blue)},
#   )]
#   def get_rgb_color(color : Color) : Color
#     color
#   end
# end
#
# ATH.run
#
# # GET /color/red  # => "red"
# # GET /color/pink # => 404
# #
# # GET /rgb-color/red   # => "red"
# # GET /rgb-color/green # => "green"
# # GET /rgb-color/blue  # => "blue"
# # GET /rgb-color/black # => 404
# ```
#
# NOTE: This type _ONLY_ supports the string representation of enum members.
struct Athena::Routing::Requirement::Enum(EnumType)
  # Returns the set of allowed enum members, or `nil` if all members are allowed.
  getter members : Set(EnumType)? = nil

  def self.new(*cases : EnumType)
    new cases.to_set
  end

  def initialize(@members : Set(EnumType)? = nil)
    {%
      unless EnumType <= ::Enum
        raise "'#{EnumType}' is not an Enum type."
      end
    %}
  end

  # :nodoc:
  def to_s(io : IO) : Nil
    (@members || EnumType.names).join io, '|' do |member, join_io|
      join_io << Regex.escape member.to_s.underscore
    end
  end
end
