# Reversible string conversion, used to observe that values pass through their mapped `Types::Type` on the way to and from the database.
struct Rot13Type < AORM::Types::Type
  NAME = "rot13"

  def sql_declaration(column : AORM::Schema::Column, platform : AORM::Platforms::Platform) : String
    platform.string_type_declaration_sql column
  end

  def to_db(value : _, platform : AORM::Platforms::Platform)
    value.is_a?(String) ? self.class.rot13(value) : value
  end

  def to_crystal_value(value : _, platform : AORM::Platforms::Platform) : String?
    value.is_a?(String) ? self.class.rot13(value) : nil
  end

  def to_crystal_value(value : DB::ResultSet, platform : AORM::Platforms::Platform) : String?
    value.read(String?).try { |v| self.class.rot13 v }
  end

  def self.rot13(value : String) : String
    String.build do |io|
      value.each_char do |char|
        io << case char
        when 'a'..'z' then ((char.ord - 'a'.ord + 13) % 26 + 'a'.ord).chr
        when 'A'..'Z' then ((char.ord - 'A'.ord + 13) % 26 + 'A'.ord).chr
        else               char
        end
      end
    end
  end
end

AORM::Types::Type.add_type Rot13Type::NAME, Rot13Type.new
