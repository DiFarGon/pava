# This file is the entry point for the MetaJulia REPL.
# It includes the necessary files and defines the main function.

module MetaJulia

include("eval.jl")
include("scope.jl")

function metajulia_repl()
  scope = init_scope()
  while (input = get_input()) != ""
    parsed = Meta.parse(input)
    output = metajulia_eval(parsed, scope)
    if isa(output, FuncDef)
      println("<function")
    elseif isa(output, FExpr)
      println("<fexpr>")
    else
      println(output)
    end
  end
end

function get_input()
  print(">> ")
  return read_expr()
end

function read_expr()
  line = readline()
  parsed = Meta.parse(line)
  while isa(parsed, Expr) && parsed.head == :incomplete
    line *= "\n" * readline()
    parsed = Meta.parse(line)
  end
  return line
end

end