# Chloë: Organelle Annotator

To run the annotator or write gff3 or create suffix array files type:

```bash
julia chloe.jl --help
# or for a specific commands e.g.
julia chloe.jl annotate --help
```

(See installing dependencies below)

## Chloë Server

Running the chloe server. In a terminal type:

```bash
JULIA_NUM_THREADS=4 julia src/chloe_svr.jl --level=info
```
(Julia refuses to use more threads that the number of CPUs on your machine:
`python -c 'import multiprocessing as m; print(m.cpu_count())'`)

In another terminal start julia:

```julia
using JuliaWebAPI

i = APIInvoker("tcp://127.0.0.1:9999")
# fasta and output should be relative to the server's working directory, or specify absolute path names!
ret = apicall(i, "chloe", fastafile, outputfile) # outputfile is optional
code, data = ret["code"], ret["data"]
@assert code === 200
# actual filename written and total elapsed
# time in ms to annotate
fname, elapsed_ms = data["filename"], data["elapsed"]
# to terminate the server
apicall(i, ":terminate")
```

The *actual* production configuration runs
the server as a client of a DEALER/ROUTER server
(see `bin/broker.py` and the `Makefile`) and connects to the
DEALER end on `ipc:///tmp/chloe-worker` a unix named socket (so
the server is not visible on the network). The
chloe website connects to `ipc:///tmp/chloe-client` which
is the ROUTER end of broker. In this setup
you can run multiple chloe servers connecting
to the same DEALER.

The use of python to create a broker is
unfortuate but the julia ZMQ package lacks the `proxy` function 
(why? See `src/dealer.jl` for my attempt to make this work).

## Installing dependencies

There is a `Project.toml` file that contains all the project
dependencies... here I think is what you are supposed to do:


Start julia -- in this directory -- and type `]` then type:

```
pkg> activate .
pkg> instantiate
pkg> status
```

Unfortunately to run Chloe from the command line this doesn't work
(or it does work but won't help you to run Chloe from the command line).

You need to get the dependencies into the main julia "package"
(`in ~/.julia/environments/v1.4/Project.toml`). So you will just have
to run a julia REPL like above -- but don't "activate" -- just
`add GZip ArgParse # etc` manually (How annoying is this!).

Check the `Project.toml` file first but cut'n'paste the following into the julia
package prompt:

```julia
pkg> add ArgParse Dates GZip JLD JuliaWebAPI LogRoller Logging Printf StatsBase
```


### Notes:

See:

* http://zguide.zeromq.org/py:all#Multithreading-with-ZeroMQ

Possible useful REPL packages

* add Revise: reload edited files within REPL
* add OhMyREPL: pretty print code
* `@code_warntype f()` check type system

