export obj, grad, grad!, objgrad, objgrad!, objcons, objcons!
export cons, cons!, jth_con, jth_congrad, jth_congrad!, jth_sparse_congrad
export jac_structure!, jac_structure, jac_coord!, jac_coord
export jac, jprod, jprod!, jtprod, jtprod!, jac_op, jac_op!
export jth_hess_coord, jth_hess_coord!, jth_hess
export jth_hprod, jth_hprod!, ghjvprod, ghjvprod!
export hess_structure!, hess_structure, hess_coord!, hess_coord
export hess, hprod, hprod!, hess_op, hess_op!
export varscale, lagscale, conscale

"""
    f = obj(nlp, x)

Evaluate ``f(x)``, the objective function of `nlp` at `x`.
"""
function obj end

"""
    g = grad(nlp, x)

Evaluate ``∇f(x)``, the gradient of the objective function at `x`.
"""
function grad(nlp::AbstractNLPModel, x::AbstractVector)
  @lencheck nlp.meta.nvar x
  g = similar(x)
  return grad!(nlp, x, g)
end

"""
    g = grad!(nlp, x, g)

Evaluate ``∇f(x)``, the gradient of the objective function at `x` in place.
"""
function grad! end

"""
    c = cons(nlp, x)

Evaluate ``c(x)``, the constraints at `x`.
"""
function cons(nlp::AbstractNLPModel, x::AbstractVector)
  @lencheck nlp.meta.nvar x
  c = similar(x, nlp.meta.ncon)
  return cons!(nlp, x, c)
end

"""
    c = cons!(nlp, x, c)

Evaluate ``c(x)``, the constraints at `x` in place.
"""
function cons! end

function jth_con end

function jth_congrad(nlp::AbstractNLPModel, x::AbstractVector, j::Integer)
  @lencheck nlp.meta.nvar x
  g = Vector{eltype(x)}(undef, nlp.meta.nvar)
  return jth_congrad!(nlp, x, j, g)
end

function jth_congrad! end

function jth_sparse_congrad end

"""
    f, c = objcons(nlp, x)

Evaluate ``f(x)`` and ``c(x)`` at `x`.
"""
function objcons(nlp, x)
  @lencheck nlp.meta.nvar x
  f = obj(nlp, x)
  c = nlp.meta.ncon > 0 ? cons(nlp, x) : eltype(x)[]
  return f, c
end

"""
    f = objcons!(nlp, x, c)

Evaluate ``f(x)`` and ``c(x)`` at `x`. `c` is overwritten with the value of ``c(x)``.
"""
function objcons!(nlp, x, c)
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.ncon c
  f = obj(nlp, x)
  nlp.meta.ncon > 0 && cons!(nlp, x, c)
  return f, c
end

"""
    f, g = objgrad(nlp, x)

Evaluate ``f(x)`` and ``∇f(x)`` at `x`.
"""
function objgrad(nlp, x)
  @lencheck nlp.meta.nvar x
  g = similar(x)
  return objgrad!(nlp, x, g)
end

"""
    f, g = objgrad!(nlp, x, g)

Evaluate ``f(x)`` and ``∇f(x)`` at `x`. `g` is overwritten with the
value of ``∇f(x)``.
"""
function objgrad!(nlp, x, g)
  @lencheck nlp.meta.nvar x g
  f = obj(nlp, x)
  grad!(nlp, x, g)
  return f, g
end

"""
    (rows,cols) = jac_structure(nlp)

Return the structure of the constraint's Jacobian in sparse coordinate format.
"""
function jac_structure(nlp :: AbstractNLPModel)
  rows = Vector{Int}(undef, nlp.meta.nnzj)
  cols = Vector{Int}(undef, nlp.meta.nnzj)
  jac_structure!(nlp, rows, cols)
end

"""
    jac_structure!(nlp, rows, cols)

Return the structure of the constraint's Jacobian in sparse coordinate format in place.
"""
function jac_structure! end

"""
    vals = jac_coord!(nlp, x, vals)

Evaluate ``J(x)``, the constraint's Jacobian at `x` in sparse coordinate format,
rewriting `vals`.
"""
function jac_coord! end

