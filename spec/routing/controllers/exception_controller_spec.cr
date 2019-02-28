require "../routing_spec_helper"

abstract struct Parent1 < Athena::Routing::StructController
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context)
    if exception.is_a? DivisionByZeroError
      halt ctx, 666, %({"code": 666, "message": "#{exception.message}"})
    end

    super
  end
end

abstract struct Parent2 < Athena::Routing::StructController
end

abstract struct Parent3 < Athena::Routing::StructController
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context)
    if exception.is_a? DivisionByZeroError
      halt ctx, 400, %({"code": 400, "message": "#{exception.message}"})
    end

    super
  end
end

struct Test1 < Parent1
  @[Athena::Routing::Get(path: "exception/custom")]
  def self.get : Nil
    raise DivisionByZeroError.new
  end
end

struct Test2 < Parent2
  @[Athena::Routing::Get(path: "exception/default")]
  def self.get : Nil
    raise NilAssertionError.new
  end
end

struct Test3 < Parent3
  @[Athena::Routing::Get(path: "exception/no_match")]
  def self.get : Nil
    raise NilAssertionError.new
  end
end
