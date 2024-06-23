# The container that stores various `ACON::Helper::Interface` implementations, keyed by their class.
#
# Each application includes a default helper set, but additional ones may be added.
# See `ACON::Application#helper_set`.
#
# These helpers can be accessed from within a command via the `ACON::Command#helper` method.
class Athena::Console::Helper::HelperSet
  @helpers = Hash(ACON::Helper.class, ACON::Helper::Interface).new

  def self.new(*helpers : ACON::Helper::Interface) : self
    helper_set = new
    helpers.each do |helper|
      helper_set << helper
    end
    helper_set
  end

  def initialize(@helpers : Hash(ACON::Helper.class, ACON::Helper::Interface) = Hash(ACON::Helper.class, ACON::Helper::Interface).new); end

  # Adds the provided *helper* to `self`.
  def <<(helper : ACON::Helper::Interface) : Nil
    @helpers[helper.class] = helper

    helper.helper_set = self
  end

  # Returns `true` if `self` has a helper for the provided *helper_class*, otherwise `false`.
  def has?(helper_class : ACON::Helper.class) : Bool
    @helpers.has_key? helper_class
  end

  # Returns the helper of the provided *helper_class*, or `nil` if it is not defined.
  def []?(helper_class : T.class) : T? forall T
    {% T.raise "Helper class type '#{T}' is not an 'ACON::Helper::Interface'." unless T <= ACON::Helper::Interface %}

    @helpers[helper_class]?.as? T
  end

  # Returns the helper of the provided *helper_class*, or raises if it is not defined.
  def [](helper_class : T.class) : T forall T
    self.[helper_class]? || raise ACON::Exception::InvalidArgument.new "The helper '#{helper_class}' is not defined."
  end
end
