cmake_minimum_required(VERSION 3.17.0)
# cmake_policy(SET CMP0048 NEW)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Do not enable compiler specific extensions, for eg on GCC use -std=c++1z (=c++17) and not -std=gnu++17
set(CMAKE_CXX_EXTENSIONS OFF)

# Use ccache is available, has to be before "project()"
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  # Support Unix Makefiles and Ninja
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project(CrossCompileTest VERSION 0.0.1)

# The PROJECT_SOURCE_DIR here is root of this repo, which we will use instead of using CMAKE_SOURCE_DIR
set(PROJECT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
# We will use BINARY_DIR instead of CMAKE_BINARY_DIR
set(PROJECT_BINARY_DIR "${CMAKE_BINARY_DIR}")

#MESSAGE(FATAL_ERROR "CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}, BINARY_DIR=${BINARY_DIR}, PROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}, CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}, CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}")

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()

#if(POLICY CMP0020)
  #cmake_policy(SET CMP0020 NEW)
#endif()
#if(POLICY CMP0022)
  #cmake_policy(SET CMP0022 NEW)
#endif()
#if(POLICY CMP0042)
  #cmake_policy(SET CMP0042 NEW)
#endif()
#if(POLICY CMP0054)
  #cmake_policy(SET CMP0054 NEW)
#endif()
#if(POLICY CMP0077)
  #cmake_policy(SET CMP0077 NEW)
#endif()

add_library(project_options INTERFACE)
target_compile_features(project_options INTERFACE cxx_std_20)

###############################################################################
#                                  N I N J A                                  #
###############################################################################
# Ninja support: has to be atop for it to take effect before anything else is done
# Add Color Output if Using Ninja
macro(AddCXXFlagIfSupported flag test)
  CHECK_CXX_COMPILER_FLAG(${flag} ${test})
  if(${${test}})
    message("adding ${flag}")
    target_compile_options(project_options INTERFACE "${flag}")
  endif()
endmacro()

if("Ninja" STREQUAL ${CMAKE_GENERATOR})
  # Clang
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    AddCXXFlagIfSupported(-fcolor-diagnostics COMPILER_SUPPORTS_fcolor-diagnostics)
  endif()

  # g++
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    # For some reason it doesn't say its supported, but it works...
    # AddCXXFlagIfSupported(-fdiagnostics-color COMPILER_SUPPORTS_fdiagnostics-color)
    message(STATUS "Ninja: Forcing -fdiagnostics-color=always")
    target_compile_options(project_options INTERFACE -fdiagnostics-color=always)
  endif()
endif()

# Xcode/Ninja generators undefined MAKE
if(CMAKE_GENERATOR MATCHES "Make")
  set(MAKE "$(MAKE)")
else()
  set(MAKE make)
endif()

# Enable runtime checking features: TSAN, ASAN, UBSAN
message("CMAKE_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}")
if(CMAKE_COMPILER_IS_GNUCC OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

  option(ENABLE_COVERAGE "Enable coverage reporting for gcc/clang" ON)
  if(ENABLE_COVERAGE)
    target_compile_options(project_options INTERFACE --coverage -O0 -g)
    target_link_libraries(project_options INTERFACE --coverage)
  endif()
endif()

###############################################################################
#                         C M A K E    C O N T R O L                          #
###############################################################################

# High level project configuration
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Products")

set(LIBRARY_SEARCH_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Release" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Debug")

###############################################################################
#          C O M P I L E R    A N D    S Y S T E M    O P T I O N S           #
###############################################################################

# Compiler and system specific options
if(UNIX)

  # all warnings
  target_compile_options(project_options INTERFACE -fPIC -fno-strict-aliasing -Winvalid-pch)
  # Treat all warnings as errors, extra errors, and be pedantic
  target_compile_options(project_options INTERFACE -Wall -Wextra -Werror -pedantic-errors -pedantic) # Turn on warnings
  if(APPLE)
     target_compile_options(project_options INTERFACE -Wno-overloaded-virtual -ftemplate-depth=1024)
  endif()

  # Note: CMAKE_CXX_STANDARD set to 20 should already take care of adding -std=c++20 or equivalent
endif()

#######################################################################
#                              C O N A N                              #
#######################################################################

if (TRUE)
set(CMAKE_CONAN_EXPECTED_HASH 170c3250029af321395135a3952a9045)
set(CMAKE_CONAN_VERSION "v0.16.1")

if(EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
  file(MD5 "${CMAKE_BINARY_DIR}/conan.cmake" CMAKE_CONAN_HASH)
endif()
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake" OR NOT "${CMAKE_CONAN_HASH}" MATCHES "${CMAKE_CONAN_EXPECTED_HASH}")
  # Put it in CMAKE_BINARY_DIR so we don't end up with two when building OpenStudioApplication
  message(STATUS "Downloading conan.cmake ${CMAKE_CONAN_VERSION} from https://github.com/conan-io/cmake-conan")
  file(DOWNLOAD "https://github.com/conan-io/cmake-conan/raw/${CMAKE_CONAN_VERSION}/conan.cmake"
     "${CMAKE_BINARY_DIR}/conan.cmake")
else()
  message(STATUS "Using existing conan.cmake")
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)

conan_check(VERSION 1.35.0 REQUIRED)

message(STATUS "RUNNING CONAN")

list(APPEND CONAN_BUILD "missing")

conan_cmake_run(REQUIRES
  fmt/7.1.3
  BASIC_SETUP CMAKE_TARGETS NO_OUTPUT_DIRS
  OPTIONS ${CONAN_OPTIONS}
  BUILD ${CONAN_BUILD}
  PROFILE ${CONAN_HOST_PROFILE}
  # PROFILE_BUILD ${CONAN_BUILD_PROFILE}
  # Passes `-u, --update`    to conan install: Check updates exist from upstream remotes
  # That and build=outdated should ensure we track the right
  # UPDATE
)

message("CONAN_LIBS=${CONAN_LIBS}")

# Search first in the binary dir, where conan will install finders, then
# search for modules in the root dir to override cmake ones
# Start with ROOT, then PROJECT_BINARY_DIR
list(APPEND CMAKE_MODULE_PATH "${PROJECT_BINARY_DIR}" "${PROJECT_SOURCE_DIR}/CMake")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")
endif()

###############################################################################
#                              E X E C U T A B L E                            #
###############################################################################

include_directories(${PROJECT_BINARY_DIR})

add_library(testlib SHARED
  src/utils.hpp
  src/utils.cpp
)

target_link_libraries(testlib
  PRIVATE
    project_options
    CONAN_PKG::fmt
)

add_executable(main
  src/main.cpp
)
target_link_libraries(main PRIVATE testlib)

###############################################################################
#                              I N S T A L L E R                              #
###############################################################################

#################  C O N F I G U R A T I O N   #################

if (APPLE)
  set(CPACK_IFW_TARGET_DIRECTORY /Applications/CrossCompile-Test-${PROJECT_VERSION}/)
elseif(UNIX)

  # For debug
  # set(CPACK_DEBIAN_PACKAGE_DEBUG ON)

  set(CPACK_DEBIAN_PACKAGE_DEPENDS "")

  # These two will set the .deb install path correctly
  set(CPACK_SET_DESTDIR ON)
  set(CPACK_DEBIAN_PACKAGE_NAME "crosscompile-test-${PROJECT_VERSION}")

  set(CPACK_INSTALL_PREFIX /usr/local/${CPACK_DEBIAN_PACKAGE_NAME})
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Julien")

elseif(WIN32)
  set(CPACK_PACKAGE_INSTALL_DIRECTORY "CrossCompile-Test-${PROJECT_VERSION}")
  set(CPACK_IFW_TARGET_DIRECTORY "C:/${CPACK_PACKAGE_INSTALL_DIRECTORY}")
  set(CPACK_BINARY_IFW ON CACHE BOOL "Enable to build IFW packages")
endif()

include(CPack)
include(CPackIFW)

cpack_add_component(Libraries
  DISPLAY_NAME "Libraries"
  DESCRIPTION "Libraries"
)

cpack_add_component(Executable
  DISPLAY_NAME "Test Exe"
  DESCRIPTION "Test Exe"
)

install(TARGETS testlib DESTINATION bin COMPONENT Libraries)
install(TARGETS main DESTINATION bin COMPONENT Executable)

#############   S Y S T E M    L I B R A R I E S   #############

# Add compiler-provided system runtime libraries
#if( NOT UNIX )
  # Skip the call to install(PROGRAMS) so we can specify our own install rule (using the value of `CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS`)
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)

  # Set to TRUE to install the Windows Universal CRT libraries for app-local deployment.
  # This is meaningful only with MSVC from Visual Studio 2015 or higher, which is our case
  #SET(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)

  include(InstallRequiredSystemLibraries)
  if(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
    message(WARNING "CMAKE_INSTALL_SYSTEM_RUNTIME_LIBs: ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}")
    install(PROGRAMS ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} DESTINATION "bin" COMPONENT Libraries)
  endif()
#endif()
