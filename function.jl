# This file contains the definition of the FuncDef struct and the function_definition function.

struct FuncDef
  args::Array{Symbol, 1}
  body::Expr
  scope::Scope
end

function function_definition(args::Array{Symbol, 1}, body::Expr, scope)
  return FuncDef(args, body, scope)
end