"""
    vals = jac_coord(nlp, x)

Evaluate ``J(x)``, the constraint's Jacobian at `x` in sparse coordinate format.
"""
function jac_coord(nlp :: AbstractNLPModel, x :: AbstractVector)
  @lencheck nlp.meta.nvar x
  vals = Vector{eltype(x)}(undef, nlp.meta.nnzj)
  return jac_coord!(nlp, x, vals)
end

"""
    Jx = jac(nlp, x)

Evaluate ``J(x)``, the constraint's Jacobian at `x` as a sparse matrix.
"""
function jac(nlp::AbstractNLPModel, x::AbstractVector)
  @lencheck nlp.meta.nvar x
  rows, cols = jac_structure(nlp)
  vals = jac_coord(nlp, x)
  sparse(rows, cols, vals, nlp.meta.ncon, nlp.meta.nvar)
end

"""
    Jv = jprod(nlp, x, v)

Evaluate ``J(x)v``, the Jacobian-vector product at `x`.
"""
function jprod(nlp::AbstractNLPModel, x::AbstractVector, v::AbstractVector)
  @lencheck nlp.meta.nvar x v
  Jv = similar(v, nlp.meta.ncon)
  return jprod!(nlp, x, v, Jv)
end

"""
    Jv = jprod!(nlp, x, v, Jv)

Evaluate ``J(x)v``, the Jacobian-vector product at `x` in place.
"""
function jprod! end

"""
    Jv = jprod!(nlp, rows, cols, vals, v, Jv)

Evaluate ``J(x)v``, the Jacobian-vector product, where the Jacobian is given by
`(rows, cols, vals)` in triplet format.
"""
function jprod!(nlp::AbstractNLPModel, rows::AbstractVector{<: Integer}, cols::AbstractVector{<: Integer}, vals::AbstractVector, v::AbstractVector, Jv::AbstractVector)
  @lencheck nlp.meta.nnzj rows cols vals
  @lencheck nlp.meta.nvar v
  @lencheck nlp.meta.ncon Jv
  increment!(nlp, :neval_jprod)
  coo_prod!(rows, cols, vals, v, Jv)
end

"""
    Jv = jprod!(nlp, x, rows, cols, v, Jv)

Evaluate ``J(x)v``, the Jacobian-vector product at `x` in place.
`(rows, cols)` should be the Jacobian structure in triplet format.
"""
jprod!(nlp::AbstractNLPModel, x::AbstractVector, ::AbstractVector{<: Integer}, ::AbstractVector{<: Integer}, v::AbstractVector, Jv::AbstractVector) = jprod!(nlp, x, v, Jv)

"""
    Jtv = jtprod(nlp, x, v, Jtv)

Evaluate ``J(x)^Tv``, the transposed-Jacobian-vector product at `x`.
"""
function jtprod(nlp::AbstractNLPModel, x::AbstractVector, v::AbstractVector)
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.ncon v
  Jtv = similar(x)
  return jtprod!(nlp, x, v, Jtv)
end

"""
    Jtv = jtprod!(nlp, x, v, Jtv)

Evaluate ``J(x)^Tv``, the transposed-Jacobian-vector product at `x` in place.
"""
function jtprod! end

"""
    Jtv = jtprod!(nlp, rows, cols, vals, v, Jtv)

Evaluate ``J(x)^Tv``, the transposed-Jacobian-vector product, where the
Jacobian is given by `(rows, cols, vals)` in triplet format.
"""
function jtprod!(nlp::AbstractNLPModel, rows::AbstractVector{<: Integer}, cols::AbstractVector{<: Integer}, vals::AbstractVector, v::AbstractVector, Jtv::AbstractVector)
  @lencheck nlp.meta.nnzj rows cols vals
  @lencheck nlp.meta.ncon v
  @lencheck nlp.meta.nvar Jtv
  increment!(nlp, :neval_jtprod)
  coo_prod!(cols, rows, vals, v, Jtv)
end

