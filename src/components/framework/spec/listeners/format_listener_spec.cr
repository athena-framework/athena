require "../spec_helper"

struct FormatListenerTest < ASPEC::TestCase
  def test_fallback_format : Nil
    event = new_request_event

    request_store = ATH::RequestStore.new
    request_store.request = event.request

    rules = [
      ATH::View::FormatNegotiator::Rule.new(fallback_format: "xml"),
    ]

    negotiator = ATH::View::FormatNegotiator.new request_store, rules

    listener = ATH::Listeners::Format.new negotiator

    listener.on_request event

    event.request.request_format.should eq "xml"
    event.request.attributes.get?("media_type").should eq "text/xml"
  end

  def test_stop_listener : Nil
    event = new_request_event
    event.request.request_format = "xml"

    request_store = ATH::RequestStore.new
    request_store.request = event.request

    rules = [
      ATH::View::FormatNegotiator::Rule.new(stop: true),
      ATH::View::FormatNegotiator::Rule.new(fallback_format: "json"),
    ]

    negotiator = ATH::View::FormatNegotiator.new request_store, rules

    listener = ATH::Listeners::Format.new negotiator

    listener.on_request event

    event.request.request_format.should eq "xml"
    event.request.attributes.get?("media_type").should be_nil
  end

  def test_cannot_resolve_format : Nil
    event = new_request_event

    request_store = ATH::RequestStore.new
    request_store.request = event.request

    rules = Array(ATH::View::FormatNegotiator::Rule).new

    negotiator = ATH::View::FormatNegotiator.new request_store, rules

    listener = ATH::Listeners::Format.new negotiator

    expect_raises ATH::Exceptions::NotAcceptable, "No matching accepted Response format could be determined." do
      listener.on_request event
    end
  end

  @[DataProvider("format_provider")]
  # Doesn't override request format if it was already set.
  def test_uses_specified_format(format : String?, expected : String, media_type : String?) : Nil
    event = new_request_event

    if format
      event.request.request_format = format
    end

    request_store = ATH::RequestStore.new
    request_store.request = event.request

    rules = [
      ATH::View::FormatNegotiator::Rule.new(fallback_format: "xml"),
    ]

    negotiator = ATH::View::FormatNegotiator.new request_store, rules

    listener = ATH::Listeners::Format.new negotiator

    listener.on_request event

    event.request.request_format.should eq expected
    event.request.attributes.get?("media_type").should eq media_type
  end

  def format_provider : Tuple
    {
      {nil, "xml", "text/xml"},
      {"html", "html", nil},
    }
  end
end
