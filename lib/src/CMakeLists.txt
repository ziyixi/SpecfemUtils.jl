cmake_minimum_required(VERSION 3.14)

project(
  "specfemUtils"
  LANGUAGES "Fortran"
  VERSION "0.0.1"
)

# not necessary as SHARED already enables -fPIC
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_library("${PROJECT_NAME}" SHARED 
    rotate_tensor.f90
    shared_par.f90
)

install(TARGETS "${PROJECT_NAME}")