# Description: This file contains the evaluation functions for the metajulia package.

include("scope.jl")
include("function.jl")
include("fexpr.jl")

PrimitiveType = Union{Number, Bool, AbstractArray, AbstractString}

# General expression evaluation
function metajulia_eval(expr::Expr, scope::Scope)
  metajulia_eval(Val(expr.head), expr, scope)
end

# LineNumberNode evaluation
function metajulia_eval(::LineNumberNode, scope::Scope)
  return nothing
end

function metajulia_eval(expr::PrimitiveType, scope::Scope)
  return expr
end

function metajulia_eval(sym::Symbol, scope::Scope)
  return lookup(scope, sym)
end

# Expression evaluation for a block
function metajulia_eval(::Val{:block}, expr::Expr, scope::Scope)
  for i = 1:(length(expr.args) - 1)
    metajulia_eval(expr.args[i], scope)
  end
  return length(expr.args) > 0 ? metajulia_eval(expr.args[end], scope) : nothing
end

# Expression evaluation for a call
function metajulia_eval(::Val{:call}, expr::Expr, scope::Scope)
  if isa(expr.args[1], Expr)
    func = metajulia_eval(Val(expr.args[1].head), expr.args[1], scope)
    new_scope = push_scope(scope)
    for (arg, val) in zip(func.args, expr.args[2:end])
      bind!(new_scope, arg, metajulia_eval(val, scope))
    end
    result = metajulia_eval(func.body, new_scope)
    return result
  end
  return metajulia_eval(Val(expr.args[1]), expr, scope)
end

function metajulia_eval(::Val{:+}, expr::Expr, scope::Scope)
  result = 0
  for arg in expr.args[2:end]
    result += metajulia_eval(arg, scope)
  end
  return result
end

function metajulia_eval(::Val{:-}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) - metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:*}, expr::Expr, scope::Scope)
  result = 1
  for arg in expr.args[2:end]
    result *= metajulia_eval(arg, scope)
  end
  return result
end

function metajulia_eval(::Val{:/}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) / metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:^}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) ^ metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:(==)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) == metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:(!=)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) != metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:<}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) < metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:(<=)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) <= metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:>}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) > metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:>=}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) >= metajulia_eval(expr.args[3], scope)
end

function metajulia_eval(::Val{:&&}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope) && metajulia_eval(expr.args[2], scope)
end

function metajulia_eval(::Val{:||}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope) || metajulia_eval(expr.args[2], scope)
end

function metajulia_eval(::Val{:!}, expr::Expr, scope::Scope)
  return !metajulia_eval(expr.args[2], scope)
end

function metajulia_eval(::Val{:if}, expr::Expr, scope::Scope)
  if metajulia_eval(expr.args[1], scope)
    return metajulia_eval(expr.args[2], scope)
  end
  return length(expr.args) > 2 ? metajulia_eval(expr.args[3], scope) : nothing
end

function metajulia_eval(::Val{:elseif}, expr::Expr, scope::Scope)
  if metajulia_eval(expr.args[1], scope)
    return metajulia_eval(expr.args[2], scope)
  end
  return length(expr.args) > 2 ? metajulia_eval(expr.args[3], scope) : nothing
end

function metajulia_eval(::Val{:let}, expr::Expr, scope::Scope)
  new_scope = push_scope(scope)
  metajulia_eval(expr.args[1], new_scope)
  output = metajulia_eval(expr.args[2], new_scope)
  return output
end

function metajulia_eval(::Val{:(=)}, expr::Expr, scope::Scope)
  if isa(expr.args[1], Expr) && length(expr.args[1].args) > 1
    sym = expr.args[1].args[1]
    args::Vector{Symbol} = []
    for arg in expr.args[1].args[2:end]
      push!(args, arg)
    end
    body = expr.args[2]
    val = function_definition(args, body, scope)
    bind!(scope, sym, val)
    return val
  else
    sym = expr.args[1]
    val = metajulia_eval(expr.args[2], scope)
    bind!(scope, sym, val)
    return val
  end
end

function metajulia_eval(::Val{:global}, expr::Expr, scope::Scope)
  args = expr.args[1].args
  if isa(args[1], Symbol)
    val = metajulia_eval(args[2], scope)
    bind!(global_scope(scope), args[1], val)
    return val
  else
    name = args[1].args[1]
    funcargs::Vector{Symbol} = args[1].args[2:end]
    body = args[2]
    val = function_definition(funcargs, body, scope)
    bind!(global_scope(scope), name, val)
    return val
  end
  return metajulia_eval(expr.args[1], gscope)
end

function metajulia_eval(::Val{sym}, expr::Expr, scope::Scope) where sym
  var = lookup(scope, sym)
  if isa(var, FuncDef)
    for (arg, val) in zip(var.args, expr.args[2:end])
      bind!(var.scope, arg, metajulia_eval(val, scope))
    end
  end
  result = metajulia_eval(var.body, var.scope)
  return result
end

function metajulia_eval(::Val{:->}, expr::Expr, scope::Scope)
  args::Vector{Symbol} = []
  if isa(expr.args[1], Expr) && expr.args[1].head == :tuple
    for arg in expr.args[1].args
      push!(args, convert(Symbol, arg))
    end
  else
    for arg in expr.args[1:end-1]
      push!(args, arg)
    end
  end
  body = expr.args[end]
  return function_definition(args, body, scope)
end

function metajulia_eval(expr::QuoteNode, scope::Scope)
  return expr
end

function metajulia_eval(::Val{:quote}, expr::Expr, scope::Scope)
  intrplt = interpolate!(expr, scope)
  return intrplt
end

# Interpolation of expressions
function interpolate!(expr::Expr, scope::Scope)
  intrplt = expr
  if expr.head == :$
    eval = metajulia_eval(expr, scope)
    intrplt = Meta.parse(string(eval))
  else
    for i in 1:length(intrplt.args)
      if isa(intrplt.args[i], Expr)
        intrplt.args[i] = interpolate!(intrplt.args[i], scope)
      end
    end
  end
  return intrplt
end

function metajulia_eval(::Val{:$}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope)
end