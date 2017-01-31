

=begin

    a  port of 'written in 48 hours' scheme using ParsecR

=end

require 'parsecr.rb'
require 'schemeobj.rb'
require 'schemeenv.rb'

class Scheme
  include ParsecR

  def self.chainPrim(v=nil,&proc)
    if v != nil
      prim { 
        |env,expr|
        expr.inject(v,&proc)
      }
    else
      prim { 
        |env,expr|
        expr.inject(&proc)
      }
    end
  end

  def self.binPrim(&proc)
      prim { 
        |env,expr|
        h = expr.head
        t = expr.tail.head
        proc.(h,t)
      }
  end
  
  Dict0 = {
    "+"  =>  chainPrim { |m,n| Number.new(m.value + n.value) },
    "-"  =>  chainPrim { |m,n| Number.new(m.value - n.value) },
    "/"  =>  chainPrim { |m,n| Number.new(m.value / n.value) },
    "*"  =>  chainPrim { |m,n| Number.new(m.value * n.value) },
    "eq"  => binPrim   { |m,n| Bool.new(m.value == n.value) },
    "<"  =>  binPrim   { |m,n| Bool.new(m.value < n.value) },
    ">"  =>  binPrim   { |m,n| Bool.new(m.value > n.value) },
    "<=" =>  binPrim   { |m,n| Bool.new(m.value <= n.value) },
    ">=" =>  binPrim   { |m,n| Bool.new(m.value >= n.value) },
    "car" => prim      { |e,expr| expr.car.car },
    "cdr" => prim      { |e,expr| expr.car.cdr },
    "list" => prim     { |e,expr| expr },
    "cons" => prim     { |e,expr|
      car = expr.car
      cdr = expr.cdr.car
      Cons.new(car,cdr)
    },
    "if" => syntax {
      |env,expr0|
      pred  = expr0.car
      texpr = expr0.cdr.car
      eexpr = expr0.cdr.cdr.car
      if pred.eval(env).bool
        texpr.eval(env)
      else
        eexpr.eval(env)
      end
    },
    "let" => syntax {
      |env0,exprs0|
      assignments = exprs0.car
      exprs = exprs0.cdr
      env = Env.new(env0)
      for asgn in assignments
        sym = asgn.car
        val = asgn.cdr.car.eval(env0)
        env.define(sym.str,val)
      end
      ret = nil
      for e in exprs
        ret = e.eval(env)
      end
      ret
    },
    "setq" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,expr.eval(env))
    },
    "define" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,expr.eval(env))
    },
    "def-macro" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,Macro.new(expr.eval(env)))
    },
    "quote" => syntax {
      |env,expr|
      expr.car
    },
    "lambda" => syntax {
      |env,expr|
      Closure.new(expr,env)
    }
  }

  attr :letter, :symbol, :spaces, :string, :atom, :number,
       :expr, :list, :dotted, :quoted
  
  def initialize

    @root = Env.new
    @root.dict = Dict0.clone

    @letter = pR(/[a-z]/i)
    @digit  = pR(/\d/)
    @symbol = pR(/[!#$%&|*+\-\/:<=>?@^_~]/)
    @spaces = k(pR(/\s+/))
    @string = tokenA( para(pS('"'),
                           pR(/[^"]*/),
                           pS('"')) ) {
      |t| Str.new(t.word)
    }
    @atom   = tokenA(
      d( o( @letter, @symbol ),
         m(o(@letter, @symbol, @digit))  )
    ) {
      |*ts|
      s = ts.map { |t| t.word }.join("")
      case s
      when "#t"
        Bool.new(true)
      when "#f"
        Bool.new(false)
      else
        Atom.new(s)
      end
    }
    @number = tokenA( m1( @digit ) ) { |*ts|
      i = ts.map { |t| t.word }.join("").to_i
      Number.new(i)
    }

    @list = m( r{@expr} ) {
      |*ts| Cons.from_a( ts )
    }

    @dotted = d(
      m1( r{@expr} ), tS("."), r{@expr}
    ) {
      |*head,dot,tail|
      Cons.from_a(head,tail)
    }

    @quoted = d( pS("'"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("quote"), expr])
    }

    @quasiquote = d( pS("`"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("quasiquote"), expr])
    }

    @unquote = d( pS(","), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("unquote"), expr])
    }

    @unquote_splicing = d( pS(",@"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("unquote-splicing"), expr])
    }
    
    @expr = o( @atom,
               @string,
               @number,
               @quoted,
               @quasiquote,
               @unquote_splicing,
               @unquote,
               para( tS("("),
                     o( u(@dotted), @list ),
                     tS(")") )
             )

    @expr1 = d(opt(@spaces), @expr )

  end

  def mainLoop
    buff = ""
    begin
      loop do
        str=readline
        buff += str
        if (pos = (buff =~ /;/)) != nil then
          print evalLine(buff[0,pos]),"\n"
          buff = ""
        end
      end
    rescue EOFError
    rescue Exception => e
      p e
    end
  end
  
  def evalLine(s)
    success,s,w = runParser(@expr1,s)
    w.eval(@root)
  end

end

if __FILE__ == $PROGRAM_NAME
  (Scheme.new).mainLoop()
end
