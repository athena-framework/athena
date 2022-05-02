struct Athena::Routing::Requirement::Enum(EnumType)
  getter members : Set(EnumType)? = nil

  def self.new(*cases : EnumType)
    new cases.to_set
  end

  def initialize(@members : Set(EnumType)? = nil)
    {% raise "'#{EnumType}' is not an Enum type." unless EnumType <= ::Enum %}
  end

  def to_s(io : IO) : Nil
    (@members || EnumType.values).join io, '|' do |member, join_io|
      join_io << Regex.escape member.to_s.underscore
    end
  end
end
