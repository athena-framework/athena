# Creates the `AHTTP::Session::Storage::Interface` of the session of a request.
module Athena::HTTP::Session::Storage::FactoryInterface
  # Returns a new storage for the session of the provided *request*.
  abstract def create_storage(request : AHTTP::Request?) : AHTTP::Session::Storage::Interface
end
