class LogicError < ::Exception; end

class Athena::Serializer::Exception::Logic < LogicError
  include Athena::Serializer::Exception
end
