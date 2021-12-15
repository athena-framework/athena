require "./spec_helper"

private TEST_CASES = {
  {
    # A named argument is an array with a service reference that doesn't exist
    "array_named_argument_missing",
    "Failed to register service 'klass'.  Could not resolve argument 'values : Array(Foo)' from named argument value '[\"@foo\"]'.",
  },
  {
    # A binding value is an array with a service reference that doesn't exist
    "binding_array_argument_missing",
    "Failed to register service 'klass'.  Could not resolve argument 'values : Array(Foo)' from binding value '[\"@foo\"]'.",
  },
  {
    # More than one service of a given type exist, but ivar name doesn't match any, nor is an alias defined
    "cannot_auto_register_multiple_candidates",
    "Failed to auto register service 'klass'.  Could not resolve argument 'service : Interface'.",
  },
  {
    # Service could not be auto registered due to an argument not resolving to any services
    "cannot_auto_register_missing_service",
    "Failed to auto register service 'klass'.  Could not resolve argument 'service : MissingService'.",
  },
  {
    "factory_instance_method",
    "Failed to register service `klass`.  Factory method `double` within `Klass` is an instance method.",
  },
  {
    "factory_missing_method",
    "Failed to register service `klass`.  Factory method `double` within `Klass` does not exist.",
  },
  {
    # Service based on type that has multiple generic arguments does not provide the correct amount of generic arguments
    "generic_service_generics_count_mismatch",
    "Failed to register service 'generic_service'.  Expected 2 generics types got 1.",
  },
  {
    # Service based on generic type does not provide any generic arguments
    "generic_service_generics_not_provided",
    "Failed to register service 'generic_service'.  Generic services must provide the types to use via the 'generics' field.",
  },
  {
    # Service based on generic type does not explicitly provide a name
    "generic_service_name_not_provided",
    "Failed to register services for 'GenericService(T)'.  Generic services must explicitly provide a name.",
  },
  {
    # Multiple services are based on a type, but not all provide a name
    "multiple_services_on_type_missing_name",
    "Failed to register services for 'Klass'.  Services based on this type must each explicitly provide a name.",
  },
  {
    # A named argument is an array more than 2 levels deep
    "nested_array_named_argument",
    "Failed to register service 'klass'.  Arrays more than two levels deep are not currently supported.",
  },
  {
    # Assert the service has been removed from the container
    "private_unused_service",
    "undefined method 'service' for Athena::DependencyInjection::ServiceContainer",
  },
  {
    # A name must be supplied if using a NamedTupleLiteral tag
    "tagged_service_invalid_tag_list_type",
    "Failed to register service `tagged_service`.  Tags must be an ArrayLiteral or TupleLiteral, not NumberLiteral.",
  },
  {
    # Tags can only be NamedTupleLiterals or StringLiterals
    "tagged_service_invalid_tag_type",
    "Failed to register service `tagged_service`.  A tag must be a StringLiteral or NamedTupleLiteral not BoolLiteral.",
  },
  {
    # A name must be supplied if using a NamedTupleLiteral tag
    "tagged_service_name_not_provided",
    "Failed to register service `tagged_service`.  All tags must have a name.",
  },
}

describe Athena::DependencyInjection do
  describe Athena::DependencyInjection::ServiceContainer do
    describe "compiler errors" do
      TEST_CASES.each do |(file_path, message)|
        it file_path do
          assert_error "compiler/#{file_path}.cr", message
        end
      end
    end
  end
end
