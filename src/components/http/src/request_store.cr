# Stores a `AHTTP::Request` object.
class Athena::HTTP::RequestStore
  property! request : AHTTP::Request

  # Resets the store, removing the reference to the request.
  #
  # Used internally after the response has been returned.
  protected def reset : Nil
    @request = nil
  end
end
