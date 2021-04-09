require "../spec_helper"

struct FormatListenerTest < ASPEC::TestCase
  def test_call_no_config : Nil
    event = new_request_event

    request_store = ART::RequestStore.new
    request_store.request = event.request

    negotiator = ART::View::FormatNegotiator.new request_store, nil

    listener = ART::Listeners::Format.new nil, negotiator

    listener.call event, AED::Spec::TracableEventDispatcher.new

    event.request.request_format.should eq "json"
    event.request.attributes.get?("media_type").should be_nil
  end

  def test_call_fallback_format : Nil
    event = new_request_event

    request_store = ART::RequestStore.new
    request_store.request = event.request

    config = ART::Config::ContentNegotiation.new [
      ART::Config::ContentNegotiation::Rule.new(fallback_format: "xml"),
    ]

    negotiator = ART::View::FormatNegotiator.new request_store, config

    listener = ART::Listeners::Format.new config, negotiator

    listener.call event, AED::Spec::TracableEventDispatcher.new

    event.request.request_format.should eq "xml"
    event.request.attributes.get?("media_type").should eq "text/xml"
  end

  def test_call_stop_listener : Nil
    event = new_request_event
    event.request.request_format = "xml"

    request_store = ART::RequestStore.new
    request_store.request = event.request

    config = ART::Config::ContentNegotiation.new [
      ART::Config::ContentNegotiation::Rule.new(stop: true),
      ART::Config::ContentNegotiation::Rule.new(fallback_format: "json"),
    ]

    negotiator = ART::View::FormatNegotiator.new request_store, config

    listener = ART::Listeners::Format.new config, negotiator

    listener.call event, AED::Spec::TracableEventDispatcher.new

    event.request.request_format.should eq "xml"
    event.request.attributes.get?("media_type").should be_nil
  end

  def test_call_cannot_resolve_format : Nil
    event = new_request_event

    request_store = ART::RequestStore.new
    request_store.request = event.request

    config = ART::Config::ContentNegotiation.new Array(ART::Config::ContentNegotiation::Rule).new

    negotiator = ART::View::FormatNegotiator.new request_store, config

    listener = ART::Listeners::Format.new config, negotiator

    expect_raises ART::Exceptions::NotAcceptable, "No matching accepted Response format could be determined." do
      listener.call event, AED::Spec::TracableEventDispatcher.new
    end
  end

  @[DataProvider("format_provider")]
  # Doesn't override request format if it was already set.
  def test_uses_specified_format(format : String?, expected : String, media_type : String?) : Nil
    event = new_request_event

    if format
      event.request.request_format = format
    end

    request_store = ART::RequestStore.new
    request_store.request = event.request

    config = ART::Config::ContentNegotiation.new [
      ART::Config::ContentNegotiation::Rule.new(fallback_format: "xml"),
    ]

    negotiator = ART::View::FormatNegotiator.new request_store, config

    listener = ART::Listeners::Format.new config, negotiator

    listener.call event, AED::Spec::TracableEventDispatcher.new

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
