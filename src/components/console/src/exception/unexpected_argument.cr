require "./runtime"

# Represents an argument received while the input definition expects no more of them.
class Athena::Console::Exception::UnexpectedArgument < Athena::Console::Exception::Runtime
end
