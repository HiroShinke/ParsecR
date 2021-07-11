# ParsecR
Yet Another Parsec like parser combinator library for Ruby

[![Ruby](https://github.com/HiroShinke/ParsecR/actions/workflows/ruby.yml/badge.svg)](https://github.com/HiroShinke/ParsecR/actions/workflows/ruby.yml)
[![ruby version][shield-ruby]](#)
[![parser combinator][shield-parser]](#)
[![haskell][shield-haskell]](#)
[![license][shield-license]](#)

## Description

## Requirement

## Usage

```ruby

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

  pExpr = createParser
  runParser(pExpr,"2 + (2 + 3)*10")

```

## Examples

## Contribution

## Licence

## Author

[shield-ruby]: https://img.shields.io/badge/tag-ruby-green.svg
[shield-parser]: https://img.shields.io/badge/tag-parser_combinator-green.svg
[shield-haskell]: https://img.shields.io/badge/tag-haskell-green.svg
[shield-license]: https://img.shields.io/badge/license-MIT-blue.svg

