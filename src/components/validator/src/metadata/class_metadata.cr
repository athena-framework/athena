require "./generic_metadata"

# Represents metadata associated with an `AVD::Validatable` instance.
#
# `self` is lazily initialized and cached at the class level.
#
# Includes metadata about the class; such as its name, constraints, etc.
class Athena::Validator::Metadata::ClassMetadata(T)
  include Athena::Validator::Metadata::GenericMetadata

  # Builds `self`, auto registering any annotation based annotations on `T`,
  # as well as those registered via `T.load_metadata`.
  def self.build : self
    class_metadata = new

    {% begin %}
      # Add property constraints
      {% for ivar, idx in T.instance_vars %}
        {% for constraint in AVD::Constraint.all_subclasses.reject &.abstract? %}
          {% ann_name = constraint.name(generic_args: false).split("::").last.id %}

          {% if ann = ivar.annotation Assert.constant(ann_name).resolve %}
            {% default_arg = ann.args.empty? ? nil : ann.args.first %}

            {% if default_arg.is_a? ArrayLiteral %}
              {% default_arg = default_arg.map do |arg|
                   if arg.is_a? Annotation
                     arg_name = arg.stringify.gsub(/@\[/, "").gsub(/\(.*/, "").split("::").last.gsub(/\]/, "")

                     inner_default_arg = arg.args.empty? ? nil : arg.args.first

                     # Support only 2 levels deep for now.
                     inner_default_arg = if inner_default_arg.is_a? ArrayLiteral
                                           inner_default_arg.map do |inner_arg|
                                             if inner_arg.is_a? Annotation
                                               inner_arg_name = inner_arg.stringify.gsub(/@\[/, "").gsub(/\(.*/, "").split("::").last.gsub(/\]/, "")

                                               inner_inner_default_arg = inner_arg.args.empty? ? nil : inner_arg.args.first

                                               %(AVD::Constraints::#{inner_arg_name.id}.new(#{inner_inner_default_arg ? "#{inner_inner_default_arg},".id : "".id}#{inner_arg.named_args.double_splat})).id
                                             else
                                               inner_arg
                                             end
                                           end
                                         else
                                           inner_default_arg
                                         end

                     # Hack this to work correctly for now.
                     if arg_name == "All" || arg_name == "AtLeastOneOf"
                       inner_default_arg = "#{inner_default_arg} of AVD::Constraint".id
                     end

                     # Resolve constraints from the annotations,
                     # TODO: Figure out a better way to do this.
                     %(AVD::Constraints::#{arg_name.id}.new(#{inner_default_arg ? "#{inner_default_arg},".id : "".id}#{arg.named_args.double_splat})).id
                   else
                     arg
                   end
                 end %}
            {% end %}

            class_metadata.add_property_constraint(
              AVD::Metadata::PropertyMetadata(T, {{idx}}).new({{ivar.name.stringify}}),
              {{constraint.name(generic_args: false).id}}.new(
                {{ default_arg ? "#{default_arg},".id : "".id }} # Default argument
                {{ ann.named_args.double_splat }}
              )
            )
          {% end %}
        {% end %}
      {% end %}

      # Add getter constraints
      {% for m, idx in T.methods %}
        {% for constraint in AVD::Constraint.all_subclasses.reject &.abstract? %}
          {% ann_name = constraint.name(generic_args: false).split("::").last.id %}

          {% if ann_name != "Callback" && (ann = m.annotation Assert.constant(ann_name).resolve) %}
            {% default_arg = ann.args.empty? ? nil : ann.args.first %}

            class_metadata.add_getter_constraint(
              AVD::Metadata::GetterMetadata(T, {{idx}}).new({{m.name.stringify}}),
              {{constraint.name(generic_args: false).id}}.new(
                {{ default_arg ? "#{default_arg},".id : "".id }} # Default argument
                {{ ann.named_args.double_splat }}
              )
            )
          {% end %}
        {% end %}
      {% end %}

      # Add callback constraints
      {% for callback in T.methods.select &.annotation(Assert::Callback) %}
        class_metadata.add_constraint AVD::Constraints::Callback.new(callback_name: {{callback.name.stringify}}, {{callback.annotation(Assert::Callback).named_args.double_splat}})
      {% end %}

      {% for callback in T.class.methods.select &.annotation(Assert::Callback) %}
        class_metadata.add_constraint AVD::Constraints::Callback.new(callback: ->T.{{callback.name.id}}(AVD::Constraints::Callback::ValueContainer, AVD::ExecutionContextInterface, Hash(String, String)?), {{callback.annotation(Assert::Callback).named_args.double_splat}})
      {% end %}
    {% end %}

    # Also support adding constraints via code
    {% if T.class.has_method? :load_metadata %}
      T.load_metadata class_metadata
    {% end %}

    # Check for group sequences
    {% if group_sequence = T.annotation Assert::GroupSequence %}
      class_metadata.group_sequence = [{{group_sequence.args.splat}}]
    {% end %}

    class_metadata
  end

  # The `#class_name` based group for `self`.
  getter default_group : String

  # The `AVD::Constraints::GroupSequence` used by `self`, if any.
  getter group_sequence : AVD::Constraints::GroupSequence? = nil

  @getters : Hash(String, AVD::Metadata::PropertyMetadataInterface) = Hash(String, AVD::Metadata::PropertyMetadataInterface).new
  @members : Hash(String, Array(AVD::Metadata::PropertyMetadataInterface)) = Hash(String, Array(AVD::Metadata::PropertyMetadataInterface)).new
  @properties : Hash(String, AVD::Metadata::PropertyMetadataInterface) = Hash(String, AVD::Metadata::PropertyMetadataInterface).new

  def initialize
    @default_group = T.to_s
  end

  def class_name : T.class
    T
  end

  # Adds each of the provided *constraints* to `self`.
  def add_constraint(constraints : Array(AVD::Constraint)) : self
    constraints.each do |c|
      self.add_constraint c
    end

    self
  end

  # :inherit:
  #
  # Also adds the `#class_name` based group via `AVD::Constraint#add_implicit_group`.
  def add_constraint(constraint : AVD::Constraint) : self
    constraint.add_implicit_group @default_group

    super constraint

    self
  end

  # Adds the provided *constraint* to the provided *method_name*.
  def add_getter_constraint(method_name : String, constraint : AVD::Constraint) : self
    self.add_getter_constraint AVD::Metadata::GetterMetadata(T, Nil).new(method_name), constraint
  end

  # Adds a hash of constraints to `self`, where the keys represent the property names, and the value
  # is the constraint/array of constraints to add.
  def add_property_constraints(property_hash : Hash(String, AVD::Constraint | Array(AVD::Constraint))) : self
    property_hash.each do |property_name, constraints|
      self.add_property_constraint property_name, constraints
    end

    self
  end

  # Adds each of the provided *constraints* to the provided *property_name*.
  def add_property_constraint(property_name : String, constraints : Array(AVD::Constraint)) : self
    constraints.each do |c|
      self.add_property_constraint property_name, c
    end

    self
  end

  # Adds the provided *constraint* to the provided *property_name*.
  def add_property_constraint(property_name : String, constraint : AVD::Constraint) : self
    self.add_property_constraint AVD::Metadata::PropertyMetadata(T, Nil).new(property_name), constraint
  end

  # Returns an array of the properties who `self` has constraints defined for.
  def constrained_properties : Array(String)
    @members.keys
  end

  # Sets the `AVD::Constraints::GroupSequence` that should be used for `self`.
  #
  # Raises an `ArgumentError` if `self` is an `AVD::Constraints::GroupSequence::Provider`,
  # the *sequence* contains `AVD::Constraint::DEFAULT_GROUP`,
  # or the `#class_name` based group is missing.
  def group_sequence=(sequence : Array(String) | AVD::Constraints::GroupSequence) : self
    raise ArgumentError.new "Defining a static group sequence is not allowed with a group sequence provider." if @group_sequence_provider

    if sequence.is_a? Array
      sequence = AVD::Constraints::GroupSequence.new sequence
    end

    if sequence.groups.includes? AVD::Constraint::DEFAULT_GROUP
      raise ArgumentError.new "The group '#{AVD::Constraint::DEFAULT_GROUP}' is not allowed in group sequences."
    end

    unless sequence.groups.includes? @default_group
      raise ArgumentError.new "The group '#{@default_group}' is missing from the group sequence."
    end

    @group_sequence = sequence

    self
  end

  # Denotes `self` as a `AVD::Constraints::GroupSequence::Provider`.
  def group_sequence_provider=(active : Bool) : Nil
    raise ArgumentError.new "Defining a group sequence provider is not allowed with a static group sequence." unless @group_sequence.nil?
    # TODO: ensure `T` implements the module interface
    @group_sequence_provider = active
  end

  # Returns `true` if `self` has property metadata for the provided *property_name*.
  def has_property_metadata?(property_name : String) : Bool
    @members.has_key? property_name
  end

  # Returns an `AVD::Metadata::PropertyMetadataInterface` instance for the provided *property_name*, if any.
  def property_metadata(property_name : String) : Array(AVD::Metadata::PropertyMetadataInterface)
    @members.fetch(property_name) { [] of AVD::Metadata::PropertyMetadataInterface }
  end

  def name : String?
    nil
  end

  protected def add_getter_constraint(getter_metadata : AVD::Metadata::PropertyMetadataInterface, constraint : AVD::Constraint) : self
    unless @getters.has_key? getter_metadata.name
      @getters[getter_metadata.name] = getter_metadata

      self.add_property_metadata getter_metadata
    end

    constraint.add_implicit_group @default_group

    @getters[getter_metadata.name].add_constraint constraint

    self
  end

  protected def add_property_constraint(property_metadata : AVD::Metadata::PropertyMetadataInterface, constraint : AVD::Constraint) : self
    unless @properties.has_key? property_metadata.name
      @properties[property_metadata.name] = property_metadata

      self.add_property_metadata property_metadata
    end

    constraint.add_implicit_group @default_group

    @properties[property_metadata.name].add_constraint constraint

    self
  end

  protected def invoke_callback(name : String, object : AVD::Validatable, context : AVD::ExecutionContextInterface, payload : Hash(String, String)?) : Nil
    {% begin %}
      case name
        {% for callback in T.methods.select &.annotation(Assert::Callback) %}
          when {{callback.name.stringify}}
            if object.responds_to?({{callback.name.id.symbolize}})
              object.{{callback.name.id}}(context, payload)
            end
        {% end %}
      else
        raise "BUG: Unknown method #{name} within #{T}"
      end
    {% end %}
  end

  private def add_property_metadata(metadata : AVD::Metadata::PropertyMetadataInterface) : Nil
    (@members[metadata.name] ||= Array(AVD::Metadata::PropertyMetadataInterface).new) << metadata
  end
end
