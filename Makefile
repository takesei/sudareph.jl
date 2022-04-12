.PHONY: lint

lint:
	@julia -e  'using JuliaFormatter; format(".")'
