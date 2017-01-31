
require "parsecscheme.rb"
require "test/unit"

def atom(str); Atom.new(str); end
def list(*ls); Cons.from_a(ls); end
def dotted(*ls,tail); Cons.from_a(ls,tail); end
def number(v); Number.new(v); end
def str(str); Str.new(str); end
def bool(b); Bool.new(b); end
def quoted(exp); list(atom("quote"),exp); end

class TestSchme < Test::Unit::TestCase
  
  def setup
    @parser = Scheme.new
  end
  
  test "symbol" do
    for w in ["!","#","$","%","&", "|", "*", "+", "-", "/",
              ":", "<", "=", ">", "?", "@", "^", "_", "~" ]
      success,s,t = @parser.runParser(@parser.symbol,w)
      assert_equal w, t.word
    end
    
    for w in ["a","b","\\"]
      success,s,t = @parser.runParser(@parser.symbol,w)
      assert_equal false,success
    end
  end
  
  test "spaces" do
    success,s,t = @parser.runParser(@parser.spaces," ")
    assert_equal true, success
    assert_equal nil, t
    
    success,s,t = @parser.runParser(@parser.spaces,"   ")
    assert_equal true, success
    assert_equal nil, t
  end
  
  test "string" do
    success,s,t = @parser.runParser(@parser.string,'"abc"')
    assert_equal Str.new("abc"), t
  end

  test "atom" do
    success,s,t = @parser.runParser(@parser.atom,"abc")
    assert_equal Atom.new("abc"), t

    success,s,t = @parser.runParser(@parser.atom,"a-b-c")
    assert_equal Atom.new("a-b-c"), t

    success,s,t = @parser.runParser(@parser.atom,"#f")
    assert_equal Bool.new(false), t
    
  end

  test "number" do
    success,s,t = @parser.runParser(@parser.number,"123")
    assert_equal Number.new(123), t
  end

  test "list" do
    success,s,t = @parser.runParser(@parser.list,"a b c")
    assert_equal list(atom("a"),atom("b"),atom("c")),t
  end

  test "expression: atom" do
    success,s,t = @parser.runParser(@parser.expr,"c")
    assert_equal atom("c"),t
  end

  test "dotted" do
    success,s,t = @parser.runParser(@parser.dotted,"a b . c  ")
    assert_equal dotted(atom("a"),atom("b"),atom("c")),t
    success,s,t = @parser.runParser(@parser.dotted,"a b. c  ")
    assert_equal dotted(atom("a"),atom("b"),atom("c")),t
    success,s,t = @parser.runParser(@parser.dotted,"a b.c  ")
    assert_equal dotted(atom("a"),atom("b"),atom("c")),t
  end

  test "list2" do
    success,s,t = @parser.runParser(@parser.expr,"(a b c)")
    assert_equal list(atom("a"),atom("b"),atom("c")), t
  end

  test "dotted2" do
    success,s,t = @parser.runParser(@parser.expr,"(a b . c)")
    assert_equal dotted(atom("a"),atom("b"),atom("c")),t
  end

  test "composit: list->list" do
    success,s,t = @parser.runParser(@parser.expr,"(a b c (d e))")
    assert_equal list(atom("a"),
                      atom("b"),
                      atom("c"),
                      list(atom("d"),
                           atom("e"))),t
  end

  test "composit: dotted->list" do
    success,s,t = @parser.runParser(@parser.expr,"(a b c . (d e))")
    assert_equal dotted(atom("a"),
                        atom("b"),
                        atom("c"),
                        list(atom("d"),
                             atom("e"))),t
  end

  test "quoted: 1" do
    success,s,t = @parser.runParser(@parser.expr,"'a")
    assert_equal quoted(atom("a")), t
  end

  test "quoted: 2" do
    success,s,t = @parser.runParser(@parser.expr,"'(a b)")
    assert_equal quoted(list(atom("a"),
                             atom("b"))), t
  end

  test "quoted: 3" do
    success,s,t = @parser.runParser(@parser.expr,"(a 'b)")
    assert_equal list(atom("a"),
                      quoted(atom("b"))), t
  end

  test "quoted: 4" do
    success,s,t = @parser.runParser(@parser.expr,"(cons a '(b c))")
    assert_equal list(atom("cons"),
                      atom("a"),
                      quoted(list(atom("b"),
                                  atom("c")))),t
  end

  test "quasiquoted: 1" do
    success,s,t = @parser.runParser(@parser.expr,"`a")
    assert_equal list(atom("quasiquote"),atom("a")), t

  end

  test "unquote: 1" do
    success,s,t = @parser.runParser(@parser.expr,",a")
    assert_equal list(atom("unquote"),atom("a")), t
  end

  test "unquote-splicing: 1" do
    success,s,t = @parser.runParser(@parser.expr,",@a")
    assert_equal list(atom("unquote-splicing"),atom("a")), t
  end

  
end
