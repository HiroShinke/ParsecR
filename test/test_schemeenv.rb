
require "schemeenv.rb"
require "test/unit"

class TestSchme < Test::Unit::TestCase
  
  test "basic env.set get" do
    e = Env.new
    e.define("abc","12345")
    assert_equal e.get("abc"), "12345"
  end

  test "env.get from parent" do
    p = Env.new
    p.define("abc","12345")
    e = Env.new(p)
    assert_equal e.get("abc"), "12345"
  end

  test "env.set to parent" do
    p = Env.new
    p.define("abc","12345")
    e = Env.new(p)
    e.set("abc","67890")
    assert_equal p.get("abc"), "67890"
  end

  test "env.set to undefined" do
    p = Env.new
    assert_raise(RuntimeError.new("variable abc not defined!!")) do
      p.set("abc","12345")
    end
  end

  test "env.define already defined" do
    p = Env.new
    p.define("abc","12345")
    assert_raise(RuntimeError.new("variable abc already defined!!")) do
      p.define("abc","12345")
    end
  end

  
end
