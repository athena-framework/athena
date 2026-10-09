# :nodoc:
#
# Typed argument records for the `AORMA` annotations.
module Athena::ORM::Mapping::Annotations
  protected record Column,
    name : String? = nil,
    type : String? = nil,
    length : Int32? = nil,
    precision : Int32? = nil,
    scale : Int32? = nil,
    unique : Bool = false,
    nullable : Bool = false,
    insertable : Bool = true,
    updatable : Bool = true,
    column_definition : String? = nil,
    generated : String? = nil,
    index : Bool = false
  # options : Hash(String, String)

  protected record JoinColumn,
    name : String? = nil,
    referenced_column_name : String? = nil,
    deferrable : Bool = false,
    unique : Bool = false,
    nullable : Bool? = nil,
    column_definition : String? = nil,
    field_name : String? = nil,
    on_delete : String? = nil
  # options : Hash(String, String)

  protected record InverseJoinColumn,
    name : String? = nil,
    referenced_column_name : String? = nil,
    deferrable : Bool = false,
    unique : Bool = false,
    nullable : Bool = false,
    column_definition : String? = nil,
    field_name : String? = nil,
    on_delete : String? = nil
  # options : Hash(String, String)

  protected record ID
  protected record Embeddable
  protected record GeneratedValue, strategy : GeneratedValueStrategy = :auto
  protected record SequenceGenerator, name : String, allocation_size : Int64 = 1
  protected record Table, name : String? = nil, schema : String? = nil
  protected record Entity, repository_class : AORM::RepositoryInterface.class | Nil = nil, read_only : Bool = false
  protected record OneToOne,
    target_entity : AORM::Entity.class | Nil = nil,
    fetch_mode : FetchMode = :lazy,
    mapped_by : String? = nil,
    inversed_by : String? = nil,
    orphan_removal : Bool = false,
    cascade : Array(String)? = nil

  protected record ManyToMany,
    target_entity : AORM::Entity.class | Nil = nil,
    fetch_mode : FetchMode = :lazy,
    mapped_by : String? = nil,
    inversed_by : String? = nil,
    orphan_removal : Bool = false,
    cascade : Array(String)? = nil,
    index_by : String? = nil

  protected record OneToMany,
    target_entity : AORM::Entity.class | Nil = nil,
    fetch_mode : FetchMode = :lazy,
    mapped_by : String? = nil,
    orphan_removal : Bool = false,
    cascade : Array(String)? = nil,
    index_by : String? = nil

  protected record ManyToOne,
    target_entity : AORM::Entity.class | Nil = nil,
    fetch_mode : FetchMode = :lazy,
    inversed_by : String? = nil,
    cascade : Array(String)? = nil

  protected record JoinTable,
    name : String? = nil,
    schema : String? = nil,
    join_columns : Array(JoinColumn)? = nil,
    inverse_join_columns : Array(JoinColumn)? = nil
end
