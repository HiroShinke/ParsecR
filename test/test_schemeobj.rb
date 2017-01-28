
require "schemeobj.rb"
require "test/unit"

class TestSchme < Test::Unit::TestCase
  
  test "basic cons.from_a" do
    e = Cons.from_a([1,2,3])
    assert_equal "(1 2 3)", e.to_s
  end

  test "basic cons.from_a empty" do
    e = Cons.from_a([])
    assert_equal "()", e.to_s
  end

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

  

end
