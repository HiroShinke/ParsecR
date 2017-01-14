

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

class Scheme
  include ParsecR

  attr :letter, :symbol, :spaces, :string, :atom, :number,
       :expr, :list, :dotted
  
  def initialize
    @letter = pR(/\w/)
    @digit  = pR(/\d/)
    @symbol = pR(/[!#$%&|*+\-\/:<=>?@^_~]/)
    @spaces = k(pR(/\s+/))
    @string = para(pS('"'),
                   pR(/[^"]*/),
                   pS('"')) { |t| Str.new(t.word) }
    @atom   = d( o( @letter, @symbol ),
                 m(o(@letter, @symbol, @digit))  ) {
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
    @number = m1( @digit ) { |*ts|
      i = ts.map { |t| t.word }.join("").to_i
      Number.new(i)
    }

    @list = seb( r{@expr}, @spaces) {
      |*ts| List.new( ts )
    }

    @dotted = d(
      seb1( r{@expr}, @spaces ),
      pS("."), opt(@spaces), r{@expr}, opt(@spaces)
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
               para( pS("("),
                     o( u(@dotted), @list ),
                     pS(")") )
             )

  end

  def mainLoop
    buff = ""
    begin
      loop do
        str=readline
        buff += str
        if (pos = (buff =~ /;/)) != nil then
          p runParser(@expr,buff[0,pos])
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
