# Association fixtures whose identifiers are mapped through `Rot13Type`, so bound join and foreign key values reveal whether they passed through it.
module ValueConversionType
  @[AORMA::Entity]
  @[AORMA::Table(name: "vct_inversed_onetomany")]
  class InversedOneToManyEntity < AORM::Entity
    @[AORMA::Column(type: "rot13")]
    @[AORMA::ID]
    @[AORMA::GeneratedValue(strategy: :none)]
    property! id1 : String

    @[AORMA::OneToMany(mapped_by: "associated_entity")]
    property associated_entities : AORM::Collection(ValueConversionType::OwningManyToOneEntity) = AORM::ArrayCollection(ValueConversionType::OwningManyToOneEntity).new
  end

  @[AORMA::Entity]
  @[AORMA::Table(name: "vct_owning_manytoone")]
  class OwningManyToOneEntity < AORM::Entity
    @[AORMA::Column(type: "rot13")]
    @[AORMA::ID]
    @[AORMA::GeneratedValue(strategy: :none)]
    property! id2 : String

    @[AORMA::ManyToOne(inversed_by: "associated_entities")]
    @[AORMA::JoinColumn(name: "associated_id", referenced_column_name: "id1")]
    property associated_entity : ValueConversionType::InversedOneToManyEntity? = nil
  end

  @[AORMA::Entity]
  @[AORMA::Table(name: "vct_inversed_manytomany")]
  class InversedManyToManyEntity < AORM::Entity
    @[AORMA::Column(type: "rot13")]
    @[AORMA::ID]
    @[AORMA::GeneratedValue(strategy: :none)]
    property! id1 : String

    @[AORMA::ManyToMany(mapped_by: "associated_entities")]
    property associated_entities : AORM::Collection(ValueConversionType::OwningManyToManyEntity) = AORM::ArrayCollection(ValueConversionType::OwningManyToManyEntity).new
  end

  @[AORMA::Entity]
  @[AORMA::Table(name: "vct_owning_manytomany")]
  class OwningManyToManyEntity < AORM::Entity
    @[AORMA::Column(type: "rot13")]
    @[AORMA::ID]
    @[AORMA::GeneratedValue(strategy: :none)]
    property! id2 : String

    @[AORMA::ManyToMany(inversed_by: "associated_entities")]
    @[AORMA::JoinTable(name: "vct_xref_manytomany")]
    @[AORMA::JoinColumn(name: "owning_id", referenced_column_name: "id2")]
    @[AORMA::InverseJoinColumn(name: "inversed_id", referenced_column_name: "id1")]
    property associated_entities : AORM::Collection(ValueConversionType::InversedManyToManyEntity) = AORM::ArrayCollection(ValueConversionType::InversedManyToManyEntity).new
  end
end
