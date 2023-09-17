require "../spec_helper"

struct HelperTest < ASPEC::TestCase
  @[TestWith(
    {0, "< 1 sec"},
    {1, "1 sec"},
    {2, "2 secs"},
    {59, "59 secs"},
    {60, "1 min"},
    {61, "1 min"},
    {119, "1 min"},
    {120, "2 mins"},
    {121, "2 mins"},
    {4.minutes, "4 mins"},
    {3599, "59 mins"},
    {3600, "1 hr"},
    {7199, "1 hr"},
    {7200, "2 hrs"},
    {7201, "2 hrs"},
    {86399, "23 hrs"},
    {86400, "1 day"},
    {86401, "1 day"},
    {172_799, "1 day"},
    {172_800, "2 days"},
    {172_801, "2 days"},
  )]
  def test_format_time(seconds : Int32 | Time::Span, expected : String) : Nil
    ACON::Helper.format_time(seconds).should eq expected
  end

  @[TestWith(
    {"abc", "abc"},
    {"abc<fg=default;bg=default>", "abc"},
    {"a\033[1;36mbc", "abc"},
    {"a\033]8;;http://url\033\\b\033]8;;\033\\c", "abc"},
  )]
  def test_remove_docoration(decorated_text : String, expected : String) : Nil
    ACON::Helper.remove_decoration(ACON::Formatter::Output.new, decorated_text).should eq expected
  end
end
