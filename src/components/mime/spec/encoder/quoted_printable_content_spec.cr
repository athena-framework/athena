require "../spec_helper"

struct QuotedPrintableEncoderTest < ASPEC::TestCase
  def test_quoted_printable_encode : Nil
    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode("test").should eq "test"
    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode("this is a foo").should eq "this is a foo"

    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode("This is a sample string with special characters: ä, ö, ü, and ß.").should eq <<-TXT
      This is a sample string with special characters: =C3=A4, =C3=B6, =C3=BC, an=\r
      d =C3=9F.
      TXT

    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode("Iñtërnâtiônàlizætiøn☃💩").should eq <<-TXT
      I=C3=B1t=C3=ABrn=C3=A2ti=C3=B4n=C3=A0liz=C3=A6ti=C3=B8n=E2=98=83=\r
      =F0=9F=92=A9
      TXT
  end

  def test_quoted_printable_encode_encodes_nul_values : Nil
    AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode("\0" * 200).should eq <<-TXT
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=\r
        =00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00=00
        TXT
  end

  def test_quoted_printable_encode_encodes_non_ascii
    AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode("строка в юникоде" * 50).should eq <<-TXT
        =D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=\r
        =BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=\r
        =D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=\r
        =B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=\r
        =D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=\r
        =82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=\r
        =D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=\r
        =BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=\r
        =D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =\r
        =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=\r
        =BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=\r
        =D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=\r
        =B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=\r
        =D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=\r
        =8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=\r
        =B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=\r
        =D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=\r
        =81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=\r
        =D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=\r
        =B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =\r
        =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=\r
        =D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=\r
        =80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=\r
        =D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=\r
        =BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=\r
        =D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=\r
        =B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=\r
        =D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=\r
        =82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=\r
        =D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=\r
        =BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=\r
        =D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =\r
        =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=\r
        =BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=\r
        =D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=\r
        =B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=\r
        =D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=\r
        =8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=\r
        =B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=\r
        =D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=\r
        =81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=\r
        =D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=\r
        =B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =\r
        =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=\r
        =D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=\r
        =80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=\r
        =D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=\r
        =BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=\r
        =D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=\r
        =B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=\r
        =D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=\r
        =82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=\r
        =D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=\r
        =BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=\r
        =D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =\r
        =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=\r
        =BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5=D1=81=\r
        =D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=\r
        =B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=8E=D0=BD=D0=B8=\r
        =D0=BA=D0=BE=D0=B4=D0=B5=D1=81=D1=82=D1=80=D0=BE=D0=BA=D0=B0 =D0=B2 =D1=\r
        =8E=D0=BD=D0=B8=D0=BA=D0=BE=D0=B4=D0=B5
        TXT
  end

  def test_quoted_printable_encode_does_not_split_multibyte_chars_by_soft_break : Nil
    AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode("\xc4\x85" * 77).should eq <<-TXT
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=C4=85=\r
        =C4=85=C4=85=C4=85=C4=85=C4=85
        TXT
  end

  def test_quoted_printable_encode_permitted_characters_are_not_encoded : Nil
    ((33..60).to_a + (62..126).to_a).each do |ord|
      char = ord.chr.to_s
      AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode(char).should eq char
    end
  end

  def test_quoted_printable_encode_crlf_is_left_alone : Nil
    string = "a\r\nb\r\nc\r\n"
    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode(string).should eq string
  end

  def test_quoted_printable_encode_always_encodes_tabs : Nil
    AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode("a\t\t\r\nb")
      .should eq "a=09=09\r\nb"
  end

  def test_quoted_printable_encode_encodes_space_before_newline : Nil
    AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode("a  \r\nb")
      .should eq "a =20\r\nb"
  end

  def test_quoted_printable_encode_lines_longer_than_76_characters_are_soft_broken : Nil
    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode("a" * 140).should eq <<-TXT
      aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=\r\naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      TXT
  end

  def test_quoted_printable_encode_bytes_below_permitted_range_are_encoded : Nil
    (0..31).each do |byte|
      char = byte.chr.to_s

      AMIME::Encoder::QuotedPrintableContent
        .quoted_printable_encode(char)
        .should eq sprintf("=%02X", byte)
    end

    # Allows spaces
    AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode(" ").should eq " "
  end

  def test_name : Nil
    AMIME::Encoder::QuotedPrintableContent.new.name.should eq "quoted-printable"
  end

  def test_encode : Nil
    AMIME::Encoder::QuotedPrintableContent.new.encode("test").should eq "test"
    AMIME::Encoder::QuotedPrintableContent.new.encode("this is a foo").should eq "this is a foo"

    AMIME::Encoder::QuotedPrintableContent.new.encode("This is a sample string with special characters: ä, ö, ü, and ß.").should eq <<-TXT
      This is a sample string with special characters: =C3=A4, =C3=B6, =C3=BC, an=\r
      d =C3=9F.
      TXT

    AMIME::Encoder::QuotedPrintableContent.new.encode("Iñtërnâtiônàlizætiøn☃💩").should eq <<-TXT
      I=C3=B1t=C3=ABrn=C3=A2ti=C3=B4n=C3=A0liz=C3=A6ti=C3=B8n=E2=98=83=\r
      =F0=9F=92=A9
      TXT
  end

  def test_quoted_printable_encode_io : Nil
    AMIME::Encoder::QuotedPrintableContent.new.encode(IO::Memory.new "test").should eq "test"
    AMIME::Encoder::QuotedPrintableContent.new.encode(IO::Memory.new "this is a foo").should eq "this is a foo"

    AMIME::Encoder::QuotedPrintableContent.new.encode(IO::Memory.new "This is a sample string with special characters: ä, ö, ü, and ß.").should eq <<-TXT
      This is a sample string with special characters: =C3=A4, =C3=B6, =C3=BC, an=\r
      d =C3=9F.
      TXT

    AMIME::Encoder::QuotedPrintableContent.new.encode("Iñtërnâtiônàlizætiøn☃💩").should eq <<-TXT
      I=C3=B1t=C3=ABrn=C3=A2ti=C3=B4n=C3=A0liz=C3=A6ti=C3=B8n=E2=98=83=\r
      =F0=9F=92=A9
      TXT
  end
end