"""
    Jtv = jtprod!(nlp, x, rows, cols, v, Jtv)

Evaluate ``J(x)^Tv``, the transposed-Jacobian-vector product at `x` in place.
`(rows, cols)` should be the Jacobian structure in triplet format.
"""
jtprod!(nlp::AbstractNLPModel, x::AbstractVector, ::AbstractVector{<: Integer}, ::AbstractVector{<: Integer}, v::AbstractVector, Jtv::AbstractVector) = jtprod!(nlp, x, v, Jtv)

"""
    J = jac_op(nlp, x)

Return the Jacobian at `x` as a linear operator.
The resulting object may be used as if it were a matrix, e.g., `J * v` or
`J' * v`.
"""
function jac_op(nlp :: AbstractNLPModel, x :: AbstractVector)
  @lencheck nlp.meta.nvar x
  prod = @closure v -> jprod(nlp, x, v)
  ctprod = @closure v -> jtprod(nlp, x, v)
  return LinearOperator{eltype(x)}(nlp.meta.ncon, nlp.meta.nvar,
                                   false, false, prod, ctprod, ctprod)
end

"""
    J = jac_op!(nlp, x, Jv, Jtv)

Return the Jacobian at `x` as a linear operator.
The resulting object may be used as if it were a matrix, e.g., `J * v` or
`J' * v`. The values `Jv` and `Jtv` are used as preallocated storage for the
operations.
"""
function jac_op!(nlp :: AbstractNLPModel, x :: AbstractVector,
                 Jv :: AbstractVector, Jtv :: AbstractVector)
  @lencheck nlp.meta.nvar x Jtv
  @lencheck nlp.meta.ncon Jv
  prod = @closure v -> jprod!(nlp, x, v, Jv)
  ctprod = @closure v -> jtprod!(nlp, x, v, Jtv)
  return LinearOperator{eltype(x)}(nlp.meta.ncon, nlp.meta.nvar,
                                   false, false, prod, ctprod, ctprod)
end

"""
    J = jac_op!(nlp, rows, cols, vals, Jv, Jtv)

Return the Jacobian given by `(rows, cols, vals)` as a linear operator.
The resulting object may be used as if it were a matrix, e.g., `J * v` or `J' * v`.
The values `Jv` and `Jtv` are used as preallocated storage for the operations.
"""
function jac_op!(nlp :: AbstractNLPModel, rows :: AbstractVector{<: Integer}, cols :: AbstractVector{<: Integer}, vals :: AbstractVector, Jv :: AbstractVector, Jtv :: AbstractVector)
  @lencheck nlp.meta.nnzj rows cols vals
  @lencheck nlp.meta.ncon Jv
  @lencheck nlp.meta.nvar Jtv
  prod = @closure v -> jprod!(nlp, rows, cols, vals, v, Jv)
  ctprod = @closure v -> jtprod!(nlp, rows, cols, vals, v, Jtv)
  return LinearOperator{eltype(vals)}(nlp.meta.ncon, nlp.meta.nvar,
                                 false, false, prod, ctprod, ctprod)
end

"""
    J = jac_op!(nlp, x, rows, cols, Jv, Jtv)

Return the Jacobian at `x` as a linear operator.
The resulting object may be used as if it were a matrix, e.g., `J * v` or
`J' * v`. `(rows, cols)` should be the sparsity structure of the Jacobian.
The values `Jv` and `Jtv` are used as preallocated storage for the operations.
"""
function jac_op!(nlp :: AbstractNLPModel, x :: AbstractVector, rows :: AbstractVector{<: Integer}, cols :: AbstractVector{<: Integer}, Jv :: AbstractVector, Jtv :: AbstractVector)
  @lencheck nlp.meta.nvar x Jtv
  @lencheck nlp.meta.nnzj rows cols
  @lencheck nlp.meta.ncon Jv
  vals = jac_coord(nlp, x)
  decrement!(nlp, :neval_jac)
  return jac_op!(nlp, rows, cols, vals, Jv, Jtv)
end

