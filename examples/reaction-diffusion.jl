### A Pluto.jl notebook ###
# v0.18.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 9f28da32-36e3-486b-bc78-18496b276f1e
begin
import Pkg
Pkg.activate(Base.current_project())
Pkg.instantiate()	
using Plots
using PlutoUI
using BenchmarkTools

using ProgressLogging
using sudareph
end;

# ╔═╡ 72bf4067-2da7-47b9-9e28-3f9eb44ed6f0
md"""
# Gray Scott Model in Julia

## Target Equation
$\frac{\partial u}{\partial t} := D_u \Delta u - uv^2 + F(1-u)$
$\frac{\partial v}{\partial t} := D_v \Delta v + uv^2 - (F + k)v$
"""

# ╔═╡ 77ebb3fa-6a53-4dbd-8529-46df00bbca19
md"""### Library"""

# ╔═╡ a571420e-db03-4529-ae51-a32e90a4963e
@bind params PlutoUI.combine() do Child
md"""
## Parameters:
- N ... Size of Field
  - $(Child("N", Slider(0:512, default=128)))
- D ... Defusion speeds
  - Du ... $(Child("Du", Slider(0:0.01:1, default=.1)))
  - Dv ... $(Child("Dv", Slider(0:0.01:1, default=.05)))
- f ... Fuel Supplying speed
  - $(Child("f", Slider(0:0.0001:1, default=.0545)))
- k ... Product vacumming speed
  - $(Child("k", Slider(0:0.0001:1, default=.062)))
"""
end

# ╔═╡ eabaaa67-32ad-49ef-99f2-3560f5804a29
begin
inputs = [md"$(k, params[k])" for k in keys(params)]
md"""
#### Current Value
$(inputs)
"""
end

# ╔═╡ 54d4735b-a80f-4a7c-905b-ddde67da14ca
md"### Implemention"

# ╔═╡ 9c66d0bc-6565-4fdb-bd2f-0adf714f9abd
begin
Base.@kwdef struct Params <: BaseParams
    Du::Const{Float64}
    Dv::Const{Float64}
    f::Const{Float64}
    k::Const{Float64}

    u::Status{Matrix{Float64}}
    v::Status{Matrix{Float64}}

    Params(Du, Dv, f, k, u, v) = new(
        Const(Du),
        Const(Dv),
        Const(f),
        Const(k),
        Status(u),
        Status(v),
    )
end

Base.copy(p::Params) = Params(p[:Du], p[:Dv], p[:f], p[:k], copy(p[:u]),copy(p[:v]))
sudareph.save(p::Params) = (u=p[:u], v=p[:v])

function equation(p::Params, dt::Float64, dx::Float64)::Params
    Δu = Δ(p[:u])
    Δv = Δ(p[:v])

    ∂u = @. p[:Du] * Δu / dx^2 - p[:u] * p[:v]^2 + p[:f] * (1 - p[:u])
    ∂v = @. p[:Dv] * Δv / dx^2 + p[:u] * p[:v]^2 - (p[:f] + p[:k]) * p[:v]
    p[:u] = p[:u] + dt * ∂u
	p[:v] = p[:v] + dt * ∂v
    return p
end
end

# ╔═╡ 875a2483-77c3-42d5-931f-840ae474fdf6
md"### Code"

# ╔═╡ 050b19ca-3a2b-4fc6-b121-793a19d92604
begin
b = params.N*0.45 |> round |> Int
e = params.N*0.55 |> round |> Int

u = ones(params.N, params.N)
@. u[b:e, b:e] = 0.5

v = zeros(params.N, params.N)
@. v[b:e, b:e] = 0.25
end;

# ╔═╡ 31bdb858-e286-40c0-8c75-c35e43e2f7fa
model = CoordModel{Params}(
    iter=equation,
    params=Params(
        Du=params.Du,
        Dv=params.Dv,
        f=params.f,
        k=params.k,
        u=u,
        v=v,
	) |> copy,
    save_by=50,
    dt=1,
    dx=1,
    n_iter=20000
);

# ╔═╡ 2835c045-e082-4188-a412-74e15311aa8f
res = start(model)

# ╔═╡ 9f25031d-3e54-403b-a067-2813ff65edc6
animefig = @animate for r in res
	heatmap(r.v, legend=false)
end

# ╔═╡ 85ceed71-0af8-441d-bd5c-d16cf770365b
gif(animefig, fps=100)

# ╔═╡ Cell order:
# ╟─72bf4067-2da7-47b9-9e28-3f9eb44ed6f0
# ╟─77ebb3fa-6a53-4dbd-8529-46df00bbca19
# ╟─9f28da32-36e3-486b-bc78-18496b276f1e
# ╟─a571420e-db03-4529-ae51-a32e90a4963e
# ╟─eabaaa67-32ad-49ef-99f2-3560f5804a29
# ╟─54d4735b-a80f-4a7c-905b-ddde67da14ca
# ╟─9c66d0bc-6565-4fdb-bd2f-0adf714f9abd
# ╟─875a2483-77c3-42d5-931f-840ae474fdf6
# ╟─050b19ca-3a2b-4fc6-b121-793a19d92604
# ╟─31bdb858-e286-40c0-8c75-c35e43e2f7fa
# ╠═2835c045-e082-4188-a412-74e15311aa8f
# ╟─9f25031d-3e54-403b-a067-2813ff65edc6
# ╠═85ceed71-0af8-441d-bd5c-d16cf770365b
