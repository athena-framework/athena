require "../routing_spec_helper"

class Parent1 < Athena::Routing::Controller
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context, location : String = "unknown")
    if exception.is_a? DivisionByZeroError
      throw 666, %({"code": 666, "message": "#{exception.message}"})
    end

    super
  end
end

class Parent2 < Athena::Routing::Controller
end

class Parent3 < Athena::Routing::Controller
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context, location : String = "unknown")
    if exception.is_a? DivisionByZeroError
      throw 400, %({"code": 400, "message": "#{exception.message}"})
    end

    super
  end
end

class Test1 < Parent1
  @[Athena::Routing::Get(path: "exception/custom")]
  def get_custom_exception : Nil
    raise DivisionByZeroError.new
  end
end

class Test2 < Parent2
  @[Athena::Routing::Get(path: "exception/default")]
  def get_default_exception : Nil
    raise NilAssertionError.new
  end
end

class Test3 < Parent3
  @[Athena::Routing::Get(path: "exception/no_match")]
  def get_no_match_exception : Nil
    raise NilAssertionError.new
  end
end
