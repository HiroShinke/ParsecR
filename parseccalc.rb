

require 'parsecr.rb'

class Calc 
  include ParsecR

  def tr(reg,&proc) ; tokenA(pR(reg),&proc) ; end
  def ts(str,&proc) ; tokenA(pS(str),&proc) ; end
  
  def createParser 

    pExpr = nil
    
    pAddop = o( tr(/\+/), tr(/-/) ) {
      |w|
      case w.word
      when "+"
        :+.to_proc
      when "-"
        :-.to_proc
      end
    }
    pMulop  = o( tr(/\*/) { |_| :*.to_proc },
                 tr(/\//) { |_| :/.to_proc })
    pDigit  =    tr(/\d+/){ |v| v.word.to_i } 
    pFactor = o( pDigit,
                 para( ts("("), r{ pExpr } , ts(")") ) )
    pTerm   = c( pFactor, pMulop )
    pExpr   = c( pTerm,   pAddop )

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

