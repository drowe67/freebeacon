#
# Freebeacon
#
# CMake configuration contributed by Richard Shaw (KF5OIM)
# Please report questions, comments, problems, or patches to the freetel
# mailing list: https://lists.sourceforge.net/lists/listinfo/freetel-codec2
#

cmake_minimum_required(VERSION 2.8)

# Prevent in-source builds to protect automake/autoconf config.
# If an in-source build is attempted, you will still need to clean up a few
# files manually.
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
  message(FATAL_ERROR "In-source builds in ${CMAKE_BINARY_DIR} are not "   
   "allowed, please remove ./CMakeCache.txt and ./CMakeFiles/, create a "
   "separate build directory and run cmake from there.")
endif("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")

# Set local module path.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

project(freebeacon C)

#
# Set version and generate version.h
#
set(FREEBEACON_VERSION_MAJOR 0)
set(FREEBEACON_VERSION_MINOR 1)
set(FREEBEACON_VERSION_PATCH FALSE)
set(FREEBEACON_VERSION ${FREEBEACON_VERSION_MAJOR}.${FREEBEACON_VERSION_MINOR})
if(FREEBEACON_VERSION_PATCH)
    set(FREEBEACON_VERSION ${FREEBEACON_VERSION}.${FREEBEACON_VERSION_PATCH})
endif()
set(FREEBEACON_VERSION_SUFFIX "devel")
if(FREEBEACON_VERSION_SUFFIX)
    set(FREEBEACON_VERSION_STRING "${FREEBEACON_VERSION} ${FREEBEACON_VERSION_SUFFIX}")
else()
    set(FREEBEACON_VERSION_STRING "${FREEBEACON_VERSION}")
endif()
message(STATUS "freebeacon version: ${FREEBEACON_VERSION_STRING}")
configure_file(cmake/version.h.in version.h @ONLY)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
    message(STATUS "Build type not specified, defaulting to ${CMAKE_BUILD_TYPE}")
endif(NOT CMAKE_BUILD_TYPE)


# Work around for not using a svn working copy.
find_program(SVNVERSION_PATH svnversion)
if(SVNVERSION_PATH)
    execute_process(COMMAND ${SVNVERSION_PATH} .
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE SVN_REVISION_RESULT
        OUTPUT_VARIABLE SVN_CURRENT_REVISION
        ERROR_QUIET
    )
else()
    set(SVN_REVISION_RESULT 1)
endif()
if(SVN_REVISION_RESULT EQUAL 0)
string(STRIP ${SVN_CURRENT_REVISION} SVN_REVISION)
add_definitions(-DSVN_REVISION="${SVN_REVISION}")
else()
add_definitions(-DSVN_REVISION="Unversioned directory")
endif()


# Set default build flags.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -pie -Wl,-z,relro -Wl,-z,now")

