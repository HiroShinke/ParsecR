

require 'parsecr'
require 'test/unit'

include ParsecR

def tr(r); token(pR(r)); end
def ts(s); token(pS(s)); end
def trw(r); tokenA(pR(r)) { |t| t.word }; end
def tsw(s); tokenA(pS(s)) { |t| t.word }; end

class ParserTest < Test::Unit::TestCase
  
  def setup
  end

  # pDo
  # 

  test "pDo: abc: success" do
    abc = d( ts("a"), ts("b"), ts("c" ) )
    success,s,w1,w2,w3 = runParser(abc,"abc")
    assert_equal "a", w1.word
    assert_equal "b", w2.word
    assert_equal "c", w3.word
  end

  test "pDo: abc: failed" do
    abc = d( ts("a"), ts("b"), ts("c" ) )
    success,s,w1,w2,w3 = runParser(abc,"abd")
    assert_equal false, success
    assert_equal 2, s.pos
    assert_equal nil, w1
    assert_equal nil, w2
    assert_equal nil, w3
  end

  # pO
  #

  test "pO: abc: success" do
    abc = o( ts("a"), ts("b"), ts("c" ) )
    success,s,w = runParser(abc,"a")
    assert_equal "a", w.word
    success,s,w = runParser(abc,"b")
    assert_equal "b", w.word
    success,s,w = runParser(abc,"c")
    assert_equal "c", w.word
  end

  test "pO: abc: failed" do
    abc = o( ts("a"), ts("b"), ts("c" ) )
    success,s,w = runParser(abc,"d")
    assert_equal false, success
    assert_equal 0, s.pos
    assert_equal nil, w
  end

  test "pO: failed if token consumed" do
    p1  = d( tsw("a"), tsw("b") )
    p2  = d( tsw("a"), tsw("c") )
    abac = o( p1, p2 )
    success,s,*w = runParser(abac,"ab")
    assert_equal ["a", "b"], w
    success,s,*w = runParser(abac,"ac")
    assert_equal false, success
  end

  # pU
  #
  
  test "pO and pU: combined with pU" do
    p1  = d( tsw("a"), tsw("b") )
    p2  = d( tsw("a"), tsw("c") )
    abac = o( u(p1), p2 )
    success,s,*w = runParser(abac,"ab")
    assert_equal ["a", "b"], w
    success,s,*w = runParser(abac,"ac")
    assert_equal ["a", "c"], w
  end
  
  # pM
  #
  test "pM" do
    p  = m( d( tsw("a"), tsw("b") ) )
    success,s,*w = runParser(p,"ababab")
    assert_equal ["a", "b","a", "b","a", "b"], w
    success,s,*w = runParser(p,"abababac")
    assert_equal ["a", "b","a", "b","a", "b"], w
    success,s,*w = runParser(p,"ac")
    assert_equal [], w
  end

  test "pM1" do
    p  = pM1( d( tsw("a"), tsw("b") ) )
    success,s,*w = runParser(p,"ababab")
    assert_equal ["a", "b","a", "b","a", "b"], w
    success,s,*w = runParser(p,"abababac")
    assert_equal ["a", "b","a", "b","a", "b"], w
    success,s,*w = runParser(p,"ac")
    assert_equal false, success
    assert_equal 1, s.pos
    assert_equal [], w
  end

  test "pSepBy1" do
    p  = sb1( tsw("a"), tsw(",") ) 
    success,s,*w = runParser(p,"a")
    assert_equal ["a"], w
    success,s,*w = runParser(p,"a,a")
    assert_equal ["a","a"], w
    success,s,*w = runParser(p,"a,")
    assert_equal ["a"], w                # is this appropriate?
  end


  

end

