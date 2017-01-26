

=begin

    a  port of 'written in 48 hours' scheme using ParsecR

=end

require 'parsecr.rb'

Atom       = Struct.new(:str)
List       = Struct.new(:ls)
DottedList = Struct.new(:ls,:tail)
Number     = Struct.new(:value)
Str        = Struct.new(:str)
Bool       = Struct.new(:bool)
Prim       = Struct.new(:proc)
Syntax     = Struct.new(:proc)
Closure    = Struct.new(:expr,:env)
Macro      = Struct.new(:expr)

def prim(&proc)
  Prim.new(proc)
end

def syntax(&proc)
  Syntax.new(proc)
end


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

class List

  def eval(env)
    func0,*args0 = ls
    func = func0.eval(env)
    func.apply(env,*args0)
  end
  
  def to_s
    "(" + ls.map { |e| e.to_s }.join(" ") + ")"
  end

end
  
class DottedList

end

class Atom
  def eval(env)
    o = env.get(str)
    o
  end
  def to_s
    str.to_s
  end
end

class Number
  def eval(env)
    self
  end
  def to_s
    value.to_s
  end
end

class Str
  def eval(env)
    self
  end
  def to_s
    str.to_s
  end
end

class Bool
  def eval(env)
    self
  end
  def to_s
    if bool then "#t" else "#f" end
  end
end

class Prim
  def eval(env)
    self
  end
  def apply(env,*args0)
    args = args0.map { |e| e.eval(env) }    
    proc.(env,*args)
  end
end

class Syntax
  def eval(env)
    self
  end
  def apply(env,*args)
    proc.(env,*args)
  end
end

class Scheme
  include ParsecR

  Root = Env.new
  Root.dict = {
    "+" =>  prim { |e,m,n| Number.new(m.value + n.value) },
    "-" =>  prim { |e,m,n| Number.new(m.value - n.value) },
    "/" =>  prim { |e,m,n| Number.new(m.value / n.value) },
    "*" =>  prim { |e,m,n| Number.new(m.value * n.value) },
    "<" =>  prim { |e,m,n| Bool.new(m.value < n.value) },
    ">" =>  prim { |e,m,n| Bool.new(m.value > n.value) },
    "<=" => prim { |e,m,n| Bool.new(m.value <= n.value) },
    ">=" => prim { |e,m,n| Bool.new(m.value >= n.value) },
    "car" => prim { |e,m|
      car,*cdr = m.ls
      car
    },
    "cdr" => prim { |e,m|
      car,*cdr = m.ls
      List.new(cdr)
    },
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
      if s == "#t" then
        Bool.new(true)
      elsif s == "#f" then
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
