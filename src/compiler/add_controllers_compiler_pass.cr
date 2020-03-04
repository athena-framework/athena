module Athena::Routing::Compiler::RegisterControllersPass
  include ADI::CompilerPass

  macro pre_process(service_hash, alias_hash)
    ART::Controller.all_subclasses.each do |controller|
      unless controller.abstract?
        controller_ann = controller.annotation(ADI::Register)

        service_id = ADI::ServiceContainer.get_service_id controller, controller_ann
        service_hash[service_id] = ADI::ServiceContainer.get_service_hash_value service_id, controller, controller_ann, alias_hash
        service_hash[service_id][:public] = true
        service_hash[service_id][:lazy] = true
      end
    end
  end
end
