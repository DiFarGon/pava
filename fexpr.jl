# This file contains the definition of the FExpr type and the fexpr_definition function.

struct FExpr
  args::Array{Union{Symbol, Expr}}
  body::Union{Symbol, Expr}
  scope::Scope
end

function fexpr_definition(args::Vector{Any}, body::Union{Symbol, Expr}, scope::Scope)
  return FExpr(args, body, scope)
end