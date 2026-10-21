# Whether a migration is to be applied or reverted.
enum Athena::ORM::Migrations::Version::Direction
  # Applies the migration, via `AORM::Migrations::AbstractMigration#up`.
  UP

  # Reverts the migration, via `AORM::Migrations::AbstractMigration#down`.
  DOWN

  def to_s : String
    self.up? ? "up" : "down"
  end

  def to_s(io : IO) : Nil
    io << self.to_s
  end
end
