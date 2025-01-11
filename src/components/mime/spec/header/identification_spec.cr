require "../spec_helper"

struct IdentificationHeaderTest < ASPEC::TestCase
  def test_happy_path : Nil
    AMIME::Header::Identification
      .new("message-id", "id-left@id-right")
      .body_to_s
      .should eq "<id-left@id-right>"
  end

  def test_can_be_retrieved_verbatim : Nil
    AMIME::Header::Identification
      .new("message-id", "id-left@id-right")
      .id
      .should eq "id-left@id-right"
  end

  def test_can_have_multiple_ids : Nil
    header = AMIME::Header::Identification.new("references", "c@d")
    header.ids = ["a@b", "x@y"]
    header.ids.should eq ["a@b", "x@y"]
  end

  def test_multiple_ids_produces_list_value : Nil
    header = AMIME::Header::Identification.new("references", ["a@b", "x@y"])
    header.body_to_s.should eq "<a@b> <x@y>"
  end

  def test_left_id_can_be_quoted : Nil
    header = AMIME::Header::Identification.new("references", %("ab"@c))
    header.id.should eq %("ab"@c)
    header.body_to_s.should eq %(<"ab"@c>)
  end

  def test_left_id_can_contain_angles_as_quoted_pair : Nil
    header = AMIME::Header::Identification.new("references", %("a\\<\\>b"@c))
    header.id.should eq %("a\\<\\>b"@c)
    header.body_to_s.should eq %(<"a\\<\\>b"@c>)
  end

  def test_left_id_can_be_dot_atom : Nil
    header = AMIME::Header::Identification.new("references", %(a.b+&%$.c@d))
    header.id.should eq %(a.b+&%$.c@d)
    header.body_to_s.should eq %(<a.b+&%$.c@d>)
  end

  # TODO: Implement when email is validated

  # def test_invalid_left : Nil
  # end

  # def test_invalid_right : Nil
  # end

  # def test_invalid_missing_at : Nil
  # end

  def test_right_id_can_be_dot_atom : Nil
    header = AMIME::Header::Identification.new("references", %(a@b.c+&%$.d))
    header.id.should eq %(a@b.c+&%$.d)
    header.body_to_s.should eq %(<a@b.c+&%$.d>)
  end

  def test_right_id_can_be_literal : Nil
    header = AMIME::Header::Identification.new("references", %(a@[1.2.3.4]))
    header.id.should eq %(a@[1.2.3.4])
    header.body_to_s.should eq %(<a@[1.2.3.4]>)
  end

  def test_right_id_is_idn_encoded : Nil
    header = AMIME::Header::Identification.new("references", "a@ä")
    header.id.should eq "a@ä"
    header.body_to_s.should eq "<a@xn--4ca>"
  end

  def test_set_body : Nil
    header = AMIME::Header::Identification.new("references", "a@b")
    header.body = "d@f"
    header.ids.should eq ["d@f"]
  end

  def test_get_body : Nil
    header = AMIME::Header::Identification.new("references", "a@b")
    header.body = "d@f"
    header.body.should eq ["d@f"]
  end

  def test_to_s : Nil
    AMIME::Header::Identification
      .new("references", ["a@b", "x@y"])
      .to_s.should eq "references: <a@b> <x@y>"
  end
end
