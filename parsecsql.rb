
require 'parsecr.rb'

class SqlParser

  include ParsecR

  def tr(reg,&proc) ; tokenA(pR(reg),&proc) ; end
  def ts(str,&proc) ; tokenA(pS(str),&proc) ; end
  
  def createParser 
    
    pDot  = ts(".")
    pComma= ts(",")
    pSemi = ts(";")
    pAsta = ts("*")
    pCnOp = ts("||")
    oBra = ts("(")
    cBra = ts(")")

    pExpr = nil
    pAddop = o( tr(/\+/) { |w| lambda { |v1,v2| [v1,w,v2] } },
                tr(/-/)  { |w| lambda { |v1,v2| [v1,w,v2] } } )
    pMulop = o( tr(/\*/) { |w| lambda { |v1,v2| [v1,w,v2] } },
                tr(/\//) { |w| lambda { |v1,v2| [v1,w,v2] } },
                a(pCnOp) { |w| lambda { |v1,v2| [v1,w,v2] } } )
    pDigit =  tr(/\d+/)

    keyWords = %w( AND OR WHERE SELECT UPDATE INSERT DELETE FROM ON AS
                   GROUP BY JOIN DISTINCT INTO SET )

    kAND,kOR,kWHERE,kSELECT,kUPDATE,kINSERT,kDELETE,kFROM,kON,kAS,
    kGROUP,kBY,kJOIN,kDISTINCT,kINTO,kSET = nil

    keywordHash = {}
    binds = binding
    
    keyWords.each do |key|
      keywordHash[key] = 1
      str = "k" + key
      binds.local_variable_set(str.to_sym,ts(key))
    end
    
    pDoubleQuoted = tr(/"[^"]*"/)
    pSingleQuoted = tr(/'[^']*'/)
    logicalOp    = o( ts("<>"), tr(/[=<>]/) )

    pId0  = tr(/[a-zA-Z][a-zA-Z_0-9]*/)
    pId   = o( f(pId0,
                 lambda {
                   |t|
                   if keywordHash.has_key?(t.word) then
                     return false
                   else
                     return true
                   end
                 }),
               pDoubleQuoted )

    sqlExpression   = nil
    selectStatement = nil

    argList         = ws(r{sqlExpression}, pComma )
    
    qualifiedId     = l("qualifiedId",  ws1(pId, pDot ))
    qualifiedIdAsta = l("qualifiedId*", d( m(d(pId, pDot)),pAsta))
                                           
    sqlFactor       = o( l("funcCall", 
                           u( d( l("functionName",qualifiedId),
                                 oBra,argList,cBra))),
                         l("columnName",u(qualifiedIdAsta)),
                         l("columnName",u(qualifiedId)),
		         l("literal",pDigit),
		         u(para(oBra,r{sqlExpression},cBra)),
                         para(oBra,r{selectStatement},cBra)
                       )
    sqlTerm           =  l( "sqlTerm", c(sqlFactor, pMulop ))
    sqlExpression     =  l( "sqlExpression", c(sqlTerm, pAddop ))
    

    logicalFactor      = o( u(d( sqlExpression, logicalOp , sqlExpression ) ),
                            u(r{sqlExpression}),
			    para( oBra, r{logicalExpression}, cBra) 
                          )
    logicalAnd         = l("logicalAnd", ws1( logicalFactor, kAND));
    logicalExpression  = l("logicalOr",  ws1( logicalAnd,    kOR));

    itemAlias       = l("itemAlias", pId)

    pItem           = d(  logicalExpression,
                          opt( o( d( k(kAS), itemAlias),
		                  itemAlias 
                                ) 
		             )
                       )

    columnList      = l("columnList", sb( pItem, pComma ))


    whereClause     = l( "whereClause",
		         d( kWHERE, logicalExpression ) )
    groupByClause   = l( "groupByClause",
		         d( kGROUP, kBY, columnList ) );
    updateStatement = kUPDATE;
    
    tableAlias      = l("tableAlias",pId);
    tableLike       = o( l("tableName", qualifiedId),
                         para(oBra,l("subquery",r{selectStatement}),cBra)
                       )

    table           = d( tableLike, 
                            opt( o( 
                                   d( k(kAS), tableAlias), 
                                   tableAlias 
                                 )
                              )
                          )
		      
    tableList       = l("tableList", ws1(table, pComma))


    selectStatement = d( kSELECT,
                      opt( kDISTINCT ),
                         columnList,
                         kFROM,
                         tableList,
                      opt( whereClause ),
		      opt( groupByClause ) )

    selectStatement = l( "selectStatement", selectStatement )
    

    sqlStatement    = o( r{selectStatement},
                         r{updateStatement} )

    parserUnit      = d( sqlStatement, pSemi )

    parserUnit
  end

  def mainLoop 
    parserUnit = createParser
    buff = ""
    begin
      loop do
        str=readline
        buff += str
        if (pos = (buff =~ /;/)) != nil then
          buff.upcase!
          success,s,*w = runParser(parserUnit,buff)
          p success
          p s
          print_result(0,*w)
          buff = ""
        end
      end
    rescue EOFError
    rescue Exception => e
      p e
    end
  end

  def print_result(l,*ws)
    ws.each {
      |w|
      if w.class == Token then
        l.times { print " " }
        print w.inspect
        puts "\n"
      elsif w.class == String then
        l.times { print " " }
        print w
        puts "\n"
      elsif w.class == Array then
        print_result(l+1,*w)
      else
      end
    }
  end
end

c = SqlParser.new
c.mainLoop

