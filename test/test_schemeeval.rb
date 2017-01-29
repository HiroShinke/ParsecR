
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
  
  test "setq 1: number: return" do
    x = @parser.evalLine("(setq a 1)")
    assert_equal 1,x.value
  end

  test "setq 1: nubmer: reference" do
    @parser.evalLine("(setq a 1)")
    x = @parser.evalLine("a")
    assert_equal Number.new(1),x
  end

  test "setq 1: symbol: reference" do
    @parser.evalLine("(setq a 'b)")
    x = @parser.evalLine("a")
    assert_equal Atom.new("b"),x
  end

  test "setq 1: cons: reference" do
    @parser.evalLine("(setq a '(a b c))")
    x = @parser.evalLine("a")
    assert_equal list(atom("a"),atom("b"),atom("c")),x
  end

  test "car 1:" do
    x = @parser.evalLine("(car '(a b c))")
    assert_equal atom("a"), x
  end

  test "car 2: null" do
    assert_raise(NoMethodError) do
      @parser.evalLine("(car '())")
    end
  end

  test "cdr 1:" do
    x = @parser.evalLine("(cdr '(a b c))")
    assert_equal list(atom("b"),atom("c")),x
  end

  test "cdr 2: nil" do
    x = @parser.evalLine("(cdr '(a))")
    assert_equal Nil::NIL, x
  end

  test "cdr 3: nil" do
    assert_raise(NoMethodError) do
      @parser.evalLine("(cdr '())")
    end
  end

  test "cons:" do
    x = @parser.evalLine("(cons 'a '(b c))")
    assert_equal list(atom("a"),atom("b"),atom("c")),x
  end
  
  test "+" do
    x = @parser.evalLine("(+ 1 2 3)")
    assert_equal Number.new(6), x
  end

  test "let" do
    x = @parser.evalLine("(let ((a 1)(b 2)) (+ a b))")
    assert_equal Number.new(3), x
  end

  test "lambda: 1" do
    @parser.evalLine("(setq f (lambda (n m) (+ n m)) )")
    x = @parser.evalLine("(f 1 2)")
    assert_equal Number.new(3), x
  end

  test "lambda: 2" do
    x = @parser.evalLine("((lambda (n m) (+ n m)) 1 2)")
    assert_equal Number.new(3), x
  end

  test "if: 1" do
    x = @parser.evalLine("(if #t 1 2)")
    assert_equal Number.new(1), x
  end

  test "if: 2" do
    x = @parser.evalLine("(if #f 1 2)")
    assert_equal Number.new(2), x
  end

  test "quote" do
    x = @parser.evalLine("(quote a)")
    assert_equal Atom.new("a"), x
  end

  test "quote: '" do
    x = @parser.evalLine("'a")
    assert_equal Atom.new("a"), x
  end

  
end