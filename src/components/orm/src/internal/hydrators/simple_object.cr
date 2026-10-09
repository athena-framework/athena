# :nodoc:
class Athena::ORM::Internal::Hydrators::SimpleObject < Athena::ORM::Internal::Hydrators::Abstract
  private getter! class_metadata : Mapping::ClassInterface

  protected def prepare : Nil
    raise "Cannot use SimpleObject with an RSM that contains more than one object result" if self.rsm.alias_map.size != 1
    raise "Cannot use SimpleObject Hydrator with a RSM that contains scalar mappings" unless self.rsm.scalar_mappings.empty?

    @class_metadata = self.class_metadata(self.rsm.alias_map.first_value)
  end

  protected def hydrate_all_data : Array(AORM::Entity)
    result = [] of AORM::Entity

    self.rs.each do
      self.hydrate_row_data result
    end

    # TODO: Trigger eager loads

    result
  end

  # Reads the current row directly from the cursor, building the field-keyed
  # hash for entity instantiation as it goes. The cursor invariant from
  # `Abstract#gather_row_data` applies: every column must be consumed.
  protected def hydrate_row_data(result : Array(AORM::Entity)) : Nil
    entity_class = self.class_metadata.entity_class
    data = Hash(String, Mapping::Value).new

    # TODO: Handle discriminator mappings
    unless self.class_metadata.inheritance_type.none?
      raise "TODO: Handle discriminator mappings"
    end

    self.rs.column_names.each do |column|
      if self.rsm.relation_map.has_key? column
        raise "Unable to retrieve association information for column '#{column}."
      end

      cache_key_info = self.hydrate_column_info column

      unless cache_key_info
        # Unmapped column — must still be consumed to keep the cursor aligned.
        self.rs.read
        next
      end

      # TODO: Handle discriminator values

      type = cache_key_info.type
      value = type ? type.read_value(self.rs, @platform) : self.rs.read.as(DB::Any)

      field_name = cache_key_info.field_name

      # Prevent overwrite in case of inherit classes using same property name (See AbstractHydrator)
      if !data.has_key?(field_name) || !value.nil?
        data[field_name] = Mapping::SingleValue.new value
      end
    end

    # TODO: handle refresh hint

    uow = @em.unit_of_work
    entity = uow.create_entity entity_class, data, @hints

    result << entity

    # TODO: handle internal iteration hint
  end

  protected def cleanup : Nil
    super

    # TODO: Trigger eager loads
  end
end
