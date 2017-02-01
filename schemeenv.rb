


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
      raise "variable #{k} not defined!!"
    end
  end

  def define(k,v)
    if dict.key?(k)
      raise "variable #{k} already defined!!"
    else
      dict[k] = v
    end
  end

end
