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
using Colors
using ColorSchemes
using ColorSchemeTools
using Plots
using PlutoUI
using BenchmarkTools
using LinearAlgebra
using CSV
using DataFrames

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

# ╔═╡ 0e9f9260-fc7d-4b81-936d-86a9806820b9
begin
	cdf = CSV.read("./map.csv", DataFrame)
	cli = Float64[0,0,0,0,1,2,2,3,2,2,2,2,2,2,2,2,2,3,2,2,2]
	@. cli[cli == 0] = 0.1
	@. cli[cli == 1] = 1.1
	@. cli[cli == 2] = .5
	@. cli[cli == 3] = .75
	
	cake = Matrix(cdf)
	for i in 1:length(cli)
		@. cake[cake == i] = cli[i]
	end
	heatmap(cake, c=:grays)
end

# ╔═╡ 720f792a-61f2-4296-b0ab-06bbff619615
begin
	df = CSV.read("./map.csv", DataFrame)
	mlist = Float64[0,0,0,0,1,2,2,3,2,2,2,2,2,2,2,2,2,3,2,2,2]
	@. mlist[mlist == 0] = 0
	@. mlist[mlist == 1] = 1
	@. mlist[mlist == 2] = .012
	@. mlist[mlist== 3] = .55
	
	mask = Matrix(df)
	@. mask[mask==0] = 1e-30
	for i in 1:length(mlist)
		@. mask[mask == i] = mlist[i]
	end
	heatmap(mask)
end

# ╔═╡ f800dc08-6a1b-4d07-8cd5-d506e771e7bd
begin
	Base.@kwdef struct Params <: BaseParams
	    D::ArrayConst{Float64}
	    R::ArrayConst{Float64}
	
		q::ArrayCoordStatus{Float64}
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
			temp .*= mask
			temp = padding(temp)
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
md"""
## Parameters Settings
0.78 ... 対称性崩れ始める　　
0.79 ... 結構大胆に崩れる　　
100 ... 定常
"""

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
	size_of_field = 512 ;N = size_of_field
	
	t1 = fill(.5, N, N)
	t2 = fill(.5, N, N)
	t3 = fill(.1, N, N)

	f = N*0.4 |> round |> Int32
	l = N*0.6 |> round |> Int32
	t1[f:l, f:l] .= 0.8
	t2[f:l, f:l] .= 0.8
	t3[f:l, f:l] .= 0.3
	
	init_plant_amount = [
		rand(512, 512), rand(512, 512), rand(512, 512)
		# t1,t2,t3
	]
	
end;

# ╔═╡ a26cd728-c76b-4ae3-9cb9-fc36a492bc85
p = Params(
	diffusion_speed .|> float |> ArrayConst,
	grow_rate .|> float |> ArrayConst,
	# ArrayCoordStatus([fill(1., size(init_plant_amount[1])), [t for t in init_plant_amount]...]; bc=periodicbc!)
	ArrayCoordStatus([fill(1., size(init_plant_amount[1])), [t .* mask for t in init_plant_amount]...]; bc=periodicbc!)
)

# ╔═╡ 5cf764d3-40ca-456e-9b10-0cc1041d1874
model = CoordModel{Params}(
    iter = equation,
    params = p,
    save_by=1,
    dt=1,
    dx=1,
    n_iter=100
);

# ╔═╡ a4f2b422-dc49-4aa6-a760-b2dba948c100
res = start(model;n_iter=1000)

# ╔═╡ 79ed0155-0cf9-4cb0-8976-5c3f60c8c7a6
c_green = make_colorscheme([
	colorant"#f3f4f6",
	colorant"#e5f2e5",
	colorant"#7fbf7f",
	colorant"#008000",
], 4)

# ╔═╡ f29d786a-42b0-4634-a160-19d8519b6da4
c_city = make_colorscheme([colorant"#f3f4f6", colorant"#e9eaec", colorant"#b4c5ce", colorant"#97a7b0", colorant"#6c7981"], 5)

# ╔═╡ 17906141-6aef-422a-a2ef-97457343e86d
heatmap(cake, c=c_city.colors, clim=(0,1), axis = nothing, legend=false)

# ╔═╡ 6cc7fca5-4114-4ee4-b81b-3cdf11eacfc4
animefig = @animate for r in res
	heatmap(r[4], clim=(0,1), legend=false, c=c_green.colors, axis = nothing)
	heatmap!(cake, clim=(0,1), legend=false, c=c_city.colors, α=0.5, size=(900, 900), axis = nothing)
	# heatmap(r[1]; legend=false, clim=(0, 1), c=:greens, size=(900, 900))
end

# ╔═╡ 15a31c5c-f5dc-4aaf-a21a-171ba25a8029
gif(animefig, fps=100)

# ╔═╡ Cell order:
# ╟─aec46583-6328-4652-96dc-11b9decbd8f0
# ╠═b19f3f44-bb8b-11ec-2744-df32e07d4d45
# ╟─83b53b0d-5fb2-483e-ab8c-f8a6b0d429ae
# ╠═0e9f9260-fc7d-4b81-936d-86a9806820b9
# ╠═720f792a-61f2-4296-b0ab-06bbff619615
# ╠═f800dc08-6a1b-4d07-8cd5-d506e771e7bd
# ╟─7ee4ec8b-c9f9-42b5-9534-6f7c7e60db56
# ╟─2874fda7-e423-4ec5-a0f4-f8319ef61ca5
# ╟─c8e7c66b-8b4f-4b02-a367-3062bf411a64
# ╠═929f0417-a92b-417c-ae1b-415e7476097c
# ╠═a26cd728-c76b-4ae3-9cb9-fc36a492bc85
# ╠═5cf764d3-40ca-456e-9b10-0cc1041d1874
# ╠═a4f2b422-dc49-4aa6-a760-b2dba948c100
# ╠═79ed0155-0cf9-4cb0-8976-5c3f60c8c7a6
# ╠═f29d786a-42b0-4634-a160-19d8519b6da4
# ╠═17906141-6aef-422a-a2ef-97457343e86d
# ╠═6cc7fca5-4114-4ee4-b81b-3cdf11eacfc4
# ╠═15a31c5c-f5dc-4aaf-a21a-171ba25a8029
