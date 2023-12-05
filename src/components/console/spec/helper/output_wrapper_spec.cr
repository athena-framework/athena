struct OutputWrapperTest < ASPEC::TestCase
  def test_wrap_no_cut : Nil
    ACON::Helper::OutputWrapper.new.wrap(
      "Árvíztűrőtükörfúrógép https://github.com/crystal/crystal Lorem ipsum <comment>dolor</comment> sit amet, consectetur adipiscing elit. Praesent vestibulum nulla quis urna maximus porttitor. Donec ullamcorper risus at <error>libero ornare</error> efficitur.",
      20,
    ).should eq <<-TEXT
    Árvíztűrőtükörfúrógé
    p https://github.com/crystal/crystal Lorem ipsum
    <comment>dolor</comment> sit amet,
    consectetur
    adipiscing elit.
    Praesent vestibulum
    nulla quis urna
    maximus porttitor.
    Donec ullamcorper
    risus at <error>libero
    ornare</error> efficitur.
    TEXT
  end

  def test_wrap_with_cut : Nil
    ACON::Helper::OutputWrapper.new(true).wrap(
      "Árvíztűrőtükörfúrógép https://github.com/crystal/crystal Lorem ipsum <comment>dolor</comment> sit amet, consectetur adipiscing elit. Praesent vestibulum nulla quis urna maximus porttitor. Donec ullamcorper risus at <error>libero ornare</error> efficitur.",
      20,
    ).should eq <<-TEXT
    Árvíztűrőtükörfúrógé
    p
    https://github.com/c
    rystal/crystal Lorem
    ipsum <comment>dolor</comment> sit
    amet, consectetur
    adipiscing elit.
    Praesent vestibulum
    nulla quis urna
    maximus porttitor.
    Donec ullamcorper
    risus at <error>libero
    ornare</error> efficitur.
    TEXT
  end
end
