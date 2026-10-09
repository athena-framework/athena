# :nodoc:
#
# Persister for ManyToMany collections.
# Handles insert and delete operations on join tables.
class Athena::ORM::Persisters::Collection::ManyToManyPersister < Athena::ORM::Persisters::Collection::Abstract
  # Deletes all rows from the join table for this collection's owner.
  def delete(collection : AORM::BasePersistentCollection) : Nil
    mapping = collection.association
    return unless mapping.is_a?(AORM::Mapping::ManyToManyOwningSide)

    owner = collection.owner
    return unless owner

    sql = self.get_delete_sql(mapping)
    params = self.get_delete_sql_params(collection, mapping)
    types = self.source_key_column_types mapping

    @connection.execute_statement sql, params, types
  end

  # Updates the join table by processing insert and delete diffs.
  def update(collection : AORM::BasePersistentCollection) : Nil
    mapping = collection.association
    return unless mapping.is_a?(AORM::Mapping::ManyToManyOwningSide)

    owner = collection.owner
    return unless owner

    delete_sql, delete_types = self.get_delete_row_sql(mapping)
    insert_sql, insert_types = self.get_insert_row_sql(mapping)

    # Delete removed elements
    collection.delete_diff.each do |element|
      next unless element.is_a?(AORM::Entity)
      params = self.get_delete_row_sql_params(collection, element, mapping)
      @connection.execute_statement delete_sql, params, delete_types
    end

    # Insert added elements
    collection.insert_diff.each do |element|
      next unless element.is_a?(AORM::Entity)
      params = self.get_insert_row_sql_params(collection, element, mapping)
      @connection.execute_statement insert_sql, params, insert_types
    end
  end

  # Generates SQL to delete all rows for an owner.
  protected def get_delete_sql(mapping : AORM::Mapping::ManyToManyOwningSide) : String
    join_table = mapping.join_table.not_nil!
    columns = mapping.relation_to_source_key_columns.keys

    "DELETE FROM #{join_table.name} WHERE #{columns.map { |c| "#{c} = ?" }.join(" AND ")}"
  end

  # Gets parameters for deleting all rows for an owner.
  protected def get_delete_sql_params(collection : AORM::BasePersistentCollection, mapping : AORM::Mapping::ManyToManyOwningSide) : Array(AORM::Mapping::Value)
    owner = collection.owner.not_nil!
    identifier = @uow.entity_identifier(owner)

    mapping.relation_to_source_key_columns.map do |_join_col, ref_col|
      self.bind_value identifier[ref_col]?
    end
  end

  # Generates SQL to delete a single row, along with the type of each of its parameters.
  protected def get_delete_row_sql(mapping : AORM::Mapping::ManyToManyOwningSide) : {String, Array(String?)}
    join_table = mapping.join_table.not_nil!
    source_columns = mapping.relation_to_source_key_columns.keys
    target_columns = mapping.relation_to_target_key_columns.keys
    all_columns = source_columns + target_columns

    {
      "DELETE FROM #{join_table.name} WHERE #{all_columns.map { |c| "#{c} = ?" }.join(" AND ")}",
      self.source_key_column_types(mapping) + self.target_key_column_types(mapping),
    }
  end

  # Gets parameters for deleting a row.
  protected def get_delete_row_sql_params(collection : AORM::BasePersistentCollection, element : AORM::Entity, mapping : AORM::Mapping::ManyToManyOwningSide) : Array(AORM::Mapping::Value)
    self.collect_join_table_column_params(collection, element, mapping)
  end

  # Generates SQL to insert a single row, along with the type of each of its parameters.
  protected def get_insert_row_sql(mapping : AORM::Mapping::ManyToManyOwningSide) : {String, Array(String?)}
    join_table = mapping.join_table.not_nil!
    source_columns = mapping.relation_to_source_key_columns.keys
    target_columns = mapping.relation_to_target_key_columns.keys
    all_columns = source_columns + target_columns
    placeholders = all_columns.map { "?" }.join(", ")

    {
      "INSERT INTO #{join_table.name} (#{all_columns.join(", ")}) VALUES (#{placeholders})",
      self.source_key_column_types(mapping) + self.target_key_column_types(mapping),
    }
  end

  # Join columns referencing the owner take the type of the owner's column they reference.
  private def source_key_column_types(mapping : AORM::Mapping::ManyToManyOwningSide) : Array(String?)
    source_class = @em.class_metadata mapping.source_entity

    mapping.relation_to_source_key_columns.values.map do |referenced_column|
      PersisterHelper.type_of_column(referenced_column, source_class, @em).as String?
    end
  end

  # Join columns referencing the element take the type of the element's column they reference.
  private def target_key_column_types(mapping : AORM::Mapping::ManyToManyOwningSide) : Array(String?)
    target_class = @em.class_metadata mapping.target_entity

    mapping.relation_to_target_key_columns.values.map do |referenced_column|
      PersisterHelper.type_of_column(referenced_column, target_class, @em).as String?
    end
  end

  # Gets parameters for inserting a row.
  protected def get_insert_row_sql_params(collection : AORM::BasePersistentCollection, element : AORM::Entity, mapping : AORM::Mapping::ManyToManyOwningSide) : Array(AORM::Mapping::Value)
    self.collect_join_table_column_params(collection, element, mapping)
  end

  # Collects parameters for join table operations in column order.
  private def collect_join_table_column_params(collection : AORM::BasePersistentCollection, element : AORM::Entity, mapping : AORM::Mapping::ManyToManyOwningSide) : Array(AORM::Mapping::Value)
    owner = collection.owner.not_nil!

    owner_id = @uow.entity_identifier(owner)
    element_id = @uow.entity_identifier(element)

    params = [] of AORM::Mapping::Value

    mapping.relation_to_source_key_columns.each do |_join_col, ref_col|
      params << self.bind_value(owner_id[ref_col]?)
    end

    mapping.relation_to_target_key_columns.each do |_join_col, ref_col|
      params << self.bind_value(element_id[ref_col]?)
    end

    params
  end

  # Returns the parameter bound for an entity-identifier slot. The slot is
  # either a `Mapping::Value` (registered identifier) or `nil` (column missing
  # from the identifier map — bound as a NULL parameter).
  private def bind_value(slot : AORM::Mapping::Value?) : AORM::Mapping::Value
    slot || AORM::Mapping::SingleValue.new(nil)
  end
end
