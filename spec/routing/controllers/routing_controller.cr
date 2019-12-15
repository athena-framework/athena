require "../routing_spec_helper"

class RoutingController < ART::Controller
  include Athena::DI::Injectable

  def initialize(@request_store : Athena::Routing::RequestStore); end

  @[ART::Get("get/safe")]
  def safe_request_check : String
    initial_query = @request_store.request.try &.query
    sleep 2 if initial_query == "foo"
    check_query = @request_store.request.try &.query

    initial_query == check_query ? "safe" : "unsafe"
  end
end
