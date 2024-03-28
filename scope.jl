# This file contains the implementation of the scope data structure and its operations.

struct Scope
  parent::Union{Nothing, Scope}
  bindings::Dict{Symbol, Any}
end

# Initialize a new scope
function init_scope()
  return Scope(nothing, Dict())
end

# Bind a value to a symbol in the scope, replaces it if already defined
function bind!(scope::Scope, sym::Symbol, val)
  scope.bindings[sym] = val
end


# Lookup a symbol in the scope
function lookup(scope::Scope, sym::Symbol)
  if sym in keys(scope.bindings)
    return scope.bindings[sym]
  elseif !isnothing(scope.parent)
    return lookup(scope.parent, sym)
  end
  return nothing
end

# Push a new scope onto the stack
function push_scope(scope::Scope)
  return Scope(scope, Dict())
end

# Combine two scopes
function combine_scopes(scope::Scope, parent::Scope)
  return Scope(parent, scope.bindings)
end

# Get the global scope
function global_scope(scope::Scope)
  if isnothing(scope.parent)
    return scope
  else
    return global_scope(scope.parent)
  end
end