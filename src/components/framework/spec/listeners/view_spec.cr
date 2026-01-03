require "../spec_helper"

private class MockViewHandler
  include ATH::View::ViewHandlerInterface

  getter! view : ATH::ViewBase

  def register_handler(format : String, handler : ATH::View::FormatHandlerInterface | Proc(ATH::View::ViewHandlerInterface, ATH::ViewBase, AHTTP::Request, String, AHTTP::Response)) : Nil
  end

  def supports?(format : String) : Bool
    true
  end

  def handle(view : ATH::ViewBase, request : AHTTP::Request? = nil) : AHTTP::Response
    @view = view

    AHTTP::Response.new
  end

  def create_redirect_response(view : ATH::ViewBase, location : String, format : String) : AHTTP::Response
    AHTTP::Response.new
  end

  def create_response(view : ATH::ViewBase, request : AHTTP::Request, format : String) : AHTTP::Response
    AHTTP::Response.new
  end
end

private def get_ann_configs(config : ADI::AnnotationConfigurations::ConfigurationBase) : ADI::AnnotationConfigurations
  ADI::AnnotationConfigurations.new ADI::AnnotationConfigurations::AnnotationHash{ATHA::View => [config] of ADI::AnnotationConfigurations::ConfigurationBase}
end

describe ATH::Listeners::View do
  describe "#call" do
    it "non ATH::View" do
      request = new_request
      event = AHK::Events::View.new request, "FOO"
      view_handler = MockViewHandler.new

      ATH::Listeners::View.new(view_handler, MockAnnotationResolver.new).on_view event

      view_handler.view.data.should eq "FOO"
      view_handler.view.format.should eq "json"
      view_handler.view.context.groups.try &.should be_empty
      view_handler.view.context.emit_nil?.should be_nil
    end

    it ATH::View do
      request = new_request
      view = ATH::View.new("BAR")
      view.format = "xml"
      event = AHK::Events::View.new request, view
      view_handler = MockViewHandler.new

      ATH::Listeners::View.new(view_handler, MockAnnotationResolver.new).on_view event

      view_handler.view.data.should eq "BAR"
      view_handler.view.format.should eq "xml"
      view_handler.view.context.groups.try &.should be_empty
    end

    it "mutating response" do
      request = new_request
      event = AHK::Events::View.new request, "FOO"
      view_handler = MockViewHandler.new

      event.action_result = "BAR"
      ATH::Listeners::View.new(view_handler, MockAnnotationResolver.new).on_view event

      view_handler.view.data.should eq "BAR"
      view_handler.view.format.should eq "json"
      view_handler.view.context.groups.try &.should be_empty
    end

    describe ATHA::View do
      describe "status" do
        it "with status" do
          request = new_request
          event = AHK::Events::View.new request, "FOO"
          view_handler = MockViewHandler.new

          ATH::Listeners::View.new(
            view_handler,
            MockAnnotationResolver.new(
              action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(status: :found))
            )
          ).on_view event

          view_handler.view.status.should eq ::HTTP::Status::FOUND
        end

        it "when the view already has a status" do
          request = new_request
          view = ATH::View.new "FOO", status: :gone
          event = AHK::Events::View.new request, view
          view_handler = MockViewHandler.new

          ATH::Listeners::View.new(
            view_handler,
            MockAnnotationResolver.new(
              action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(status: :found))
            )
          ).on_view event

          view_handler.view.status.should eq ::HTTP::Status::GONE
        end

        it "when the view already has a status, but it's OK" do
          request = new_request
          view = ATH::View.new "FOO", status: :ok
          event = AHK::Events::View.new request, view
          view_handler = MockViewHandler.new

          ATH::Listeners::View.new(
            view_handler,
            MockAnnotationResolver.new(
              action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(status: :found))
            )
          ).on_view event

          view_handler.view.status.should eq ::HTTP::Status::FOUND
        end
      end

      describe "serialization_groups" do
        it "and the view doesn't have any groups already" do
          request = new_request
          event = AHK::Events::View.new request, "FOO"
          view_handler = MockViewHandler.new

          ATH::Listeners::View.new(
            view_handler,
            MockAnnotationResolver.new(
              action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(serialization_groups: ["one", "two"]))
            )
          ).on_view event

          groups = view_handler.view.context.groups.should_not be_nil
          groups.should eq Set{"one", "two"}
        end

        it "and the view already has some groups" do
          request = new_request
          view = ATH::View.new "FOO"
          view.context.add_groups "three", "four"

          event = AHK::Events::View.new request, view
          view_handler = MockViewHandler.new

          ATH::Listeners::View.new(
            view_handler,
            MockAnnotationResolver.new(
              action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(serialization_groups: ["one", "two"]))
            )
          ).on_view event

          groups = view_handler.view.context.groups.should_not be_nil
          groups.should eq Set{"three", "four", "one", "two"}
        end
      end

      it "emit_nil" do
        request = new_request
        event = AHK::Events::View.new request, "FOO"
        view_handler = MockViewHandler.new

        ATH::Listeners::View.new(
          view_handler,
          MockAnnotationResolver.new(
            action_annotations: get_ann_configs(ATHA::ViewConfiguration.new(emit_nil: true))
          )
        ).on_view event

        view_handler.view.context.emit_nil?.should be_true
      end
    end
  end
end
