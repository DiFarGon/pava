# This file contains the implementation of the scope data structure and its operations.

struct Scope
  parent::Union{Nothing, Scope}
  bindings::Dict{Symbol, Any}
end

function init_scope()
  scope = Scope(nothing, Dict())
  eval_def = function_definition([:x], Expr(:x), scope)
  bind!(scope, :eval, eval_def)
  return scope
end

function bind!(scope::Scope, sym::Symbol, val)
  scope.bindings[sym] = val
end

function lookup(scope::Scope, sym::Symbol)
  if sym in keys(scope.bindings)
    return scope.bindings[sym]
  elseif !isnothing(scope.parent)
    return lookup(scope.parent, sym)
  else
    error("Symbol $sym not found")
  end
end

function push_scope(scope::Scope)
  return Scope(scope, Dict())
end

function global_scope(scope::Scope)
  if isnothing(scope.parent)
    return scope
  else
    return global_scope(scope.parent)
  end
end