# Enum fixtures: enum fields are stored as the enum's integer value.
enum Suit
  Hearts
  Diamonds
  Clubs
  Spades
end

@[Flags]
enum Permission : UInt8
  Read
  Write
end

enum Priority : Int64
  Low  =             1
  High = 5_000_000_000
end

@[AORMA::Entity]
@[AORMA::Table(name: "cards")]
class Card < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! suit : Suit
end

@[AORMA::Entity]
@[AORMA::Table(name: "cards_with_nullable")]
class CardWithNullable < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property suit : Suit? = nil
end

# Enum used as the identifier.
@[AORMA::Entity]
@[AORMA::Table(name: "cards_with_enum_id")]
class CardWithEnumId < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! suit : Suit
end

# Flags enum with a narrow base type, and an enum whose base type needs a 64-bit column.
@[AORMA::Entity]
@[AORMA::Table(name: "tickets")]
class Ticket < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! permissions : Permission

  @[AORMA::Column]
  property! priority : Priority
end

# Enum field explicitly mapped to a type that cannot hold its integer value.
@[AORMA::Entity]
@[AORMA::Table(name: "cards_with_string_suit")]
class CardWithStringSuit < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column(type: "string")]
  property! suit : Suit
end