"""
    vals = jth_hess_coord(nlp, x, j)

Evaluate the Hessian of j-th constraint at `x` in sparse coordinate format.
Only the lower triangle is returned.
"""
function jth_hess_coord(nlp::AbstractNLPModel, x::AbstractVector, j::Integer)
  @lencheck nlp.meta.nvar x
  @rangecheck 1 nlp.meta.ncon j
  vals = Vector{eltype(x)}(undef, nlp.meta.nnzh)
  return jth_hess_coord!(nlp, x, j, vals)
end

"""
    vals = jth_hess_coord!(nlp, x, j, vals)

Evaluate the Hessian of j-th constraint at `x` in sparse coordinate format, with `vals` of
length `nlp.meta.nnzh`, in place. Only the lower triangle is returned.
"""
function jth_hess_coord! end

"""
   Hx = jth_hess(nlp, x, j)

Evaluate the Hessian of j-th constraint at `x` as a sparse matrix with
the same sparsity pattern as the Lagrangian Hessian.
Only the lower triangle is returned.
"""
function jth_hess(nlp::AbstractNLPModel, x::AbstractVector, j::Integer) 
  @lencheck nlp.meta.nvar x
  @rangecheck 1 nlp.meta.ncon j
  rows, cols = hess_structure(nlp)
  vals = jth_hess_coord(nlp, x, j)
  return sparse(rows, cols, vals, nlp.meta.nvar, nlp.meta.nvar)
end

"""
    Hv = jth_hprod(nlp, x, v, j)

Evaluate the product of the Hessian of j-th constraint at `x` with the vector `v`.
"""
function jth_hprod(nlp::AbstractNLPModel, x::AbstractVector, v::AbstractVector, j::Integer)
  @lencheck nlp.meta.nvar x v
  @rangecheck 1 nlp.meta.ncon j
  Hv = Vector{eltype(x)}(undef, nlp.meta.nvar)
  return jth_hprod!(nlp, x, v, j, Hv)
end

"""
    Hv = jth_hprod!(nlp, x, v, j, Hv)

Evaluate the product of the Hessian of j-th constraint at `x` with the vector `v`
in place.
"""
function jth_hprod! end

"""
   gHv = ghjvprod(nlp, x, g, v)

Return the vector whose i-th component is gᵀ ∇²cᵢ(x) v.
"""
function ghjvprod(nlp::AbstractNLPModel, x::AbstractVector, g::AbstractVector, v::AbstractVector)
  @lencheck nlp.meta.nvar x g v
  gHv = Vector{eltype(x)}(undef, nlp.meta.ncon)
  return ghjvprod!(nlp, x, g, v, gHv)
end

"""
   ghjvprod!(nlp, x, g, v, gHv)

Return the vector whose i-th component is gᵀ ∇²cᵢ(x) v in place.
"""
function ghjvprod! end

"""
    (rows,cols) = hess_structure(nlp)

Return the structure of the Lagrangian Hessian in sparse coordinate format.
"""
function hess_structure(nlp :: AbstractNLPModel)
  rows = Vector{Int}(undef, nlp.meta.nnzh)
  cols = Vector{Int}(undef, nlp.meta.nnzh)
  hess_structure!(nlp, rows, cols)
end

"""
    hess_structure!(nlp, rows, cols)

Return the structure of the Lagrangian Hessian in sparse coordinate format in place.
"""
function hess_structure! end

