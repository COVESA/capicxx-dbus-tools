# Copyright (C) 2015 BMW Group
# Author: Manfred Bathelt (manfred.bathelt@bmw.de)
# Author: Juergen Gehring (juergen.gehring@bmw.de)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 2.8)

set(PRJ_NAME UDisks2)

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O0 -std=c++0x -D_GLIBCXX_USE_NANOSLEEP")

message(STATUS "Compiler options: ${CMAKE_CXX_FLAGS}") 

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message(STATUS "USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

if ("${USE_INSTALLED_COMMONAPI}" STREQUAL "ON")
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    FIND_PACKAGE(CommonAPI-DBus REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
else()
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(CommonAPI-DBus REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
endif()

message(STATUS "CommonAPI_CONSIDERED_CONFIGS: ${CommonAPI_CONSIDERED_CONFIGS}")
message(STATUS "COMMONAPI_INCLUDE_DIRS: ${COMMONAPI_INCLUDE_DIRS}")
message(STATUS "CommonAPI-DBus_CONSIDERED_CONFIGS: ${CommonAPI-DBus_CONSIDERED_CONFIGS}")
message(STATUS "COMMONAPI_DBUS_INCLUDE_DIRS: ${COMMONAPI_DBUS_INCLUDE_DIRS}")

# CommonAPI
include(FindPkgConfig)
pkg_check_modules (DBUS "dbus-1 >= 1.4")

# Source Files
set(PRJ_SRC_PATH src)
set(PRJ_SRC_GEN_PATH src-gen/v2/org/freedesktop/UDisks2)

set(PRJ_NAME_CLIENT ${PRJ_NAME}Client)

FILE(GLOB PRJ_DBUS_LIB_SRCS ${PRJ_SRC_GEN_PATH}/*DBus*.cpp)

message("PRJ_SRC_GEN_PATH: ${PRJ_SRC_GEN_PATH}")

set(PRJ_CLIENT_SRCS ${PRJ_SRC_PATH}/${PRJ_NAME_CLIENT}.cpp)

# Paths
OPTION(USE_INSTALLED_DBUS "Set to OFF to use the local (patched) version of dbus" ON)
message(STATUS "USE_INSTALLED_DBUS is set to value: ${USE_INSTALLED_DBUS}")

include_directories(
    src-gen
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_DBUS_INCLUDE_DIRS}
    ${DBUS_INCLUDE_DIRS}
)

if ("${USE_INSTALLED_DBUS}" STREQUAL "ON")
link_directories(
    ${COMMONAPI_LIBDIR}
    ${COMMONAPI_DBUS_LIBDIR}
    ${DBUS_LIBDIR}
)
else()
link_directories(
    ${COMMONAPI_LIBDIR}
    ${COMMONAPI_DBUS_LIBDIR}
    ${DBUS_INCLUDE_DIRS}/dbus/.libs
)
endif()

set(LINK_LIBRARIES -Wl,--no-as-needed -Wl,--as-needed CommonAPI)

# Build Client
add_executable(${PRJ_NAME_CLIENT} ${PRJ_CLIENT_SRCS})
target_link_libraries(${PRJ_NAME_CLIENT} ${LINK_LIBRARIES})

# Build gluecode.so
add_library (${PRJ_NAME}-dbus SHARED ${PRJ_DBUS_LIB_SRCS})
target_link_libraries(${PRJ_NAME}-dbus CommonAPI-DBus ${DBUS_LIBRARIES})

