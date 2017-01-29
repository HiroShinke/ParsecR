
require "schemeobj.rb"
require "test/unit"

def atom(str); Atom.new(str); end
def list(*ls); Cons.from_a(ls); end
def dotted(*ls,tail); Cons.from_a(ls,tail); end
def number(v); Number.new(v); end
def str(str); Str.new(str); end
def bool(b); Bool.new(b); end
def quoted(exp); list(atom("quote"),exp); end

class TestSchme < Test::Unit::TestCase
  
  test "basic cons.inject(10)" do
    e = Cons.from_a([1,2,3])
    assert_equal 16, e.inject(10) { |m,n| m + n }
  end

  test "basic cons.inject" do
    e = Cons.from_a([1,2,3])
    assert_equal 6, e.inject { |m,n| m + n }
  end

  test "basic cons for i" do
    e = Cons.from_a([1,2,3])
    r = ""
    for i in e
      r = r + i.to_s
    end
    assert_equal "123", r
  end

  test "basic cons.each" do
    e = Cons.from_a([1,2,3])
    r = ""
    e.each { |i|
      r = r + i.to_s
    }
    assert_equal "123", r
  end

  test "to_s: list" do
    c = list(atom("a"),atom("b"),atom("c"))
    assert_equal "(a b c)", c.to_s
  end

  test "to_s: dotted" do
    c = dotted(atom("a"),atom("b"),atom("c"))
    assert_equal "(a b . c)", c.to_s
  end

  test "basic cons.from_a empty" do
    e = Cons.from_a([])
    assert_equal "()", e.to_s
  end

end
