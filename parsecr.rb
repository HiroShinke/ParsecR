
=begin

     Yet Another Parsec like parser combinator library for Ruby

=end

require 'strscan'

class ParserState

  attr :stream, :pos, :lineno, :column, :scanner

  def initialize(str,pos=0,lineno=1,column=0)
    @stream = str
    @scanner = StringScanner.new(str)
    @scanner.pos = pos
    @pos    = pos
    @lineno = lineno
    @column = column
  end

  def forwardPos(p)
    str = scanner.peek(p);
    nc = str.count("\n")
    ln = str.split(/\n/,-1)
    ParserState.new(@stream,
                    @pos + p,
                    @lineno + nc,
                    nc == 0 ? @column + p : ln[-1].length 
                   )
  end

  def ==(o)
    pos == o.pos
  end

  def [](i,len)
    @stream[i,len]
  end

  def eos?
    ! ( @pos < @stream.length )
  end
end

Token = Struct.new( :word, :pos, :line, :column )

module ParsecR

  FAILED  = false
  SUCCESS = true
  
  def runParser(p,str)
    s = ParserState.new(str)
    p.(s)
  end
  
  def pChar(pred)
    lambda {
      |s|
      if true then      
        if (w = pred.(s)) != nil then
          return [SUCCESS,s.forwardPos(w.length),
                  Token.new(w,s.pos,s.lineno,s.column) ]
        else
          return [FAILED,s]
        end
      else
          return [FAILED,s]        
      end
    }
  end

  def pNotChar(pred)
    lambda {
      |s|
      if ! s.eos? then
        if pred.(s) != nil then
          return [FAILED,s]
        else
          return [SUCCESS,s.forwardPos(1),
                  Token.new(s.scanner.peek(1),s.pos,s.lineno,s.column)]
        end
      else
        return [FAILED,s]
      end
    }
  end

  def predString(str)
    len = str.length
    lambda { |s|
      if( s.scanner.peek(len) == str ) then
        str
      else
        nil
      end
    }
  end

  def predRegexp(regexp0)
    lambda { |s|
      if( (str = s.scanner.check(regexp0)) != nil) then
        str
      else
        nil
      end
    }
  end

  def pS(str);     pChar( predString(str) );   end
  def pR(regexp);  pChar( predRegexp(regexp)); end
  def pNS(str);    pNotChar( predString(str)); end 
  def pNR(regexp); pNotChar( predRegexp(regexp)); end
  def pAny;        pChar( ->(s){s.scanner.peek(1)} ); end
  def pEof;        pNotFollowdBy(pAny);        end
  
  ############# high level parsers ##################################

  def token(p)
    pU( pD( p, pK( pR(/\s*/) ) ) )
  end

  def tR(regexp); token(pR(regexp)); end

  def tS(str)   ; token(pS(str));    end  

  # lazy evaluation for mutualy recursive parser
  def pRef(&b)
    p = nil
    lambda {
      |s|
      if p == nil then p = b.call() end
      p.(s)
    }
  end    
  
  def pOk(v)
    lambda {
      |s|
      return [SUCCESS,s,v]
    }
  end

  def pFail(str)
    lambda {
      |s|
      if str != null
      then
        print str
      end
      return [FAILED,s]
    }
  end

  # A is for Action
  # (block interface)
  def pA(p,&func)
    pAl(p,func)
  end

  # (lamda interface)
  def pAl(p,func)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if( success) then
        return [SUCCESS,s0,func.(*w)]      
      else
        return [FAILED,s0]
      end
    }
  end
  
  # G is for get
  def pG(p,func)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if( success) then
        func.(*w)
        return [SUCCESS,s0,*w]      
      else
        return [FAILED,s0]
      end
    }
  end

  # for Debug
  def pDebug(label,p)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if(success) then
        print "label=#{label}:success:w=#{w},pos=#{s.pos}\n";
        return [SUCCESS,s0,*w]      
      else
        print "label=#{label}:failed:pos=#{s.pos}\n";
        return [FAILED,s0]
      end
    }
  end

  # F is for filter
  def pF(p,func)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if(success) then
        if func.(*w) then
          return [SUCCESS,s0,*w]
        else
          return [FAILED,s]
        end
      else
        return [FAILED,s0]
      end
    }
  end

  # L is for label
  def pL(str,p)
    lambda {
      |s|
      success,s0,*w = p.(s)      
      if success
        return [SUCCESS,s0,[str,[*w]]]
      else
        return [FAILED,s0]
      end
    }
  end

  # K is for skip
  def pK(p)
    lambda {
      |s|
      success,s0,_ = p.(s)      
      if success
        return [SUCCESS,s0]
      else
        return [FAILED,s0]
      end
    }
  end

  def pKS(str)
    pK(pS(str))
  end

  # D is for "do"
  # the 'monadic' sequence of parsers
  def pD(*ps)
    lambda {
      |s|
      ret = []
      for p in ps
        success,s,*w = p.(s)
        if success then
          ret.push(*w)
        else
          return [FAILED,s]
        end
      end
      return [SUCCESS,s,*ret]
    }
  end

  # M is for many
  # zero or more occurence of p
  def pM(p)
    lambda {
      |s|
      ret = []
      loop do
        success,s0,*w = p.(s)
        if success then
          ret.push(*w)
          s = s0
        elsif s0 != s
          return [FAILED,s0]
        else
          break
        end
      end
      return [SUCCESS,s,*ret]
    }
  end

  # 1 or more
  def pM1(p)
    pD(p,pM(p))
  end

  ##### manyTill
  # zero or more p ended by endFunc
  def pMT(p,endFunc)
    lambda {
      |s|
      ret = []
      loop do
        success,s0,*w = endFunc.(s)
        if success then
          return [SUCCESS,s0,*ret]
        else
          if s0 != s then
            return [FAILE,s0]
          end
          success,s1,*w = p.(s0)
          if success then
            s = s1
            ret.push(*w)
          else
            return [FAILED,s1]
          end
        end
      end
    }
  end

  ##### 1 or more p separated by sep
  def pSepBy1(p,sep)
    pD( p,
        pM( pD(pK(sep), p) )
      )
  end

  def pSepBy(p,sep)
    pOpt( pSepBy1(p,sep) )
  end

  ##### 1 or more p separated by sep
  # return (p,sep,....,p,sep,p)
  def pWithSep1(p,sep)
    pD( p, pM(pD(sep, p)) )
  end

  def pWithSep(p,sep)
    pOpt( pWithSep1(p,sep) )
  end

  ##### zero or more p separated by and ended by sep
  # return (p,...)
  def pEndBy(p,endFunc)
    pM( pD(p, pK(endFunc) ) )
  end

  ##### 1 or more p separated by and ended by sep 
  # return (p,...)
  def pEndBy1(p,endFunc)
    pM1( pD(p, pK(endFunc) ) )
  end

  # 1 or more p separated by sep ,
  # and optionaly ended by sep
  # return (p,...)
  def pSepEndBy1(p,sep)
    pD( p,
        pM( pU(pD(pK(sep), p)) ),
        pOpt(pK(sep)) )
  end

  # zero or more
  def pSepEndBy(p,sep)
    pOpt( pSepEndBy1(p,sep) )
  end

  # the chain combinators
  def pChain(p,op,evalFunc)
    lambda {
      |s|
      values = []
      ops    = []
      success,s,*w = p.(s)
      if success then
        values.push(*w)
        loop do
          success,s,*w = op.(s)
          if success then
            raise "error" if w.length > 1
            success,s,*w1 = p.(s)
            if success then
              ops.push(w[0])
              values.push(*w1)
            else
              return [FAILED,s]
            end
          else
            break
          end
        end
        return [SUCCESS,s,evalFunc.(values,ops)]
      else
        return [FAILED,s]
      end
    }
  end

  def evalChianR(values,ops)
    vs = values.dup
    os = ops.dup
    while os.length > 0 do
      v2 = vs.pop
      v1 = vs.pop
      o  = os.pop  
      v  = o.(v1,v2)
      vs.push v
    end
    return vs[0]
  end

  def pCr1(p,op)
    pChain(p,op,method(:evalChainR))
  end

  def evalChainL(values,ops)
    vs = values.dup
    os = ops.dup
    while os.length > 0 do
      v1 = vs.shift
      v2 = vs.shift
      o  = os.shift
      v  = o.(v1,v2)
      vs.unshift v
    end
    return vs[0]
  end

  def pCl1(p,op)
    pChain(p,op,method(:evalChainL))
  end

  # P is for paren
  def pP(po,p,pc)
    pD( pK(po), p, pK(pc) )
  end

  # pOpt
  def pOpt(p)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if success then
        return [SUCCESS,s0,*w]
      else
        if s0 == s then
          return [SUCCESS,s]
        else
          print "failed at #{s0}"
          return [FAILED,s0]
        end
      end
    }
  end

  # notFollowedBy
  def pNotFolloedBy(p)
    lambda {
      |s|
      success,_ = p.(s)
      if !success then
        return [SUCCESS,s]
      else
        return [FAILED,s]
      end
    }
  end
            
  # lookAhead
  def pLookAhead(p)
    lambda {
      |s|
      success,s0,_ = p.(s)
      if success then
        return [SUCCESS,s]
      else
        if s0 != s then
          print "failed at #{s0}"
          return [FAILED,s0]
        else
          return [FAILED,s]
        end
      end
    }
  end    

  # O is for Or
  # the choice combinator
  def pO(*ps)
    lambda {
      |s|
      for p in ps
        success,s0,*w = p.(s)
        if success then
          return [SUCCESS,s0,*w]
        else
          if s != s0 then
            return [FAILED,s0]
          end
        end
      end
      return [FAILED,s]
    }
  end

  # U is for Undo
  # the try combinator
  def pU(p)
    lambda {
      |s|
      success,s0,*w = p.(s)
      if success then
        return [SUCCESS,s0,*w]
      else
        return [FAILED,s]
      end
    }
  end

  # define pxxxxA for each pxxxx.
  # these parsers can accept a block for action.
  # note pA and pRef are exceptional.
  # because they has their original block arguments.
  [ :token,
    :pOk,
    :pFail,
    :pG ,
    :pDebug,
    :pF,
    :pL ,
    :pK ,
    :pKS,
    :pD ,
    :pM ,
    :pM1,
    :pMT ,
    :pSepBy1,
    :pSepBy,
    :pWithSep1,
    :pWithSep,
    :pEndBy,
    :pEndBy1,
    :pSepEndBy1,
    :pSepEndBy,
    :pChain,
    :pCr1,
    :pCl1,
    :pP,
    :pOpt,
    :pNotFolloedBy,
    :pLookAhead,
    :pO ,
    :pU
  ].each do
    |sym|
    newsym = ( sym.to_s + "A" ).to_sym
    define_method(newsym,
                  lambda {
                    |*ps,&proc|
                    if proc != nil then
                      pAl(send(sym,*ps),proc)
                    else
                      send(sym,*ps)
                    end
                  })
  end

  # aliases exported

  alias a    pA
  alias r    pRef
  
  alias para pPA
  alias f    pFA
  alias k    pKA
  alias l    pLA
  alias m    pMA
  alias m1   pM1A
  alias u    pUA
  alias o    pOA
  alias d    pDA
  alias c    pCl1A
  alias opt  pOptA
  alias eb   pEndByA
  alias sb   pSepByA
  alias seb  pSepEndByA
  alias sb1  pSepBy1A
  alias seb1 pSepEndBy1A
  alias ws   pWithSepA
  alias ws1  pWithSep1A

end
