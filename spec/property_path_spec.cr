require "./spec_helper"

private PATHS = [
  {"foo", "", "foo"},           # It returns the basePath if subPath is empty
  {"", "bar", "bar"},           # It returns the subPath if basePath is empty
  {"foo", "bar", "foo.bar"},    # It append the subPath to the basePath
  {"foo", "[bar]", "foo[bar]"}, # It does not include the dot separator if subPath uses the array notation
  {"0", "bar", "0.bar"},        # Leading zeros are kept
]

describe AVD::PropertyPath do
  describe ".append" do
    PATHS.each do |(base, sub, expected)|
      it "generates the correct strings" do
        AVD::PropertyPath.append(base, sub).should eq expected
      end
    end
  end
end
