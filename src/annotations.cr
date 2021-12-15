module Athena::Config::Annotations
  # Used as a sorts of "interface" that other libraries can use to provide configuration type instances automatically.
  # The [Dependency Injection](/DependencyInjection/Register/#Athena::DependencyInjection::Register--configuration) component is an example of this.
  #
  # The annotation should be provided a "path", either as the first positional argument, or via the `path` field, to the object from the `ACF::Base` instance.
  annotation Resolvable; end
end
