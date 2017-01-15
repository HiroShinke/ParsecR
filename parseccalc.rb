
=begin

    A simple calculator program using ParsecR.

    This is a straightforward port of 
    an example of the use of pChainl1 
    in the Text.Parsec hackage page

=end

require 'parsecr.rb'

class Calc 
  include ParsecR

  def tr(reg,&proc) ; tokenA(pR(reg),&proc) ; end
  def ts(str,&proc) ; tokenA(pS(str),&proc) ; end

  def createParser 

    pExpr = nil

    spaces  = k(pR(/\s*/))
    pAddop  = o( tr(/\+/) { |_| :+.to_proc },
                 tr(/-/ ) { |_| :-.to_proc })
    pMulop  = o( tr(/\*/) { |_| :*.to_proc },
                 tr(/\//) { |_| :/.to_proc })
    pDigit  =    tr(/\d+/){ |v| v.word.to_i } 
    pFactor = o( pDigit,
                 para( ts("("), r{ pExpr } , ts(")") ) )
    pTerm   = c( pFactor, pMulop )
    pExpr   = c( pTerm,   pAddop )

    d(spaces, pExpr)
  end

  def mainLoop 
    pExpr = createParser
    buff = ""
    begin
      loop do
        str=readline
        buff += str
        if (pos = (buff =~ /;/)) != nil then
          p runParser(pExpr,buff[0,pos])
          buff = ""
        end
      end
    rescue EOFError
    rescue Exception => e
      p e
    end
  end

end

c = Calc.new
c.mainLoop

