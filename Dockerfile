FROM julia:1.7.2-buster

RUN mkdir /work
WORKDIR /work

RUN julia -e 'import Pkg; Pkg.add("Pluto")'
