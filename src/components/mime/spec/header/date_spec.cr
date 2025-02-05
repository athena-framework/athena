require "../spec_helper"

struct DateHeaderTest < ASPEC::TestCase
  def test_happy_path : Nil
    header = AMIME::Header::Date.new "date", now = Time.utc
    header.body.should eq now

    later = Time.utc + 1.week
    header.body = later
    header.body.should eq later
  end

  def test_body_to_s : Nil
    AMIME::Header::Date
      .new("date", Time.utc 2025, 1, 3, 0, 16, 15)
      .to_s.should eq "date: Fri, 3 Jan 2025 00:16:15 +0000"
  end
end
