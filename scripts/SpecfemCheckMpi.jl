#= 
# the following is from https://github.com/usnistgov/Pope.jl/blob/master/scripts/debugscript.jl with the MIT license
JULIA="${JULIA:-julia}"
JULIA_CMD="${JULIA_CMD:-$JULIA --color=yes --startup-file=no}"
# below gets the directory name of the script, even if there is a symlink involved
# from https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
export JULIA_PROJECT=$DIR/..
export JULIA_LOAD_PATH=@:@stdlib  # exclude default environment
exec $JULIA_CMD -e 'include(popfirst!(ARGS))' "${BASH_SOURCE[0]}" "$@" =#
using MPI
MPI.Init()

comm = MPI.COMM_WORLD
println("Hello world, I am $(MPI.Comm_rank(comm)) of $(MPI.Comm_size(comm))")
MPI.Barrier(comm)

@show MPI.MPI_LIBRARY_VERSION_STRING