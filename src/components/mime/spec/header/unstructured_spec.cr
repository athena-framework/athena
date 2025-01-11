require "../spec_helper"

struct UnstructuredHeaderTest < ASPEC::TestCase
  def test_name : Nil
    AMIME::Header::Unstructured
      .new("subject", "")
      .name
      .should eq "subject"
  end

  def test_body : Nil
    AMIME::Header::Unstructured
      .new("subject", "content")
      .body
      .should eq "content"
  end

  def test_to_s : Nil
    AMIME::Header::Unstructured
      .new("subject", "content")
      .to_s
      .should eq "subject: content"
  end

  def ftest_to_s_long_lines : Nil
    AMIME::Header::Unstructured
      .new("x-custom-header", "The quick brown fox jumped over the fence, he was a very very scary brown fox with a bushy tail")
      .to_s
      .should eq <<-TXT
        x-custom-header: The quick brown fox jumped over the fence, he was a very very
        scary brown fox with a bushy tail
        TXT
  end
end
