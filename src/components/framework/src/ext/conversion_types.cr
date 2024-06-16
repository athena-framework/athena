# :nodoc:
def Object.from_parameter(value)
  value
end

def Object.from_parameter?(value)
  value
end

# :nodoc:
def Array.from_parameter(value : Array)
  value.map { |item| T.from_parameter(item).as T }
end

# :nodoc:
def Bool.from_parameter(value : String) : Bool
  case value
  when "true", "1", "yes", "on"  then true
  when "false", "0", "no", "off" then false
  else
    raise ArgumentError.new "Invalid Bool: #{value}"
  end
end

# :nodoc:
def Bool.from_parameter?(value : String) : Bool?
  case value
  when "true", "1", "yes", "on"  then true
  when "false", "0", "no", "off" then false
  end
end

# :nodoc:
def Union.from_parameter(value : String)
  # Process non nilable types first as they are more likely to work.
  {% for type in T.sort_by { |t| t.nilable? ? 1 : 0 } %}
    begin
      return {{type}}.from_parameter value
    rescue
      # Noop to allow next T to be tried.
    end
  {% end %}
  raise ArgumentError.new "Invalid #{self}: #{value}"
end

# :nodoc:
def Number.from_parameter(value : String) : Number
  new value, whitespace: false
end

# :nodoc:
def Number.from_parameter?(value : String)
  new value, whitespace: false rescue nil
end

# :nodoc:
def Nil.from_parameter(value : String) : Nil
  raise ArgumentError.new "Invalid Nil: #{value}" unless value == "null"
end

# :nodoc:
def Nil.from_parameter?(value : String) : Nil
end
