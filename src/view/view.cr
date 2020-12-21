class Athena::Routing::View(T)
  property data : T
  property status : HTTP::Status?
  property headers : HTTP::Headers
  property format : String? = nil
  property route_parameters : Hash(String, String)? = nil

  getter location : String? = nil
  getter route : String? = nil

  getter! view_context : ART::Action::ViewContext

  getter response : ART::Response do
    response = ART::Response.new

    if status = @status
      response.status = status
    end

    response
  end

  def initialize(
    @data : T? = nil,
    status : HTTP::Status | Int | Nil = nil,
    @headers : HTTP::Headers = HTTP::Headers.new
  )
    @status = HTTP::Status.new status if status
  end

  def return_type : T.class
    T
  end

  # :nodoc:
  # def view_context=(@view_context : ART::Action::ViewContext)
  # end
end
