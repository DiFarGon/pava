module MetaJulia

function metajulia_repl()
  println("Welcome to MetaJulia REPL")
  
  while true
    print(">> ")
    input = readline()

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
      for arg in expr.args[begin:2:end-2]
        metajulia_eval(arg)
      end
      return metajulia_eval(expr.args[end])
    end
  end
end

end