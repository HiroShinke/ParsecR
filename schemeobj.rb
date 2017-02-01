

Atom       = Struct.new(:str)
List       = Struct.new(:ls)
Number     = Struct.new(:value)
Str        = Struct.new(:str)
Bool       = Struct.new(:bool)
Prim       = Struct.new(:proc)
Syntax     = Struct.new(:proc)
Closure    = Struct.new(:expr,:lenv)
Macro      = Struct.new(:closure)

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
  alias car head
  alias cdr tail

  def initialize(h,t)
    @head = h
    @tail = t
  end

  def self.from_a(a,x=Nil::NIL)
    r = a.reverse
    r.inject(x) { |c,e| Cons.new(e,c) }
  end

  def self.list(*a)
    from_a(a)
  end
  
  def eval(env)
    func = head.eval(env)
    func.apply(env,tail)
  end
  
  def to_s
    "(" + to_s0 + ")"
  end

  def to_s0
    v  = ""
    c = self
    while c.instance_of?(Cons)
      e = c.head
      if v == ""
        v = e.to_s
      else
        v = v + " " + e.to_s
      end
      c = c.tail
    end
    if c != Nil::NIL
      v = v + " . " + c.to_s
    end
    v
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

  def ==(o)
    begin
       @head == o.head &&
       @tail == o.tail
    rescue
      false
    end
  end

  def append(exp0)
    if @tail == Nil::NIL
      @tail = exp0
    else
      @tail.append(exp0)
    end
    self
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
    args = args0.map { |e| e.eval(env) }
    apply0(env,args)
  end

  def apply0(env,args)
    params = expr.head
    bodys  = expr.tail
    env = makeBindings(params,args)
    ret = nil
    for b in bodys
      ret = b.eval(env)
    end
    ret
  end
  
  def makeBindings(params,args)
    env = Env.new(lenv)
    while params.instance_of?(Cons)
      p = params.head
      env.define(p.str,args.head)
      params = params.tail
      args   = args.tail
    end
    if params != Nil::NIL
      env.define(params.str,args)
    end
  env
  end

  def to_s
    "<closure 0x" + object_id.inspect + ">"
  end
  
end

class Macro

  def eval(env)
    self
  end

  def apply(env,args)
    expr = closure.apply0(env,args)
    expr.eval(env)
  end

  def to_s
    "<macro 0x" + object_id.inspect + ">"
  end
  
end



