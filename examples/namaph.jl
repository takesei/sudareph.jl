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

# ╔═╡ b19f3f44-bb8b-11ec-2744-df32e07d4d45
begin
import Pkg
Pkg.activate(Base.current_project())
Pkg.instantiate()
using Plots
using PlutoUI
using BenchmarkTools
using LinearAlgebra

using ProgressLogging
using sudareph
end;

# ╔═╡ aec46583-6328-4652-96dc-11b9decbd8f0
md"""
# Namaph Simulators
## Import libs
"""

# ╔═╡ 83b53b0d-5fb2-483e-ab8c-f8a6b0d429ae
md"## Implementions"

# ╔═╡ f800dc08-6a1b-4d07-8cd5-d506e771e7bd
begin
	Base.@kwdef struct Params <: BaseParams
	    D::ArrayConst{Float64}
	    R::ArrayConst{Float64}
	
		q::ArrayCoordStatus{Float64}

		# Params(D, R, q; N, bc=x->x) = new(
		# 	D　 .|> float,
		# 	R .|> float,
		# 	ArrayCoordStatus([fill(1., N, N), q...]; bc=bc)
		# )
	end

	Base.copy(p::Params) = Params(
		copy(p[:D]) |> ArrayConst, 
		copy(p[:R]) |> ArrayConst, 
		copy(p.q)
	)
	sudareph.save(p::Params) = copy(supress.(p[:q]))

	function equation(p::Params, dt::T, dx::U)::Params where {T<:Real, U<:Real}
		DΔq = p[:D] .* Δ.(p[:q][2:end]) / dx^2
		
		coef = map(1:length(p[:D])) do i
			return (1:size(p[:R])[2] .|> idx -> p[:R][i, idx] * p[:q][idx]) |> sum
		end
		coef = [coef[i] .* p[:q][begin+i] for i in 1:length(coef)]

		∂q = @. DΔq + supress(coef)
	    temp = map(supress.(p[:q][begin+1:end]) + dt * ∂q) do x
			temp = x
			temp = padding(temp)
			temp = periodicbc!(temp)
			temp[temp .|> isnan] .= 0
			temp[temp .== Inf] .= 1
			temp[temp .== -Inf] .= 0
			return temp
		end
		p[:q][begin+1:end] = temp
	    return p
	end
end

# ╔═╡ 7ee4ec8b-c9f9-42b5-9534-6f7c7e60db56
md"## Parameters Settings"

# ╔═╡ 2874fda7-e423-4ec5-a0f4-f8319ef61ca5
@bind ap confirm(TextField(default="0.765"))

# ╔═╡ c8e7c66b-8b4f-4b02-a367-3062bf411a64
a = parse(Float64, ap)

# ╔═╡ 929f0417-a92b-417c-ae1b-415e7476097c
# begin
# 	number_of_species = 1
# 	diffusion_speed = [1e-1]
# 	grow_rate = [
# 		# [original_rate, interaction_with_1st_plant, interaction_with_2nd_plant, ...]
# 		0 0
# 	]
# 	size_of_field = 5 ;N = size_of_field

# 	temp = zeros(N, N)
# 	temp[3,3]= 1
# 	init_plant_amount = [
# 		temp
# 	]
# end

begin
	number_of_species = 3
	
	diffusion_speed = [1e-5, 1e-5, .1e-3]
	grow_rate = [
		# [original_rate, interaction_with_1st_plant, interaction_with_2nd_plant, ...]
		1.0  -1  -1  -2;
		a -1 -0.8 -1;
		-1 1 1 0
	]
	size_of_field = 100 ;N = size_of_field
	
	t1 = fill(.5, N, N)
	t1[40:60, 40:60] .= 0.8
	t2 = fill(.5, N, N)
	t2[40:60, 40:60] .= 0.8
	t3 = fill(.1, N, N)
	t3[40:60, 40:60] .= 0.3
	
	init_plant_amount = [
		# rand(512, 512), rand(512, 512), rand(512, 512)
		t1,t2,t3
	]
	
end;

# Wanna use
# begin
# 	number_of_species = 4
	
# 	diffusion_speed = [1e-5, 1e-3, .1e-2, .1e-2]
# 	grow_rate = [
# 		# [original_rate, interaction_with_1st_plant, interaction_with_2nd_plant, ...]
# 		[1.0,    0, -0.2, -0.4,  -1],
# 		[0.5, -0.3,  1.0,  0.1,-0.1],
# 		[0.2, -0.5, -0.1,  1.0,   0],
#       	[.01, 0.01, 0.02,    0, 1.0]
# 	]
# 	size_of_field = 10 ;N = size_of_field
# 	init_plant_amount = [
# 		fill(5., N, N),
# 		fill(5., N, N),
# 		fill(5., N, N),
# 		fill(5., N, N),
# 	]
# end;

# ╔═╡ a26cd728-c76b-4ae3-9cb9-fc36a492bc85
p = Params(
	diffusion_speed .|> float |> ArrayConst,
	grow_rate .|> float |> ArrayConst,
	ArrayCoordStatus([fill(1., size(init_plant_amount[1])), init_plant_amount...]; bc=periodicbc!)
)

# ╔═╡ 5cf764d3-40ca-456e-9b10-0cc1041d1874
model = CoordModel{Params}(
    iter = equation,
    params = p |> copy,
    save_by=1,
    dt=1,
    dx=1,
    n_iter=1000
);

# ╔═╡ a4f2b422-dc49-4aa6-a760-b2dba948c100
res = start(model)

# ╔═╡ 6cc7fca5-4114-4ee4-b81b-3cdf11eacfc4
animefig = @animate for r in res
	heatmap(r[2], clim=(0,1))
	# heatmap(r[1]; legend=false, clim=(0, 1), c=:greens, size=(900, 900))
end

# ╔═╡ 15a31c5c-f5dc-4aaf-a21a-171ba25a8029
gif(animefig, fps=100)

# ╔═╡ Cell order:
# ╟─aec46583-6328-4652-96dc-11b9decbd8f0
# ╠═b19f3f44-bb8b-11ec-2744-df32e07d4d45
# ╟─83b53b0d-5fb2-483e-ab8c-f8a6b0d429ae
# ╠═f800dc08-6a1b-4d07-8cd5-d506e771e7bd
# ╟─7ee4ec8b-c9f9-42b5-9534-6f7c7e60db56
# ╟─2874fda7-e423-4ec5-a0f4-f8319ef61ca5
# ╟─c8e7c66b-8b4f-4b02-a367-3062bf411a64
# ╠═929f0417-a92b-417c-ae1b-415e7476097c
# ╠═a26cd728-c76b-4ae3-9cb9-fc36a492bc85
# ╠═5cf764d3-40ca-456e-9b10-0cc1041d1874
# ╠═a4f2b422-dc49-4aa6-a760-b2dba948c100
# ╠═6cc7fca5-4114-4ee4-b81b-3cdf11eacfc4
# ╠═15a31c5c-f5dc-4aaf-a21a-171ba25a8029
