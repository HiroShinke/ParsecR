

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

class List

  PRIMITIVES = {
    "+" => lambda { |m,n| m + n },
    "-" => lambda { |m,n| m - n },
    "/" => lambda { |m,n| m / n },
    "*" => lambda { |m,n| m * n }
  }
  
  def eval
    func,*args = ls.map { |e| e.eval }
    apply(func,*args)
  end

  def apply(func,*args)
    name = func.str
    if proc = PRIMITIVES[name]
      proc.(*args)
    else
      raise "unknown primitives"
    end
  end
  
end
  
class DottedList

end

class Atom
  def eval
    self
  end
end

class Number
  def eval
    value
  end
end

class Str
  def eval
    self
  end
end

class Bool
  def eval
    self
  end
end

class Scheme
  include ParsecR

  attr :letter, :symbol, :spaces, :string, :atom, :number,
       :expr, :list, :dotted
  
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
          p w.eval
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
