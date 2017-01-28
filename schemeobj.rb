

Atom       = Struct.new(:str)
List       = Struct.new(:ls)
Number     = Struct.new(:value)
Str        = Struct.new(:str)
Bool       = Struct.new(:bool)
Prim       = Struct.new(:proc)
Syntax     = Struct.new(:proc)
Closure    = Struct.new(:expr,:lenv)
Macro      = Struct.new(:expr)

def prim(&proc)
  Prim.new(proc)
end

def syntax(&proc)
  Syntax.new(proc)
end


class List
  include Enumerable

  def eval(env)
    func0,*args0 = ls
    func = func0.eval(env)
    func.apply(env,*args0)
  end
  
  def to_s
    "(" + ls.map { |e| e.to_s }.join(" ") + ")"
  end

  def [](i,len)
    ls[i,len]
  end

  def length
    ls.length
  end
  
  def each(*params,&proc)
    ls.each(*params,&proc)
  end

  def car
    car,*cdr = ls
    car
  end

  def cdr
    car,*cdr = ls
    List.new(cdr)
  end
  
end

class Cons
  include Enumerable

  attr_accessor :head, :tail

  def initialize(h,t)
    @head = h
    @tail = t
  end

  def self.from_a(a)
    r = a.reverse
    r.inject(Nil::NIL) { |c,e| Cons.new(e,c) }
  end

  def eval(env)
    func = head.eval(env)
    func.apply(env,tail)
  end
  
  def to_s
    "(" + to_s0 + ")"
  end

  def to_s0
    inject("") {
      |v,e|
      if v == ""
        e.to_s
      else
        v + " " + e.to_s
      end
    }
  end

  def each(*params,&proc)
    enum = Enumerator.new {
      |y|
      c = self
      while c.instance_of?(Cons)
        y << c.head
        c = c.tail
      end
    } 
    if block_given?
      enum.each(&proc)
    else
      enum
    end
  end

  def map(&proc)
    Cons.new(proc.(head),tail.map(&proc))
  end

  def car
    head
  end

  def cdr
    tail
  end

  def ==(o)
    begin
       @head == o.head &&
       @tail == o.tail
    rescue
      false
    end
  end

end

class Nil
  include Enumerable

  NIL = Nil.new

  def eval(env)
    self
  end
  
  def to_s
    "()"
  end
  
  def each(*params,&proc)
    enum = Enumerator.new { }
    if block_given?
      enum.each(&proc)
    else
      enum
    end
  end

  def map(&proc)
    NIL
  end

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
  def apply(env,args0)
    args = args0.map { |e| e.eval(env) } 
    proc.(env,args)
  end
end

class Syntax
  def eval(env)
    self
  end
  def apply(env,args)
    proc.(env,args)
  end
end

class Closure
  def eval(env)
    self
  end
  def apply(env,args0)
    params,body = expr
    args = args0.map { |e| e.eval(env) } 
    env = makeBindings(params,args)
  end
  
  def makeBindings(params,args)
    env = Env.new(lenv)
    i = 0
    while i < params.length
      p = params[i]
      a = args[i]
      env.define(p.str,a)
    end
    env
  end

end
