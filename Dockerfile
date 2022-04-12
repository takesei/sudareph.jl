FROM julia:1.7.2-buster

RUN mkdir /work
WORKDIR /work

RUN julia -e 'import Pkg; Pkg.add("Pluto")'
CMD julia -e 'import Pluto; Pluto.run(;launch_browser=false, port=1234, host="0.0.0.0", require_secret_for_open_links=false, require_secret_for_access=false)'
