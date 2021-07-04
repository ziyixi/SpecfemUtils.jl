using BinaryBuilder,Pkg

name = "libspecfemUtils"
version = v"0.0.1"
sources = [
    DirectorySource(joinpath(@__DIR__,  "src")),
]

script = raw"""
cd ${WORKSPACE}/srcdir
mkdir build 
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build .
cmake --install .
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos")
]

products = [
    LibraryProduct("libspecfemUtils", :libspecfemUtils),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, expand_gfortran_versions(platforms), products, dependencies)

