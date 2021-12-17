require "spec"
require "athena-spec"
require "../src/athena-config"

include ASPEC::Methods

@[ACFA::Resolvable("a")]
class Athena::Config::A
  getter bar : Int32 = 12
end

@[ACFA::Resolvable("b")]
class Athena::Config::B
end

class Athena::Config::Base
  getter foo : String? = nil
  getter a : Athena::Config::A = Athena::Config::A.new
  getter b : Athena::Config::B? = Athena::Config::B.new
end

class Athena::Config::Parameters
  getter username : String = "fred"
end

macro new_annotation_array(*configurations)
  [{{configurations.splat}}] of ACF::AnnotationConfigurations::ConfigurationBase
end
