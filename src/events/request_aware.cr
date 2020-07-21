# Represents an event that has access to the current request object.
#
# Listeners of an event including `self` also have access to the `ART::Action` that will be handling the given `#request` via `.request.action`.
# In addition, any custom annotations defined using `Athena::Config.configuration_annotation` are accessible via `ART::Action#annotation_configurations`.
# The main purpose of this is to allow for more advanced annotation based `ART::ParamConverterInterface` and `ART::Listeners`' logic.
#
# ### Example
# Lets define a `SecurityListener` that denies access to users without the required permissions from annotated endpoints.
#
# ```
# # Define an enum to represent our security levels.
# enum Level
#   # No permissions required.
#   Public
#
#   # Restricted to admins.
#   Private
# end
#
# # First define our annotation configuration, that includes the security level of the action.
# # Default values and custom methods can also be used.
# ACF.configuration_annotation Security, level : Level
#
# # Our mock User object.
# record User do
#   def admin? : Bool
#     # Logic to determine if `self` is an admin.
#     false
#   end
# end
#
# @[ADI::Register]
# struct SecurityListener
#   include AED::EventListenerInterface
#
#   def self.subscribed_events : AED::SubscribedEvents
#     AED::SubscribedEvents{
#       ART::Events::Request => 24, # Set the priority to run right after the action for this request has been resolved.
#     }
#   end
#
#   def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
#     # Get access to the current request object.
#     request = event.request
#
#     # Get access to the annotation configurations on the action related to this request.
#     ann_configs = request.action.annotation_configurations
#
#     # Nothing to do if the action doesn't have the `Security` annotation.
#     return unless security = ann_configs[Security]?
#
#     # Nothing to do if the endpoint is public.
#     return if security.level.public?
#
#     # Parse a user from the request
#     user = get_user request
#
#     # Raise a 403 error if the current user is not an admin and the action is private.
#     if security.level.private? && !user.admin?
#       raise ART::Exceptions::Forbidden.new "Route '#{request.path}' is only available to admins."
#     end
#   end
#
#   private def get_user(request : HTTP::Request) : User
#     # Logic to return a user given a request,
#     # such as looking up the related user in the DB based on the provided JWT token.
#     # Be sure to throw a 401 if the request is missing authentication credentials.
#     User.new
#   end
# end
#
# class ExampleController < ART::Controller
#   get "/unset" do
#     "unset"
#   end
#
#   @[Security(level: :public)]
#   get "/public" do
#     "public"
#   end
#
#   @[Security(:private)]
#   get "/private" do
#     "private"
#   end
# end
#
# ART.run
#
# # GET /unset   # => unset
# # GET /public  # => public
# # GET /private # => {"code":403,"message":"Route '/private' is only available to admins."}
# ```
module Athena::Routing::Events::RequestAware
  # Returns the current request object.
  getter request : HTTP::Request

  def initialize(@request : HTTP::Request); end
end