# -fPIC is implied on MinGW...
if(NOT WIN32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif()

#
# Setup cmake options
#
set(CMAKE_VERBOSE_MAKEFILE TRUE CACHE BOOL "Verbose makefile.")
set(USE_STATIC_DEPS FALSE CACHE BOOL 
    "Download and build static libraries instead of system libraries.")
set(USE_STATIC_PORTAUDIO FALSE CACHE BOOL 
    "Download and build static portaudio instead of the system library.")
set(USE_STATIC_SNDFILE FALSE CACHE BOOL
    "Download and build static sndfile instead of the system library.")
set(USE_STATIC_SAMPLERATE FALSE CACHE BOOL
    "Download and build static samplerate instead of the system library.")
set(USE_STATIC_CODEC2 FALSE CACHE BOOL
    "Download and build static codec2 instead of the system library.")
#set(USE_STATIC_SPEEXDSP TRUE CACHE BOOL
#    "Download and build static speex instead of the system library.")

if(USE_STATIC_DEPS)
    set(USE_STATIC_PORTAUDIO TRUE FORCE)
    set(USE_STATIC_SNDFILE TRUE FORCE)
    set(USE_STATIC_SAMPLERATE TRUE FORCE)
    set(USE_STATIC_CODEC2 TRUE FORCE)
endif(USE_STATIC_DEPS)

#
# Various hacks and work arounds for building under MinGW.
#
if(MINGW)
    message(STATUS "System is MinGW.")
    # Setup HOST variable.
    include(cmake/MinGW.cmake)
    # This sets up the exe icon for windows under mingw.
    set(RES_FILES "")
    set(RES_FILES "${CMAKE_SOURCE_DIR}/contrib/freedv.rc")
    set(CMAKE_RC_COMPILER_INIT windres)
    enable_language(RC)
    set(CMAKE_RC_COMPILE_OBJECT
        "<CMAKE_RC_COMPILER> <FLAGS> -O coff <DEFINES> -i <SOURCE> -o <OBJECT>")
    include(InstallRequiredSystemLibraries)
endif(MINGW)

# Math library is automatic on MinGW
if(UNIX)
    set(CMAKE_REQUIRED_INCLUDES math.h)
    set(CMAKE_REQUIRED_LIBRARIES m)
endif(UNIX)

# Find some standard headers and functions.
include(CheckIncludeFiles)
check_include_files("stdlib.h" HAVE_STDLIB_H)

include(CheckTypeSize)
check_type_size("int" SIZEOF_INT)

# requires patching to find config.h as it current looks in the
# source directory and the generated file goes in the binary directory.
#configure_file ("${PROJECT_SOURCE_DIR}/cmake/config.h.in"
#                "${PROJECT_BINARY_DIR}/config.h" )
#include_directories(${PROJECT_BINARY_DIR})
#add_definitions(-DHAVE_CONFIG_H)

# Pthread Library
find_package(Threads REQUIRED)
message(STATUS "Threads library flags: ${CMAKE_THREAD_LIBS_INIT}")

#
# Find codec2
#
if(NOT USE_STATIC_CODEC2)
    if(CODEC2_BUILD_DIR)
        message(STATUS "Using codec2 from build directory...")
        find_package(codec2 REQUIRED
            NO_DEFAULT_PATH
            PATHS ${CODEC2_BUILD_DIR}
            CONFIGS codec2.cmake
        )
    else()
        message(STATUS "Looking for codec2...")
        find_package(codec2 QUIET)
    endif()
    if(codec2_FOUND)
        get_target_property(CODEC2_LIBRARY codec2 LOCATION)
        message(STATUS "  codec2 library: ${CODEC2_LIBRARY}")
        message(STATUS "  codec2 headers: ${codec2_INCLUDE_DIRS}")
    else()
        # Try to find manually
        find_path(CODEC2_INCLUDE_DIRS codec2.h
                  PATH_SUFFIXES codec2)
        find_library(CODEC2_LIBRARY NAMES codec2)
        if(CODEC2_LIBRARY AND CODEC2_INCLUDE_DIRS)
            message(STATUS "  codec2 library: ${CODEC2_LIBRARY}")
            message(STATUS "  codec2 headers: ${CODEC2_INCLUDE_DIRS}")
            list(APPEND FREEBEACON_LINK_LIBS ${CODEC2_LIBRARY})
            include_directories(${CODEC2_INCLUDE_DIRS})
        else()
            message(FATAL_ERROR "codec2 library not found.
Linux: 
Codec2 may not be in your distribution so build yourself or use the cmake option to build statically into freebeacon.
Windws:
It's easiest to use the cmake option: USE_STATIC_CODEC2"
        )
        endif()
    endif()
else(NOT USE_STATIC_CODEC2)
    message(STATUS "Will attempt static build of codec2.")
    include(cmake/BuildCodec2.cmake)
endif(NOT USE_STATIC_CODEC2)

#
# Find or build portaudio Library
#
if(NOT USE_STATIC_PORTAUDIO)
    message(STATUS "Looking for portaudio...")
    find_package(Portaudio REQUIRED)
    if(PORTAUDIO_FOUND)
        message(STATUS "  portaudio library: ${PORTAUDIO_LIBRARIES}")
        message(STATUS "  portaudio headers: ${PORTAUDIO_INCLUDE_DIRS}")
        list(APPEND FREEBEACON_LINK_LIBS ${PORTAUDIO_LIBRARIES})
        include_directories(${PORTAUDIO_INCLUDE_DIRS})
    else()
        message(FATAL_ERROR "portaudio library not found.
On Linux systems try installing:
    portaudio-devel  (RPM based systems)
    libportaudio-dev (DEB based systems)
On Windows it's easiest to use the cmake option: USE_STATIC_PORTAUDIO"
        )
    endif()
    if(NOT ${PORTAUDIO_VERSION} EQUAL 19)
        message(WARNING "Portaudio versions other than 19 are known to have issues. You have been warned!")
    endif()
else(NOT USE_STATIC_PORTAUDIO)
    message(STATUS "Will attempt static build of portaudio.")
    include(cmake/BuildPortaudio.cmake)
endif(NOT USE_STATIC_PORTAUDIO)

#
# Samplerate Library
#
if(NOT USE_STATIC_SAMPLERATE)
    message(STATUS "Looking for samplerate...")
    find_library(LIBSAMPLERATE samplerate)
    find_path(LIBSAMPLERATE_INCLUDE_DIR samplerate.h)
    message(STATUS "  samplerate library: ${LIBSAMPLERATE}")
    message(STATUS "  samplerate headers: ${LIBSAMPLERATE_INCLUDE_DIR}")
    if(LIBSAMPLERATE AND LIBSAMPLERATE_INCLUDE_DIR)
        list(APPEND FREEBEACON_LINK_LIBS ${LIBSAMPLERATE})
        include_directories(${LIBSAMPLERATE_INCLUDE_DIR})
    else(LIBSTAMPLERATE AND LIBSAMPLERATE_INCLUDE_DIR)
        message(FATAL_ERROR "samplerate library not found.
On Linux systems try installing:
    samplerate-devel  (RPM based systems)
    libsamplerate-dev (DEB based systems)
On Windows it's easiest to use the cmake option: USE_STATIC_SAMPLERATE"
        )
    endif(LIBSAMPLERATE AND LIBSAMPLERATE_INCLUDE_DIR)
else(NOT USE_STATIC_SAMPLERATE)
    message(STATUS "Will attempt static build of samplerate.")
    include(cmake/BuildSamplerate.cmake)
endif(NOT USE_STATIC_SAMPLERATE)

#    
# sndfile Library
#
if(NOT USE_STATIC_SNDFILE)
    message(STATUS "Looking for sndfile...")
    find_library(LIBSNDFILE sndfile)
    find_path(LIBSNDFILE_INCLUDE_DIR sndfile.h)
    message(STATUS "  sndfile library: ${LIBSNDFILE}")
    message(STATUS "  sndfile headers: ${LIBSNDFILE_INCLUDE_DIR}")
    if(LIBSNDFILE AND LIBSNDFILE_INCLUDE_DIR)
        list(APPEND FREEBEACON_LINK_LIBS ${LIBSNDFILE})
    else(LIBSNDFILE AND LIBSNDFILE_INCLUDE_DIR)
        message(FATAL_ERROR "sndfile library not found.
On Linux systems try installing:
    libsndfile-devel (RPM based systems)
    libsndfile-dev   (DEB based systems)
On Windows it's easiest to use the cmake option: USE_STATIC_SNDFILE"
        )
    endif(LIBSNDFILE AND LIBSNDFILE_INCLUDE_DIR)
else(NOT USE_STATIC_SNDFILE)
    message(STATUS "Will attempt static build of sndfile.")
    include(cmake/BuildSndfile.cmake)
endif(NOT USE_STATIC_SNDFILE)

add_executable(freebeacon freebeacon.c)
target_link_libraries(freebeacon ${FREEBEACON_LINK_LIBS})
if(FREEBEACON_STATIC_DEPS)
    add_dependencies(freebeacon ${FREEBEACON_STATIC_DEPS})
endif()

install(TARGETS freebeacon RUNTIME DESTINATION bin)
