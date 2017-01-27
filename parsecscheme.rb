

=begin

    a  port of 'written in 48 hours' scheme using ParsecR

=end

require 'parsecr.rb'
require 'schemeobj.rb'

class Env

  attr :parent
  attr_accessor :dict
  
  def initialize(par = nil)
    @parent = par
    @dict = {}
  end
  
  def get(k)
    if dict.key?(k)
      dict[k]
    elsif parent
      parent.get(k)
    else
      nil
    end
  end

  def set(k,v)
    if dict.key?(k)
      dict[k] = v
    elsif parent
      parent.set(k,v)
    else
      raise "variable not defined!!"
    end
  end

  def define(k,v)
    if dict.key?(k)
      raise "variable already defined!!"
    else
      dict[k] = v
    end
  end

end


class Scheme
  include ParsecR

  Root = Env.new
  Root.dict = {
    "#t" => Bool.new(true),
    "#f" => Bool.new(false),
    "+" =>  prim { |e,m,n| Number.new(m.value + n.value) },
    "-" =>  prim { |e,m,n| Number.new(m.value - n.value) },
    "/" =>  prim { |e,m,n| Number.new(m.value / n.value) },
    "*" =>  prim { |e,m,n| Number.new(m.value * n.value) },
    "<" =>  prim { |e,m,n| Bool.new(m.value < n.value) },
    ">" =>  prim { |e,m,n| Bool.new(m.value > n.value) },
    "<=" => prim { |e,m,n| Bool.new(m.value <= n.value) },
    ">=" => prim { |e,m,n| Bool.new(m.value >= n.value) },
    "car" => prim { |e,m| m.car },
    "cdr" => prim { |e,m| m.cdr },
    "cons" => prim { |e,car,cdr|
      List.new([car,*(cdr.ls)])
    },
    "if" => syntax {
      |env,pred,texpr,eexpr|
      if pred.eval(env).bool
        texpr.eval(env)
      else
        eexpr.eval(env)
      end
    },
    "let" => syntax {
      |env0,assignments,*exprs|
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
      |env,sym,expr|
      env.define(sym.str,expr.eval(env))
    },
    "quote" => syntax {
      |env,expr|
      expr
    }
  }

  attr :letter, :symbol, :spaces, :string, :atom, :number,
       :expr, :list, :dotted, :quoted
  
  def initialize
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
      Atom.new(s)
    }
    @number = tokenA( m1( @digit ) ) { |*ts|
      i = ts.map { |t| t.word }.join("").to_i
      Number.new(i)
    }

    @list = m( r{@expr} ) {
      |*ts| List.new( ts )
    }

    @dotted = d(
      m1( r{@expr} ), tS("."), r{@expr}
    ) {
      |*head,dot,tail|
      DottedList.new(head,tail)
    }

    @quoted = d( pS("'"), r{@expr} ) {
      |apos,expr|
      List.new([Atom.new("quote"), expr])
    }

    @expr = o( @atom,
               @string,
               @number,
               @quoted,
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
          success,s,w = runParser(@expr1,buff[0,pos])
          print w.eval(Root),"\n"
          buff = ""
        end
      end
    rescue EOFError
    rescue Exception => e
      p e
    end
  end
  
end

if __FILE__ == $PROGRAM_NAME
  (Scheme.new).mainLoop()
end
