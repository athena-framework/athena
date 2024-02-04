require "../spec_helper"

private def normalize(input : String) : String
  input.gsub EOL, "\n"
end

describe ACON::Helper::Formatter do
  it "#format_section" do
    ACON::Helper::Formatter.new.format_section("cli", "some text to display").should eq "<info>[cli]</info> some text to display"
  end

  describe "#format_block" do
    it "formats" do
      formatter = ACON::Helper::Formatter.new

      formatter.format_block("Some text to display", "error").should eq "<error> Some text to display </error>"
      formatter.format_block({"Some text to display", "foo bar"}, "error").should eq "<error> Some text to display </error>\n<error> foo bar              </error>"
      formatter.format_block("Some text to display", "error", true).should eq normalize <<-BLOCK
      <error>                        </error>
      <error>  Some text to display  </error>
      <error>                        </error>
      BLOCK
    end

    it "formats with diacritic letters" do
      formatter = ACON::Helper::Formatter.new

      formatter.format_block("Du texte à afficher", "error", true).should eq normalize <<-BLOCK
      <error>                       </error>
      <error>  Du texte à afficher  </error>
      <error>                       </error>
      BLOCK
    end

    pending "formats with double with characters" do
    end

    it "escapes < within the block" do
      ACON::Helper::Formatter.new.format_block("<info>some info</info>", "error", true).should eq normalize <<-BLOCK
      <error>                            </error>
      <error>  \\<info>some info\\</info>  </error>
      <error>                            </error>
      BLOCK
    end
  end

  describe "#truncate" do
    it "with shorter length than message with suffix" do
      formatter = ACON::Helper::Formatter.new
      message = "testing wrapping"

      formatter.truncate(message, 4).should eq "test..."
      formatter.truncate(message, 15).should eq "testing wrappin..."
      formatter.truncate(message, 16).should eq "testing wrapping..."
      formatter.truncate("zażółć gęślą jaźń", 12).should eq "zażółć gęślą..."
    end

    it "with custom suffix" do
      ACON::Helper::Formatter.new.truncate("testing truncate", 4, "!").should eq "test!"
    end

    it "with longer length than message with suffix" do
      ACON::Helper::Formatter.new.truncate("test", 10).should eq "test"
    end

    it "with negative length" do
      formatter = ACON::Helper::Formatter.new
      message = "testing truncate"

      formatter.truncate(message, -5).should eq "testing tru..."
      formatter.truncate(message, -100).should eq "..."
    end
  end
end
