

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
