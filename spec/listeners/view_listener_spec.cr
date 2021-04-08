require "../spec_helper"

private class MockViewHandler
  include ART::View::ViewHandlerInterface

  getter! view : ART::ViewBase

  def register_handler(format : String, handler : ART::View::FormatHandlerInterface | Proc(ART::View::ViewHandlerInterface, ART::ViewBase, ART::Request, String, ART::Response)) : Nil
  end

  def supports?(format : String) : Bool
    true
  end

  def handle(view : ART::ViewBase, request : ART::Request? = nil) : ART::Response
    @view = view

    ART::Response.new
  end

  def create_redirect_response(view : ART::ViewBase, location : String, format : String) : ART::Response
    ART::Response.new
  end

  def create_response(view : ART::ViewBase, request : ART::Request, format : String) : ART::Response
    ART::Response.new
  end
end

private def get_ann_configs(config : ACF::AnnotationConfigurations::ConfigurationBase) : ACF::AnnotationConfigurations
  ACF::AnnotationConfigurations.new ACF::AnnotationConfigurations::AnnotationHash{ARTA::View => [config] of ACF::AnnotationConfigurations::ConfigurationBase}
end

describe ART::Listeners::View do
  describe "#call" do
    it "non ART::View" do
      request = new_request
      event = ART::Events::View.new request, "FOO"
      view_handler = MockViewHandler.new

      ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

      view_handler.view.data.should eq "FOO"
      view_handler.view.format.should eq "json"
      view_handler.view.context.groups.try &.should be_empty
    end

    it ART::View do
      request = new_request
      view = ART::View.new("BAR")
      view.format = "xml"
      event = ART::Events::View.new request, view
      view_handler = MockViewHandler.new

      ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

      view_handler.view.data.should eq "BAR"
      view_handler.view.format.should eq "xml"
      view_handler.view.context.groups.try &.should be_empty
    end

    describe ARTA::View do
      describe "status" do
        it "with status" do
          request = new_request(
            action: new_action(
              annotation_configurations: get_ann_configs(ARTA::ViewConfiguration.new(status: :found))
            )
          )
          event = ART::Events::View.new request, "FOO"
          view_handler = MockViewHandler.new

          ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

          view_handler.view.status.should eq HTTP::Status::FOUND
        end

        it "when the view already has a status" do
          request = new_request(
            action: new_action(
              annotation_configurations: get_ann_configs(ARTA::ViewConfiguration.new(status: :found))
            )
          )
          view = ART::View.new "FOO", status: :gone
          event = ART::Events::View.new request, view
          view_handler = MockViewHandler.new

          ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

          view_handler.view.status.should eq HTTP::Status::GONE
        end

        it "when the view already has a status, but it's OK" do
          request = new_request(
            action: new_action(
              annotation_configurations: get_ann_configs(ARTA::ViewConfiguration.new(status: :found))
            )
          )
          view = ART::View.new "FOO", status: :ok
          event = ART::Events::View.new request, view
          view_handler = MockViewHandler.new

          ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

          view_handler.view.status.should eq HTTP::Status::FOUND
        end
      end

      describe "serialization_groups" do
        it "and the view doesn't have any groups already" do
          request = new_request(
            action: new_action(
              annotation_configurations: get_ann_configs(ARTA::ViewConfiguration.new(serialization_groups: ["one", "two"]))
            )
          )
          event = ART::Events::View.new request, "FOO"
          view_handler = MockViewHandler.new

          ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

          groups = view_handler.view.context.groups.should_not be_nil
          groups.should eq Set{"one", "two"}
        end

        it "and the view already has some groups" do
          request = new_request(
            action: new_action(
              annotation_configurations: get_ann_configs(ARTA::ViewConfiguration.new(serialization_groups: ["one", "two"]))
            )
          )

          view = ART::View.new "FOO"
          view.context.add_groups "three", "four"

          event = ART::Events::View.new request, view
          view_handler = MockViewHandler.new

          ART::Listeners::View.new(view_handler).call event, AED::Spec::TracableEventDispatcher.new

          groups = view_handler.view.context.groups.should_not be_nil
          groups.should eq Set{"three", "four", "one", "two"}
        end
      end
    end
  end
end
