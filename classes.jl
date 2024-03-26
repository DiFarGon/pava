module MetaJulia

scope = [Dict()]
cur_scope = 1

function metajulia_repl()
  println("Welcome to MetaJulia REPL")
  lines = String[]

  while true
    print(">> ")
    input = read_multiline_input()#readline()

    if input == "exit"
      break
    end

    parsed = Meta.parse(input)

    result = MetaJulia.metajulia_eval(parsed)
    println(result)
  end
end

function metajulia_eval(expr)
  if typeof(expr) == Int64
    return expr
  end
  if typeof(expr) == Char
    return expr
  end
  if typeof(expr) == String
    return expr
  end
  if typeof(expr) == Symbol
    for i in length(MetaJulia.scope):-1:1
      if haskey(MetaJulia.scope[i], expr)
        d = MetaJulia.scope[i]
        return d[expr]
      end
    end
    return expr
  end
  if typeof(expr) == Expr
    if expr.head == :call
      if expr.args[1] == :+
        return metajulia_eval(expr.args[2]) + metajulia_eval(expr.args[3])
      end
      if expr.args[1] == :-
        return metajulia_eval(expr.args[2]) - metajulia_eval(expr.args[3])
      end
      if expr.args[1] == :*
        return metajulia_eval(expr.args[2]) * metajulia_eval(expr.args[3])
      end
      if expr.args[1] == :/
        return metajulia_eval(expr.args[2]) / metajulia_eval(expr.args[3])
      end
      if expr.args[1] == :<
        return metajulia_eval(expr.args[2]) < metajulia_eval(expr.args[3])
      end
      if expr.args[1] == :>
        return metajulia_eval(expr.args[2]) > metajulia_eval(expr.args[3])
      end
    end
    if expr.head == :&&
      return metajulia_eval(expr.args[1]) && metajulia_eval(expr.args[2])
    end
    if expr.head == :||
      return metajulia_eval(expr.args[1]) || metajulia_eval(expr.args[2])
    end
    if expr.head == :if
      if metajulia_eval(expr.args[1])
        return metajulia_eval(expr.args[2])
      end
      return metajulia_eval(expr.args[3])
    end
    if expr.head == :block
      if expr.args == []
        return
      end
      for arg in expr.args[begin:end-1]
        if typeof(arg) != LineNumberNode
          metajulia_eval(arg)
        end
      end
      return metajulia_eval(expr.args[end])
    end
    if expr.head == :(=)
      value = metajulia_eval(expr.args[2])
      MetaJulia.scope[MetaJulia.cur_scope][expr.args[1]] = value
      return value
    end
    if expr.head == :let
      MetaJulia.cur_scope += 1
      push!(MetaJulia.scope, Dict())
      for arg in expr.args[1:end-1]
        if typeof(arg) != LineNumberNode
          metajulia_eval(arg)
        end
      end
      last = metajulia_eval(expr.args[end])
      pop!(MetaJulia.scope)
      MetaJulia.cur_scope -= 1
      return last
    end
    if expr.head == :global
      prev_scope = MetaJulia.cur_scope
      MetaJulia.cur_scope = 1
      for arg in expr.args[1:end-1]
        if typeof(arg) != LineNumberNode
          metajulia_eval(arg)
        end
      end
      last = metajulia_eval(expr.args[end])
      MetaJulia.cur_scope = prev_scope
      return last
    end
  end
end

function read_multiline_input()

  lines = String[]

  while true
      input = readline()      
      if input == ""
          break
      end
      push!(lines, input)
  end
  
  return join(lines, "\n")

end


end