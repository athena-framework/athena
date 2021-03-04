class Athena::Routing::View(T)
  property data : T
  property status : HTTP::Status?
  property format : String? = nil
  property route_params : Hash(String, String)? = nil
  property context : ASR::SerializationContext { ASR::SerializationContext.new }

  getter location : String? = nil
  getter route : String? = nil

  property response : ART::Response do
    response = ART::Response.new

    if status = @status
      response.status = status
    end

    response
  end

  def self.create_redirect(
    url : String,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ART::View(Nil).new status: status, headers: headers
    view.location = url

    view
  end

  def self.create_route_redirect(
    route : String,
    params : Hash(String, _)? = nil,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ART::View(Nil).new status: status, headers: headers
    view.route = route
    view.route_params = params.try &.transform_values &.to_s

    view
  end

  def initialize(@data : T? = nil, @status : HTTP::Status? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    self.headers = headers unless headers.empty?
  end

  def headers : HTTP::Headers
    self.response.headers
  end

  def location=(@location : String) : Nil
    @route = nil
  end

  def return_type : T.class
    T
  end

  def route=(@route : String) : Nil
    @location = nil
  end

  def set_header(key : String, value : String) : Nil
    self.response.headers[key] = value
  end

  def set_header(key : String, value : _) : Nil
    self.set_header key, value.to_s
  end

  def headers=(headers : HTTP::Headers) : Nil
    self.response.headers.clear
    self.response.headers.merge! headers
  end
end
