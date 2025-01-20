require "../spec_helper"

struct TableStyleSpec < ASPEC::TestCase
  def test_getter_setters : Nil
    style = ACON::Helper::Table::Style
      .new
      .align(:right)
      .border_format("BF")
      .padding_char('c')
      .header_title_format("HTF")
      .footer_title_format("FTF")
      .cell_header_format("CHF")
      .cell_row_format("CRF")
      .cell_row_content_format("CRCF")
      .horizontal_border_chars('o', 'i')
      .vertical_border_chars('v', 'u')
      .default_crossing_char('x')

    style.align.should eq ACON::Helper::Table::Alignment::RIGHT
    style.border_format.should eq "BF"
    style.padding_char.should eq 'c'
    style.header_title_format.should eq "HTF"
    style.footer_title_format.should eq "FTF"
    style.cell_header_format.should eq "CHF"
    style.cell_row_format.should eq "CRF"
    style.cell_row_content_format.should eq "CRCF"
    style.border_chars.should eq({"o", "v", "i", "u"})
    style.crossing_chars.should eq({"x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x"})

    style.crossing_chars("c", "tl", "tm", "tr", "mr", "br", "bm", "bl", "ml", "tlb", "tmb", "trb")
    style.crossing_chars.should eq({"c", "tl", "tm", "tr", "mr", "br", "bm", "bl", "ml", "tlb", "tmb", "trb"})
  end
end
