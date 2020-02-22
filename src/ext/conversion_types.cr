def Object.from_parameter(value)
  value
end

def Bool.from_parameter(value : String) : Bool
  if value == "true"
    true
  elsif value == "false"
    false
  else
    raise ArgumentError.new "Invalid Bool: #{value}"
  end
end

def Union.from_parameter(value : String)
  # Process non nilable types first as they are more likely to work.
  {% for type in T.sort_by { |t| t.nilable? ? 1 : 0 } %}
    return {{type}}.from_parameter value
  {% end %}
end

def Number.from_parameter(value : String) : Number
  new value
end