"""
    vals = hess_coord!(nlp, x, vals; obj_weight=1.0)

Evaluate the objective Hessian at `x` in sparse coordinate format,
with objective function scaled by `obj_weight`, i.e.,
$(OBJECTIVE_HESSIAN), rewriting `vals`.
Only the lower triangle is returned.
"""
function hess_coord!(nlp :: AbstractNLPModel, x :: AbstractVector, vals :: AbstractVector; obj_weight :: Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.nnzh vals
  hess_coord!(nlp, x, zeros(nlp.meta.ncon), vals, obj_weight=obj_weight)
end

"""
    vals = hess_coord!(nlp, x, y, vals; obj_weight=1.0)

Evaluate the Lagrangian Hessian at `(x,y)` in sparse coordinate format,
with objective function scaled by `obj_weight`, i.e.,
$(LAGRANGIAN_HESSIAN), rewriting `vals`.
Only the lower triangle is returned.
"""
function hess_coord! end

"""
    vals = hess_coord(nlp, x; obj_weight=1.0)

Evaluate the objective Hessian at `x` in sparse coordinate format,
with objective function scaled by `obj_weight`, i.e.,

$(OBJECTIVE_HESSIAN).
Only the lower triangle is returned.
"""
function hess_coord(nlp :: AbstractNLPModel, x :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  vals = Vector{eltype(x)}(undef, nlp.meta.nnzh)
  return hess_coord!(nlp, x, vals; obj_weight=obj_weight)
end

"""
    vals = hess_coord(nlp, x, y; obj_weight=1.0)

Evaluate the Lagrangian Hessian at `(x,y)` in sparse coordinate format,
with objective function scaled by `obj_weight`, i.e.,

$(LAGRANGIAN_HESSIAN).
Only the lower triangle is returned.
"""
function hess_coord(nlp :: AbstractNLPModel, x :: AbstractVector, y :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.ncon y
  vals = Vector{eltype(x)}(undef, nlp.meta.nnzh)
  return hess_coord!(nlp, x, y, vals; obj_weight=obj_weight)
end

"""
    Hx = hess(nlp, x; obj_weight=1.0)

Evaluate the objective Hessian at `x` as a sparse matrix,
with objective function scaled by `obj_weight`, i.e.,

$(OBJECTIVE_HESSIAN).
Only the lower triangle is returned.
"""
function hess(nlp::AbstractNLPModel, x::AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  rows, cols = hess_structure(nlp)
  vals = hess_coord(nlp, x, obj_weight=obj_weight)
  sparse(rows, cols, vals, nlp.meta.nvar, nlp.meta.nvar)
end

"""
    Hx = hess(nlp, x, y; obj_weight=1.0)

Evaluate the Lagrangian Hessian at `(x,y)` as a sparse matrix,
with objective function scaled by `obj_weight`, i.e.,

$(LAGRANGIAN_HESSIAN).
Only the lower triangle is returned.
"""
function hess(nlp::AbstractNLPModel, x::AbstractVector, y::AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.ncon y
  rows, cols = hess_structure(nlp)
  vals = hess_coord(nlp, x, y, obj_weight=obj_weight)
  sparse(rows, cols, vals, nlp.meta.nvar, nlp.meta.nvar)
end

"""
    Hv = hprod(nlp, x, v; obj_weight=1.0)

Evaluate the product of the objective Hessian at `x` with the vector `v`,
with objective function scaled by `obj_weight`, where the objective Hessian is
$(OBJECTIVE_HESSIAN).
"""
function hprod(nlp::AbstractNLPModel, x::AbstractVector, v::AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x v
  Hv = similar(x)
  return hprod!(nlp, x, v, Hv; obj_weight=obj_weight)
end

"""
    Hv = hprod(nlp, x, y, v; obj_weight=1.0)

Evaluate the product of the Lagrangian Hessian at `(x,y)` with the vector `v`,
with objective function scaled by `obj_weight`, where the Lagrangian Hessian is
$(LAGRANGIAN_HESSIAN).
"""
function hprod(nlp::AbstractNLPModel, x::AbstractVector, y::AbstractVector, v::AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x v
  @lencheck nlp.meta.ncon y
  Hv = similar(x)
  return hprod!(nlp, x, y, v, Hv; obj_weight=obj_weight)
end

"""
    Hv = hprod!(nlp, x, v, Hv; obj_weight=1.0)

Evaluate the product of the objective Hessian at `x` with the vector `v` in
place, with objective function scaled by `obj_weight`, where the objective Hessian is
$(OBJECTIVE_HESSIAN).
"""
function hprod!(nlp::AbstractNLPModel, x::AbstractVector, v::AbstractVector, Hv::AbstractVector; obj_weight :: Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x v Hv
  hprod!(nlp, x, zeros(nlp.meta.ncon), v, Hv, obj_weight=obj_weight)
end

"""
    Hv = hprod!(nlp, rows, cols, vals, v, Hv)

Evaluate the product of the objective or Lagrangian Hessian given by `(rows, cols, vals)` in
triplet format with the vector `v` in place. Only one triangle of the Hessian should be given.
"""
function hprod!(nlp::AbstractNLPModel, rows::AbstractVector{<: Integer}, cols::AbstractVector{<: Integer}, vals::AbstractVector, v::AbstractVector, Hv::AbstractVector)
  @lencheck nlp.meta.nnzh rows cols vals
  @lencheck nlp.meta.nvar v Hv
  increment!(nlp, :neval_hprod)
  coo_sym_prod!(cols, rows, vals, v, Hv)
end

"""
    Hv = hprod!(nlp, x, rows, cols, v, Hv; obj_weight=1.0)

Evaluate the product of the objective Hessian at `x` with the vector `v` in
place, where the objective Hessian is
$(OBJECTIVE_HESSIAN).
`(rows, cols)` should be the Hessian structure in triplet format.
"""
hprod!(nlp::AbstractNLPModel, x::AbstractVector, ::AbstractVector{<: Integer}, ::AbstractVector{<: Integer}, v::AbstractVector, Hv::AbstractVector; obj_weight::Real=1.0) = hprod!(nlp, x, v, Hv, obj_weight=obj_weight)

"""
    Hv = hprod!(nlp, x, y, v, Hv; obj_weight=1.0)

Evaluate the product of the Lagrangian Hessian at `(x,y)` with the vector `v` in
place, with objective function scaled by `obj_weight`, where the Lagrangian Hessian is
$(LAGRANGIAN_HESSIAN).
"""
function hprod! end

"""
    Hv = hprod!(nlp, x, y, rows, cols, v, Hv; obj_weight=1.0)

Evaluate the product of the Lagrangian Hessian at `(x,y)` with the vector `v` in
place, where the Lagrangian Hessian is
$(LAGRANGIAN_HESSIAN).
`(rows, cols)` should be the Hessian structure in triplet format.
"""
hprod!(nlp::AbstractNLPModel, x::AbstractVector, y::AbstractVector, ::AbstractVector{<: Integer}, ::AbstractVector{<: Integer}, v::AbstractVector, Hv::AbstractVector; obj_weight::Real=one(eltype(x))) = hprod!(nlp, x, y, v, Hv, obj_weight=obj_weight)

"""
    H = hess_op(nlp, x; obj_weight=1.0)

Return the objective Hessian at `x` with objective function scaled by
`obj_weight` as a linear operator. The resulting object may be used as if it were a
matrix, e.g., `H * v`. The linear operator H represents
$(OBJECTIVE_HESSIAN).
"""
function hess_op(nlp :: AbstractNLPModel, x :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  prod = @closure v -> hprod(nlp, x, v; obj_weight=obj_weight)
  return LinearOperator{eltype(x)}(nlp.meta.nvar, nlp.meta.nvar,
                                   true, true, prod, prod, prod)
end

"""
    H = hess_op(nlp, x, y; obj_weight=1.0)

Return the Lagrangian Hessian at `(x,y)` with objective function scaled by
`obj_weight` as a linear operator. The resulting object may be used as if it were a
matrix, e.g., `H * v`. The linear operator H represents
$(LAGRANGIAN_HESSIAN).
"""
function hess_op(nlp :: AbstractNLPModel, x :: AbstractVector, y :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x
  @lencheck nlp.meta.ncon y
  prod = @closure v -> hprod(nlp, x, y, v; obj_weight=obj_weight)
  return LinearOperator{eltype(x)}(nlp.meta.nvar, nlp.meta.nvar,
                                   true, true, prod, prod, prod)
end

"""
    H = hess_op!(nlp, x, Hv; obj_weight=1.0)

Return the objective Hessian at `x` with objective function scaled by
`obj_weight` as a linear operator, and storing the result on `Hv`. The resulting
object may be used as if it were a matrix, e.g., `w = H * v`. The vector `Hv` is
used as preallocated storage for the operation.  The linear operator H
represents
$(OBJECTIVE_HESSIAN).
"""
function hess_op!(nlp :: AbstractNLPModel, x :: AbstractVector, Hv :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x Hv
  prod = @closure v -> hprod!(nlp, x, v, Hv; obj_weight=obj_weight)
  return LinearOperator{eltype(x)}(nlp.meta.nvar, nlp.meta.nvar,
                                   true, true, prod, prod, prod)
end

"""
    H = hess_op!(nlp, rows, cols, vals, Hv)

Return the Hessian given by `(rows, cols, vals)` as a linear operator,
and storing the result on `Hv`. The resulting
object may be used as if it were a matrix, e.g., `w = H * v`.
  The vector `Hv` is used as preallocated storage for the operation.  The linear operator H
represents
$(OBJECTIVE_HESSIAN).
"""
function hess_op!(nlp :: AbstractNLPModel, rows :: AbstractVector{<: Integer}, cols :: AbstractVector{<: Integer}, vals :: AbstractVector, Hv :: AbstractVector)
  @lencheck nlp.meta.nnzh rows cols vals
  @lencheck nlp.meta.nvar Hv
  prod = @closure v -> hprod!(nlp, rows, cols, vals, v, Hv)
  return LinearOperator{eltype(vals)}(nlp.meta.nvar, nlp.meta.nvar,
                                 true, true, prod, prod, prod)
end

"""
    H = hess_op!(nlp, x, rows, cols, Hv; obj_weight=1.0)

Return the objective Hessian at `x` with objective function scaled by
`obj_weight` as a linear operator, and storing the result on `Hv`. The resulting
object may be used as if it were a matrix, e.g., `w = H * v`.
`(rows, cols)` should be the sparsity structure of the Hessian.
The vector `Hv` is used as preallocated storage for the operation.  The linear operator H
represents
$(OBJECTIVE_HESSIAN).
"""
function hess_op!(nlp :: AbstractNLPModel, x :: AbstractVector, rows :: AbstractVector{<: Integer}, cols :: AbstractVector{<: Integer}, Hv :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x Hv
  @lencheck nlp.meta.nnzh rows cols
  vals = hess_coord(nlp, x, obj_weight=obj_weight)
  return hess_op!(nlp, rows, cols, vals, Hv)
end

"""
    H = hess_op!(nlp, x, y, Hv; obj_weight=1.0)

Return the Lagrangian Hessian at `(x,y)` with objective function scaled by
`obj_weight` as a linear operator, and storing the result on `Hv`. The resulting
object may be used as if it were a matrix, e.g., `w = H * v`. The vector `Hv` is
used as preallocated storage for the operation.  The linear operator H
represents
$(LAGRANGIAN_HESSIAN).
"""
function hess_op!(nlp :: AbstractNLPModel, x :: AbstractVector, y :: AbstractVector, Hv :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x Hv
  @lencheck nlp.meta.ncon y
  prod = @closure v -> hprod!(nlp, x, y, v, Hv; obj_weight=obj_weight)
  return LinearOperator{eltype(x)}(nlp.meta.nvar, nlp.meta.nvar,
                                   true, true, prod, prod, prod)
end

"""
    H = hess_op!(nlp, x, y, rows, cols, Hv; obj_weight=1.0)

Return the Lagrangian Hessian at `(x,y)` with objective function scaled by
`obj_weight` as a linear operator, and storing the result on `Hv`. The resulting
object may be used as if it were a matrix, e.g., `w = H * v`.
`(rows, cols)` should be the sparsity structure of the Hessian.
The vector `Hv` is used as preallocated storage for the operation.  The linear operator H
represents
$(OBJECTIVE_HESSIAN).
"""
function hess_op!(nlp :: AbstractNLPModel, x :: AbstractVector, y :: AbstractVector, rows :: AbstractVector{<: Integer}, cols :: AbstractVector{<: Integer}, Hv :: AbstractVector; obj_weight::Real=one(eltype(x)))
  @lencheck nlp.meta.nvar x Hv
  @lencheck nlp.meta.ncon y
  @lencheck nlp.meta.nnzh rows cols
  vals = hess_coord(nlp, x, y, obj_weight=obj_weight)
  decrement!(nlp, :neval_hess)
  return hess_op!(nlp, rows, cols, vals, Hv)
end

function varscale end
function lagscale end
function conscale end