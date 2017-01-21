

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


class Env

  attr :parent,:dict
  
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

  PRIMITIVES = {
    "+" => lambda { |m,n| Number.new(m.value + n.value) },
    "-" => lambda { |m,n| Number.new(m.value - n.value) },
    "/" => lambda { |m,n| Number.new(m.value / n.value) },
    "*" => lambda { |m,n| Number.new(m.value * n.value) },
    "<" => lambda { |m,n| Bool.new(m.value < n.value) },
    ">" => lambda { |m,n| Bool.new(m.value > n.value) },
    "<=" => lambda { |m,n| Bool.new(m.value <= n.value) },
    ">=" => lambda { |m,n| Bool.new(m.value >= n.value) },
    "car" => lambda { |m|
      car,*cdr = m.ls
      car
    },
    "cdr" => lambda { |m|
      car,*cdr = m.ls
      List.new(cdr)
    },
    "cons" => lambda { |car,cdr|
      List.new([car,*(cdr.ls)])
    }
  }

  def eval(env)
    func0,*args0 = ls
    if func0.instance_of?(Atom) then
      case func0.str
      when "if"
        func0,pred,texpr,eexpr = ls
        if pred.eval.bool
          texpr.eval
        else
          eexpr.eval
        end
      when "quote"
        func0,rest = ls
        rest
      else
        func,*args = ls.map { |e| e.eval }    
        apply(func,*args)
      end
    end
  end

  def apply(func,*args)
    name = func.str
    if proc = PRIMITIVES[name]
      proc.(*args)
    else
      raise "unknown primitive function"
    end
  end
  
  def to_s
    "(" + ls.map { |e| e.to_s }.join(" ") + ")"
  end

end
  
class DottedList

end

class Atom
  def eval
    self
  end
  def to_s
    str.to_s
  end
end

class Number
  def eval
    self
  end
  def to_s
    value.to_s
  end
end

class Str
  def eval
    self
  end
  def to_s
    str.to_s
  end
end

class Bool
  def eval
    self
  end
  def to_s
    if bool then "#t" else "#f" end
  end
end

class Scheme
  include ParsecR

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
          print w.eval,"\n"
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
