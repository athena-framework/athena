require "../spec_helper"

@[ADI::Register]
class ORMController < ATH::Controller
  def initialize(@entity_manager : AORM::EntityManagerInterface); end

  @[ARTA::Get("/orm/transaction")]
  def transaction : Nil
    @entity_manager.begin_transaction
  end
end
