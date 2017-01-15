

require 'parsecr'
require 'test/unit'

include ParsecR

class ParserTest < Test::Unit::TestCase
  
  def setup
  end

  test "test pR: success" do

    p = pR(/\w+/)
    success,s,w = runParser(p,"abc")
    assert_equal w.line,  1
    assert_equal w.pos,   0
    assert_equal w.word, "abc"
    
  end

  test "test pR: failed" do

    p = pR(/\w+/)
    success,s,w = runParser(p,"")
    assert_equal success,false
    assert_equal s.pos,  0
    
  end
  
  test "test pR: parse at eos" do

    p = d(pS("abc"),pR(/\w+/))
    success,s,w0,w1 = runParser(p,"abc")
    assert_equal success,false
    assert_equal s.pos  ,3
    assert_equal w0     ,nil
    
  end

  test "test token(pR)" do

    p = token(pR(/\w+/))
    success,s,w = runParser(p,"abc ")
    assert_equal w.line,  1
    assert_equal w.pos,   0
    assert_equal w.word, "abc"
    
  end

  test "test multiline" do

    p0 = token(pR(/\w+/))
    p  = d(p0,p0)
    success,s,w1,w2 = runParser(p,"abc \n efg ")
    assert_equal w1.word, "abc"
    assert_equal w2.word, "efg"
    assert_equal w2.pos,  6
    assert_equal w2.column, 1
    assert_equal w2.line, 2

  end

  test "test pR: ignore case" do

    p = pR(/abc/i)
    success,s,w = runParser(p,"ABC")
    assert_equal w.word, "ABC"

  end
  
end

