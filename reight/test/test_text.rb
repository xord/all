require_relative 'helper'


class TestText < Test::Unit::TestCase

  def test_insert()
    t        = text
    modified = false
    t.modified {modified = true}

    t.insert 0,  "a\nb\nc"
    assert_equal "a\nb\nc",         t.to_s
    assert_true                     modified
    modified = false

    t.insert 0,  "x"
    assert_equal "xa\nb\nc",        t.to_s
    assert_true                     modified
    modified = false

    t.insert 0,  "\n"
    assert_equal "\nxa\nb\nc",      t.to_s
    assert_true                     modified
    modified = false

    t.insert 3,      "y"
    assert_equal "\nxay\nb\nc",     t.to_s
    assert_true                     modified
    modified = false

    t.insert t.to_s.size,   "z"
    assert_equal "\nxay\nb\ncz",    t.to_s
    assert_true                     modified
    modified = false

    t.insert t.to_s.size - 1, "_"
    assert_equal   "\nxay\nb\nc_z", t.to_s
    assert_true                     modified
    modified = false

    t.insert 0,    ''
    assert_equal   "\nxay\nb\nc_z", t.to_s
    assert_false                    modified

    assert_raise(ArgumentError)         {t.insert 0.1, "!"}
    assert_false modified

    assert_raise(R8::Text::NoLineError) {t.insert(-1,  "!")}
    assert_false modified

    assert_raise(R8::Text::NoLineError) {t.insert t.to_s.size + 1, "!"}
    assert_false modified
  end

  def test_replace()
    t        = text "a\nb\nc"
    modified = false
    t.modified {modified = true}

    t.replace 0, 0, "x"
    assert_equal    "xa\nb\nc",      t.to_s
    assert_true                      modified
    modified = false

    t.replace 0, 1, "\n"
    assert_equal    "\na\nb\nc",     t.to_s
    assert_true                      modified
    modified = false

    t.replace 1, 3, "y"
    assert_equal  "\ny\nc",          t.to_s
    assert_true                      modified
    modified = false

    t.replace 2, -1, "1\n2\n3\n"
    assert_equal   "\n1\n2\n3\n\nc", t.to_s
    assert_true                      modified
    modified = false

    t.replace t.to_s.size, 0,  "q"
    assert_equal "\n1\n2\n3\n\ncq",  t.to_s
    assert_true                      modified
    modified = false

    t.replace t.to_s.size, -1, "p"
    assert_equal "\n1\n2\n3\n\ncp",  t.to_s
    assert_true                      modified
    modified = false

    t.replace 1, 1, "1"
    assert_equal  "\n1\n2\n3\n\ncp", t.to_s
    assert_false                     modified

    t.replace 1, 3, "1\n2"
    assert_equal  "\n1\n2\n3\n\ncp", t.to_s
    assert_false                     modified

    t.replace 1, 5, "1\n2\n3"
    assert_equal  "\n1\n2\n3\n\ncp", t.to_s
    assert_false                     modified

    t.replace 1, 7, "1\n2\n3\n\n"
    assert_equal  "\n1\n2\n3\n\ncp", t.to_s
    assert_false                     modified

    assert_raise(ArgumentError) {t.replace  0.1, 0,   "!"}
    assert_false modified

    assert_raise(ArgumentError) {t.replace  0,   0.1, "!"}
    assert_false modified

    assert_raise(R8::Text::NoLineError) {t.replace(-1, 0,  "!")}
    assert_false modified

    assert_raise(R8::Text::NoLineError) {t.replace  0, -1, "!"}
    assert_false modified

    assert_raise(R8::Text::NoLineError) {t.replace t.to_s.size, 1, "!"}
    assert_false modified
  end

  def test_clear()
    t = text "a\nb\nc"
    t.clear
    assert_equal '', t.to_s
  end

  def test_enumerable()
    assert_equal [""],                         text                .map(&:to_s)
    assert_equal ["abcd"],                     text("abcd")        .map(&:to_s)
    assert_equal ["a\n", "b\n", "cd"],         text("a\nb\ncd")    .map(&:to_s)
    assert_equal ["a\r", "b\n", "c\r\n", "d"], text("a\rb\nc\r\nd").map(&:to_s)
    assert_equal [ "\n",  "\r",  "\r\n", ""],  text("\n\r\r\n")    .map(&:to_s)
    assert_equal [ "\n",  "\r",  "\r\n", " "], text("\n\r\r\n ")   .map(&:to_s)
  end

  def test_each_line()
    assert_equal(
      [["cd\n", 1..1], ["ef\n", 0..1], ["gh\n", 0..0]],
      text("ab\ncd\nef\ngh\nij").each_line(4, 6).map {[_1.to_s, _2]})
  end

  def test_size()
    assert_equal 1, text                .size
    assert_equal 1, text("a")           .size
    assert_equal 2, text("a\n")         .size
    assert_equal 2, text("a\nb")        .size
    assert_equal 3, text("a\nb\r")      .size
    assert_equal 3, text("a\nb\rc")     .size
    assert_equal 4, text("a\nb\rc\r\n") .size
    assert_equal 4, text("a\nb\rc\r\nd").size
    assert_equal 4, text("\n\r\r\n")    .size
    assert_equal 4, text("\n\r\r\n ")   .size
  end

  def test_empty?()
    assert_true  text            .empty?
    assert_false text("a")       .empty?
    assert_false text("\n")      .empty?
    assert_false text("\n\r")    .empty?
    assert_false text("\n\r\r\n").empty?
  end

  def test_at()
    assert_equal "a\n", text("a\nb\nc")[0].to_s
    assert_equal "b\n", text("a\nb\nc")[1].to_s
    assert_equal "c",   text("a\nb\nc")[2].to_s
  end

  def test_to_s()
    assert_equal "",             text("")            .to_s
    assert_equal "abcd",         text("abcd")        .to_s
    assert_equal "a\nbcd",       text("a\nbcd")      .to_s
    assert_equal "a\nb\rc\r\nd", text("a\nb\rc\r\nd").to_s
    assert_equal "abcd\n",       text("abcd\n")      .to_s
    assert_equal "abcd\r",       text("abcd\r")      .to_s
    assert_equal "abcd\r\n",     text("abcd\r\n")    .to_s
  end

  private

  Text = R8::Text

  def text(str = '') = Text.new str

end# TestText
