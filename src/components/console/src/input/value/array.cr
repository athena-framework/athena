abstract struct Athena::Console::Input::Value; end

# :nodoc:
struct Athena::Console::Input::Value::Array < Athena::Console::Input::Value
  getter value : ::Array(Athena::Console::Input::Value)

  def self.from_array(array : ::Array) : self
    new(array.map { |item| ACON::Input::Value.from_value item })
  end

  def self.new(value)
    new [ACON::Input::Value.from_value value]
  end

  def self.new
    new [] of ACON::Input::Value
  end

  def initialize(@value : ::Array(Athena::Console::Input::Value)); end

  def <<(value)
    @value << ACON::Input::Value.from_value value
  end

  def get(type : ::Array(T).class) : ::Array(T) forall T
    @value.map &.get(T)
  end

  def get(type : ::Array(T)?.class) : ::Array(T)? forall T
    @value.map(&.get(T)) || nil
  end

  def resolve
    self.value.map &.resolve
  end

  def to_s(io : IO) : ::Nil
    @value.join io, ','
  end
end
