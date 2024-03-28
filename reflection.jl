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

function quot(expr::Union{Symbol, Expr, Number, String})
  return Meta.quot(expr)
end

function unquot(expr::Expr)
  return expr.args[1]
end