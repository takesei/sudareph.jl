.PHONY: test

test:
	@julia --code-coverage=user -e 'Pkg.test(coverage=true)'
