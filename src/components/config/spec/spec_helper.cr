require "spec"
require "athena-spec"
require "../src/athena-config"

include ASPEC::Methods

macro new_annotation_array(*configurations)
  [{{configurations.splat}}] of ACF::AnnotationConfigurations::ConfigurationBase
end
