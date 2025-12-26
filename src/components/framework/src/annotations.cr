# Contains all the `Athena::Framework` based annotations.
# See each annotation for more information.
module Athena::Framework::Annotations
  # Configures how the `ATH::View::ViewHandlerInterface` should render the related controller action.
  #
  # ## Fields
  #
  # * status : `HTTP::Status` - The `HTTP::Status` the endpoint should return. Defaults to `HTTP::Status::OK` (200).
  # * serialization_groups : `Array(String)?` - The serialization groups to use for this route as part of `ASR::ExclusionStrategies::Groups`.
  # * validation_groups : `Array(String)?` - Groups that should be used to validate any objects related to this route; see `AVD::Constraint@validation-groups`.
  # * emit_nil : `Bool` - If `nil` values should be serialized. Defaults to `false`.
  #
  # ## Example
  #
  # ```
  # @[ARTA::Post(path: "/publish/{id}")]
  # @[ATHA::View(status: :accepted, serialization_groups: ["default", "detailed"])]
  # def publish(id : Int32) : Article
  #   article = Article.find id
  #   article.published = true
  #   article
  # end
  # ```
  ADI.configuration_annotation ::Athena::Framework::Annotations::View,
    status : HTTP::Status? = nil,
    serialization_groups : Array(String)? = nil,
    validation_groups : Array(String)? = nil,
    emit_nil : Bool? = nil
end
