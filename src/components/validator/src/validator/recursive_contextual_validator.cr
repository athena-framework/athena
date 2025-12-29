# A recursive implementation of `AVD::Validator::ContextualValidatorInterface`.
#
# See `Athena::Validator.validator`.
class Athena::Validator::Validator::RecursiveContextualValidator
  private alias GroupsTypes = Array(String) | Array(String | AVD::Constraints::GroupSequence)

  include Athena::Validator::Validator::ContextualValidatorInterface

  @default_groups : Array(String)
  @default_property_path : String

  def initialize(
    @context : AVD::ExecutionContextInterface,
    @constraint_validator_factory : AVD::ConstraintValidatorFactoryInterface,
    @metadata_factory : AVD::Metadata::MetadataFactoryInterface,
  )
    @default_groups = [(g = @context.group) ? g : Constraint::DEFAULT_GROUP]
    @default_property_path = @context.property_path
  end

  # :inherit:
  def at_path(path : String) : AVD::Validator::ContextualValidatorInterface
    @default_property_path = @context.property_path path

    self
  end

  # :inherit:
  def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
    groups = self.normalize_groups groups

    previous_value = @context.value
    previous_object = @context.object
    previous_metadata = @context.metadata
    previous_path = @context.property_path
    previous_group = @context.group
    previous_constraint = @context.is_a?(AVD::ExecutionContext) ? @context.constraint : nil

    # Validate the value against explicitly passed constraints
    unless constraints.nil?
      constraints = constraints.is_a?(Array) ? constraints : [constraints]

      metadata = AVD::Metadata::Metadata.new
      metadata.add_constraints constraints

      self.validate_generic_node(
        value,
        previous_object,
        metadata,
        @default_property_path,
        groups,
        nil,
        @context
      )

      @context.set_node previous_value, previous_object, previous_metadata, previous_path
      @context.group = previous_group

      unless previous_constraint.nil?
        @context.constraint = previous_constraint
      end

      return self
    end

    case value
    when AVD::Validatable
      self.validate_object(
        value,
        @default_property_path,
        groups,
        @context
      )

      @context.set_node previous_value, previous_object, previous_metadata, previous_path
      @context.group = previous_group

      self
    when Iterable, Hash
      self.validate_each_object_in(
        value,
        @default_property_path,
        groups,
        @context
      )

      @context.set_node previous_value, previous_object, previous_metadata, previous_path
      @context.group = previous_group

      self
    when Athena::HTTP::UploadedFile
      # Won't result in violations, but is still supported explicitly.

      self
    else
      raise AVD::Exception::InvalidArgument.new "Could not validate values of type '#{value.class}' automatically.  Please provide a constraint."
    end
  end

  # :inherit:
  def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
    groups = self.normalize_groups groups

    class_metadata = @metadata_factory.metadata object
    property_metadatas = class_metadata.property_metadata property_name

    property_path = AVD::PropertyPath.append @default_property_path, property_name

    previous_value = @context.value
    previous_object = @context.object
    previous_metadata = @context.metadata
    previous_path = @context.property_path
    previous_group = @context.group

    property_metadatas.each do |property_metadata|
      property_value = property_metadata.value object

      self.validate_generic_node(
        property_value,
        object,
        property_metadata,
        property_path,
        groups,
        nil,
        @context
      )
    end

    @context.set_node previous_value, previous_object, previous_metadata, previous_path
    @context.group = previous_group

    self
  end

  # :inherit:
  def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
    groups = self.normalize_groups groups

    class_metadata = @metadata_factory.metadata object
    property_metadatas = class_metadata.property_metadata property_name

    property_path = AVD::PropertyPath.append @default_property_path, property_name

    previous_value = @context.value
    previous_object = @context.object
    previous_metadata = @context.metadata
    previous_path = @context.property_path
    previous_group = @context.group

    property_metadatas.each do |property_metadata|
      self.validate_generic_node(
        value,
        object,
        property_metadata,
        property_path,
        groups,
        nil,
        @context
      )
    end

    @context.set_node previous_value, previous_object, previous_metadata, previous_path
    @context.group = previous_group

    self
  end

  # :inherit:
  def violations : AVD::Violation::ConstraintViolationListInterface
    @context.violations
  end

  private def validate_each_object_in(
    collection : Iterable,
    property_path : String,
    groups : GroupsTypes,
    context : AVD::ExecutionContextInterface,
  )
    collection.each_with_index do |item, idx|
      case item
      when Iterable, Hash   then self.validate_each_object_in(item, "#{property_path}[#{idx}]", groups, context)
      when AVD::Validatable then self.validate_object(item, "#{property_path}[#{idx}]", groups, context)
      end
    end
  end

  private def validate_each_object_in(
    collection : Hash,
    property_path : String,
    groups : GroupsTypes,
    context : AVD::ExecutionContextInterface,
  )
    collection.each do |key, value|
      case value
      when Iterable, Hash   then self.validate_each_object_in(value, "#{property_path}[#{key}]", groups, context)
      when AVD::Validatable then self.validate_object(value, "#{property_path}[#{key}]", groups, context)
      end
    end
  end

  private def validate_generic_node(
    value : _,
    object : _,
    metadata : AVD::Metadata::MetadataInterface?,
    property_path : String,
    groups : GroupsTypes,
    cascaded_groups : Array(String)?,
    context : AVD::ExecutionContextInterface,
  )
    context.set_node value, object, metadata, property_path

    groups.each_with_index do |group, idx|
      if group.is_a? AVD::Constraints::GroupSequence
        self.step_through_group_sequence(
          value,
          object,
          metadata,
          property_path,
          group,
          nil,
          context
        )

        groups.delete_at idx

        next
      end

      self.validate_in_group value, metadata, group, context
    end

    return if groups.empty?
    return if value.nil?

    return unless metadata.cascading_strategy.cascade?

    cascaded_groups = !cascaded_groups.nil? && cascaded_groups.size > 0 ? cascaded_groups : groups

    case value
    when Iterable
      self.validate_each_object_in(
        value,
        property_path,
        cascaded_groups,
        context
      )
    when AVD::Validatable
      self.validate_object(
        value,
        property_path,
        cascaded_groups,
        context
      )
    end
  end

  private def validate_object(object : AVD::Validatable, property_path : String, groups : GroupsTypes, context : AVD::ExecutionContextInterface) : Nil
    self.validate_class_node(
      object,
      @metadata_factory.metadata(object),
      property_path,
      groups,
      nil,
      context
    )
  end

  private def validate_class_node(
    object : AVD::Validatable,
    class_metadata : AVD::Metadata::ClassMetadata,
    property_path : String,
    groups : GroupsTypes,
    cascaded_groups : Array(String)?,
    context : AVD::ExecutionContextInterface,
  ) : Nil
    context.set_node object, object, class_metadata, property_path

    groups.each_with_index do |group, idx|
      # Handle cascading to the "default" group if a GroupSequence is used.
      default_overridden = false

      # Replace the "default" group by the group sequence if applicable.
      if AVD::Constraint::DEFAULT_GROUP == group
        if group_sequence = class_metadata.group_sequence
          group = group_sequence
          default_overridden = true
        elsif object.is_a? AVD::Constraints::GroupSequence::Provider
          group = object.group_sequence
          default_overridden = true

          unless group.is_a? AVD::Constraints::GroupSequence
            group = AVD::Constraints::GroupSequence.new group
          end
        end
      end

      if group.is_a? AVD::Constraints::GroupSequence
        self.step_through_group_sequence(
          object,
          object,
          class_metadata,
          property_path,
          group,
          default_overridden ? AVD::Constraint::DEFAULT_GROUP : nil,
          context
        )

        groups.delete_at idx

        next
      end

      # TODO: Can cache validated groups here if needed in the future
      self.validate_in_group object, class_metadata, group, context
    end

    return if groups.empty?

    class_metadata.constrained_properties.each do |property_name|
      # A constraint can be applied to a property and getter of that property,
      # thus resulting in two metadata objects being returned.
      class_metadata.property_metadata(property_name).each do |property_metadata|
        property_value = property_metadata.value object

        self.validate_generic_node(
          property_value,
          object,
          property_metadata,
          AVD::PropertyPath.append(property_path, property_name),
          groups,
          cascaded_groups,
          context
        )
      end
    end

    return unless object.is_a? Iterable

    self.validate_each_object_in(
      object,
      property_path,
      groups,
      context
    )
  end

  private def step_through_group_sequence(
    value : _,
    object : _,
    metadata : AVD::Metadata::MetadataInterface?,
    property_path : String,
    group_sequence : AVD::Constraints::GroupSequence,
    cascaded_groups : String?,
    context : AVD::ExecutionContextInterface,
  ) : Nil
    violation_count = context.violations.size
    cascaded_groups = cascaded_groups ? [cascaded_groups] : nil

    group_sequence.groups.each do |group_in_sequence|
      groups = group_in_sequence.is_a?(Array) ? group_in_sequence : [group_in_sequence]

      if metadata.is_a? AVD::Metadata::ClassMetadata
        self.validate_class_node(
          value,
          metadata,
          property_path,
          groups,
          cascaded_groups,
          context
        )
      else
        self.validate_generic_node(
          value,
          object,
          metadata,
          property_path,
          groups,
          cascaded_groups,
          context
        )
      end

      # Don't validate future groups if a violation was generated
      break if context.violations.size > violation_count
    end
  end

  private def validate_in_group(value : _, metadata : AVD::Metadata::MetadataInterface, group : String, context : AVD::ExecutionContextInterface) : Nil
    context.group = group

    metadata.find_constraints(group).each do |constraint|
      # TODO: Can cache validated groups here if needed in the future
      context.constraint = constraint

      validator = @constraint_validator_factory.validator constraint.validated_by
      validator.context = context

      validator.validate value, constraint
    rescue ex : AVD::Exception::UnexpectedValueError
      context.add_violation "This value should be a valid: {{ type }}", {"{{ type }}" => ex.supported_types}
    end
  end

  private def normalize_groups(groups) : GroupsTypes
    case groups
    in Nil                                     then @default_groups
    in String, AVD::Constraints::GroupSequence then [groups] of String | AVD::Constraints::GroupSequence
    in Array                                   then groups
    end
  end
end
