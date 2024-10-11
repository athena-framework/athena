require "../spec_helper"

@[ADI::Register(
  public: true,
  _reference: "%app.domain%",
  _with_percent: "%app.with_percent%",
  _with_percent_and_placeholder: "%app.with_percent_placeholder%",
  _with_single_placeholder: "%app.placeholder%",
  _with_multiple_placeholders: "%app.placeholders%",
  _hash: "%app.mapping%",
  _array: "%app.array%",
  _nested_array: "%app.nested_array%",
  _nested_hash: "%app.nested_mapping%",
  _non_string: "%app.enable_v2_protocol%"
)]
class ParametersClient
  def initialize(
    reference : String,
    with_percent : String,
    with_percent_and_placeholder : String,
    with_single_placeholder : String,
    with_multiple_placeholders : String,
    hash : Hash(Int32, String),
    array : Array(String),
    nested_array : Array(Array(String) | String),
    nested_hash : Hash(String, Bool | String | Array(String) | Array(Array(String) | String)),
    non_string : Bool,
  )
    reference.should eq "google.com"
    with_percent.should eq "foo%bar"
    with_percent_and_placeholder.should eq "https://google.com/path/t%o/thing"
    with_single_placeholder.should eq "https://google.com/path/to/thing"
    with_multiple_placeholders.should eq "https://google.com/path/to/false"
    hash.should eq({10 => "google.com", 20 => "https://google.com/path/to/thing"})
    array.should eq ["google.com", "https://google.com/path/to/thing", "foo%bar", "https://google.com/path/t%o/thing"]
    nested_array.should eq [["google.com", "https://google.com/path/to/thing", "foo%bar", "https://google.com/path/t%o/thing"], "google.com"]
    nested_hash.should eq({"string" => "google.com", "array" => ["google.com", "https://google.com/path/to/thing", "foo%bar", "https://google.com/path/t%o/thing"], "nested_array" => [["google.com", "https://google.com/path/to/thing", "foo%bar", "https://google.com/path/t%o/thing"], "google.com"], "bool" => false})
    non_string.should be_false
  end
end

describe ADI::ServiceContainer do
  it "resolves parameters" do
    ADI.container.parameters_client
  end
end
