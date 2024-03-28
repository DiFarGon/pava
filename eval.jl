# Description: This file contains the evaluation functions for the metajulia package.

include("scope.jl")
include("function.jl")
include("fexpr.jl")
include("reflection.jl")
include("macro.jl")

PrimitiveType = Union{Number, Bool, AbstractArray, AbstractString}

# General expression evaluation
function metajulia_eval(expr::Expr, scope::Scope)
  metajulia_eval(Val(expr.head), expr, scope)
end

# LineNumberNode evaluation
function metajulia_eval(::LineNumberNode, scope::Scope)
  return nothing
end

# Evaluation for primitive types like numbers, strings and booleans
function metajulia_eval(expr::PrimitiveType, scope::Scope)
  return expr
end

# Evaluation for symbols
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

# Expression evaluation for +
function metajulia_eval(::Val{:+}, expr::Expr, scope::Scope)
  result = 0
  for arg in expr.args[2:end]
    result += metajulia_eval(arg, scope)
  end
  return result
end

# Expression evaluation for -
function metajulia_eval(::Val{:-}, expr::Expr, scope::Scope)
  if length(expr.args) == 2
    return -metajulia_eval(expr.args[2], scope)
  end
  return metajulia_eval(expr.args[2], scope) - metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for *
function metajulia_eval(::Val{:*}, expr::Expr, scope::Scope)
  result = 1
  for arg in expr.args[2:end]
    result *= metajulia_eval(arg, scope)
  end
  return result
end

# Expression evaluation for /
function metajulia_eval(::Val{:/}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) / metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for ^
function metajulia_eval(::Val{:^}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) ^ metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for %
function metajulia_eval(::Val{:(==)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) == metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for !=
function metajulia_eval(::Val{:(!=)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) != metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for <
function metajulia_eval(::Val{:<}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) < metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for <=
function metajulia_eval(::Val{:(<=)}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) <= metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for >
function metajulia_eval(::Val{:>}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) > metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for >=
function metajulia_eval(::Val{:>=}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[2], scope) >= metajulia_eval(expr.args[3], scope)
end

# Expression evaluation for &&
function metajulia_eval(::Val{:&&}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope) && metajulia_eval(expr.args[2], scope)
end

# Expression evaluation for ||
function metajulia_eval(::Val{:||}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope) || metajulia_eval(expr.args[2], scope)
end

# Expression evaluation for !
function metajulia_eval(::Val{:!}, expr::Expr, scope::Scope)
  return !metajulia_eval(expr.args[2], scope)
end

# Expression evaluation for if
function metajulia_eval(::Val{:if}, expr::Expr, scope::Scope)
  if metajulia_eval(expr.args[1], scope)
    return metajulia_eval(expr.args[2], scope)
  end
  return length(expr.args) > 2 ? metajulia_eval(expr.args[3], scope) : nothing
end

# Expression evaluation for elseif
function metajulia_eval(::Val{:elseif}, expr::Expr, scope::Scope)
  if metajulia_eval(expr.args[1], scope)
    return metajulia_eval(expr.args[2], scope)
  end
  return length(expr.args) > 2 ? metajulia_eval(expr.args[3], scope) : nothing
end

# Expression evaluation for let
function metajulia_eval(::Val{:let}, expr::Expr, scope::Scope)
  new_scope = push_scope(scope)
  metajulia_eval(expr.args[1], new_scope)
  output = metajulia_eval(expr.args[2], new_scope)
  return output
end

# Expression evaluation for assignments
function metajulia_eval(::Val{:(=)}, expr::Expr, scope::Scope)
  if isa(expr.args[1], Expr)
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

# Expression evaluation for global assignments
function metajulia_eval(::Val{:global}, expr::Expr, scope::Scope)
  args = expr.args[1].args
  if isa(args[1], Symbol)
    val = metajulia_eval(args[2], scope)
    bind!(global_scope(scope), args[1], val)
    return val
  else
    name = args[1].args[1]
    body = args[2]
    val = nothing
    if expr.args[1].head == :(=)
      funcargs::Vector{Symbol} = args[1].args[2:end]
      val = function_definition(funcargs, body, scope)
    else
      fexprargs::Vector{Any} = args[1].args[2:end]
      val = fexpr_definition(fexprargs, body, scope)
    end
    bind!(global_scope(scope), name, val)
    return val
  end
  return metajulia_eval(expr.args[1], gscope)
end

# Expression evaluation for function, fexpr and macro calls
function metajulia_eval(::Val{sym}, expr::Expr, scope::Scope) where sym
  var = lookup(scope, sym)
  if isa(var, PrimitiveType)
    return var
  end
  if isa(var, FuncDef)
    new_scope = combine_scopes(var.scope, scope)
    for (arg, val) in zip(var.args, expr.args[2:end])
      bind!(new_scope, arg, metajulia_eval(val, scope))
    end
    return metajulia_eval(var.body, new_scope)
  elseif isa(var, FExpr)
    new_scope = combine_scopes(var.scope, scope)
    for (arg, val) in zip(var.args, expr.args[2:end])
      bind!(new_scope, arg, quot(val))
    end
    return metajulia_eval(var.body, new_scope)
  elseif isa(var, Macro)
    new_scope = combine_scopes(var.scope, scope)
    for (arg, val) in zip(var.args, expr.args[2:end])
      bind!(new_scope, arg, val)
    end
    body = metajulia_eval(var.body, new_scope)
    return metajulia_eval(unquot(body), scope)
  else
    error("Not a symbol, function, fexpr or macro")
  end
end

# Expression evaluation for anonymous function definitions
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

# Expression evaluation for quote nodes
function metajulia_eval(expr::QuoteNode, scope::Scope)
  return expr
end

# Expression evaluation for expression with head == :quote. Includes interpolation
function metajulia_eval(::Val{:quote}, expr::Expr, scope::Scope)
  intrplt = interpolate!(expr, scope)
  return intrplt
end

# Expression evaluation for interpolation
function metajulia_eval(::Val{:$}, expr::Expr, scope::Scope)
  return metajulia_eval(expr.args[1], scope)
end

# Expression evaluation for fexpr definition
function metajulia_eval(::Val{:(:=)}, expr::Expr, scope::Scope)
  sym = expr.args[1].args[1]
  args = expr.args[1].args[2:end]
  body = expr.args[2]
  new_scope = push_scope(scope)
  val = fexpr_definition(args, body, new_scope)
  bind!(scope, sym, val) 
  return val
end

# FIXME: eval should be stored as a function, not a cheesy method to parse a
# specific symbol
function metajulia_eval(::Val{:eval}, expr::Expr, scope::Scope)
  arg = expr.args[2]
  if isa(arg, Symbol)
    arg = lookup(scope, arg)
  end
  while isa(arg, Expr)
    if arg.head == :quote
      arg = unquot(arg)
    end
    arg = metajulia_eval(arg, scope)
  end
  return arg
end

# FIXME: same as eval above
function metajulia_eval(::Val{:println}, expr::Expr, scope::Scope)
  for arg in expr.args[2:end]
    toprint = metajulia_eval(arg, scope)
    if isa(toprint, Expr) && toprint.head == :quote
      toprint = unquot(toprint)
    end
    print(toprint, " ")
  end
  print("\n")
end

# Expression evaluation for macro definition
function metajulia_eval(::Val{:$=}, expr::Expr, scope::Scope)
  println(expr)
  sym = expr.args[1].args[1]
  args = expr.args[1].args[2:end]
  body = expr.args[2]
  new_scope = push_scope(scope)
  val = macro_definition(args, body, new_scope)
  bind!(scope, sym, val) 
  return val
end