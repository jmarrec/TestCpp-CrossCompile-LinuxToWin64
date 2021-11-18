# Sample toolchain file for building for Windows from an Ubuntu Linux system.
#
# Typical usage:
#    *) install cross compiler: `sudo apt-get install mingw-w64`
#    *) cd build
#    *) cmake -DCMAKE_TOOLCHAIN_FILE=~/mingw-w64-x86_64.cmake ..

set(CMAKE_SYSTEM_NAME Windows)
set(TOOLCHAIN_PREFIX x86_64-w64-mingw32)

# cross compilers to use for C, C++ and Fortran
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++)
set(CMAKE_Fortran_COMPILER ${TOOLCHAIN_PREFIX}-gfortran)
set(CMAKE_RC_COMPILER ${TOOLCHAIN_PREFIX}-windres)

# target environment on the build host system
set(CMAKE_FIND_ROOT_PATH /usr/${TOOLCHAIN_PREFIX})

# modify default behavior of FIND_XXX() commands
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Use a cross compiling toolchain for conan
# Host platform: The platform on which the generated binaries will run.
set(CONAN_HOST_PROFILE "${CMAKE_CURRENT_LIST_DIR}/conan_linux_to_win64")
set(CONAN_DISABLE_CHECK_COMPILER ON)

set(EXPLICIT_SHIP_DLLS OFF)

if(NOT EXPLICIT_SHIP_DLLS)
  # Avoid having to explicitly ship the mingw dlls (libgcc_s_seh-1.dll  libstdc++-6.dll)
  # TODO: not working
  # set(CMAKE_EXE_LINKER_FLAGS "-static")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")

else()
  # Explicitly ship the DLLs instead of static linking them
  execute_process (COMMAND "${CMAKE_C_COMPILER}" -print-libgcc-file-name
    RESULT_VARIABLE _libgcc_SUCCESS
    OUTPUT_VARIABLE _libgcc_LOCATION
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(_libgcc_SUCCESS)
    message(FATAL_ERROR "Cannot use the mingw gcc \"${CMAKE_C_COMPILER}\"")
  elseif(_libgcc_LOCATION STREQUAL "")
    message(FATAL_ERROR "Cannot find the location of the mingw libgcc via \"${CMAKE_C_COMPILER} -print-libgcc-file-name\"")
  endif()

  get_filename_component(MINGW_LIB_DIR ${_libgcc_LOCATION} DIRECTORY CACHE)
  message(AUTHOR_WARNING "MINGW_LIB_DIR=${MINGW_LIB_DIR}")
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS
    ${MINGW_LIB_DIR}/libgcc_s_seh-1.dll
    ${MINGW_LIB_DIR}/libstdc++-6.dll
  )
endif()
