# This file contains the definition of the Macro struct and the macro_definition function.

struct Macro 
  args::Array{Any, 1}
  body::Union{Symbol, Expr}
  scope::Scope
end

function macro_definition(args::Array{Any, 1}, body::Union{Symbol, Expr}, scope::Scope)
  return Macro(args, body, scope)
end