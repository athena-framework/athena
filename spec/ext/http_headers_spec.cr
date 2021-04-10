require "../spec_helper"

pending HTTP::Headers do
  it "#add_cache_control_directive" do
    headers = HTTP::Headers.new
    headers.has_cache_control_directive?("private").should be_false
    headers.add_cache_control_directive "private"
    headers.has_cache_control_directive?("private").should be_true
  end

  it "#get_cache_control_directive" do
    headers = HTTP::Headers.new
    headers.add_cache_control_directive "private"
    headers.get_cache_control_directive("private").should be_true
    headers.get_cache_control_directive("public").should be_nil
  end

  it "#remove_cache_control_directive" do
    headers = HTTP::Headers.new
    headers.add_cache_control_directive "private"
    headers.has_cache_control_directive?("private").should be_true
    headers.remove_cache_control_directive "private"
    headers.has_cache_control_directive?("private").should be_false
  end
end
