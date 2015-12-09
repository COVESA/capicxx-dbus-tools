# Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 2.8)

set(PRJ_NAME ObjectPathSimple)

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O0 -std=c++0x -D_GLIBCXX_USE_NANOSLEEP -pthread")

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

SET(COMMONAPI_TOOL_GENERATOR "na" CACHE STRING "CommonAPI-Tools generator install path")

if("${COMMONAPI_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi-generator needs to be specified! Use '-DCOMMONAPI_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_TOOL_GENERATOR specified: ${COMMONAPI_TOOL_GENERATOR}")
endif()

SET(COMMONAPI_DBUS_TOOL_GENERATOR "na" CACHE STRING "CommonAPI-DBus-Tools generator install path")

if("${COMMONAPI_DBUS_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi-dbus-generator needs to be specified! Use '-DCOMMONAPI_DBUS_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_DBUS_TOOL_GENERATOR specified: ${COMMONAPI_DBUS_TOOL_GENERATOR}")
endif()

##############################################################################
# generate code from franca files
file(GLOB FIDL_FILES "fidl/*.fidl")
file(GLOB FDEPL_FILES "fidl/*.fdepl")
message("FIDL_FILES: ${FIDL_FILES}")
message("FDEPL_FILES: ${FDEPL_FILES}")

execute_process(COMMAND ${COMMONAPI_DBUS_TOOL_GENERATOR} -dest src-gen ${FDEPL_FILES} 
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )

execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -dest src-gen ${FIDL_FILES} -sk Default
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )

message(STATUS "CommonAPI_CONSIDERED_CONFIGS: ${CommonAPI_CONSIDERED_CONFIGS}")
message(STATUS "COMMONAPI_INCLUDE_DIRS: ${COMMONAPI_INCLUDE_DIRS}")
message(STATUS "CommonAPI-DBus_CONSIDERED_CONFIGS: ${CommonAPI-DBus_CONSIDERED_CONFIGS}")
message(STATUS "COMMONAPI_DBUS_INCLUDE_DIRS: ${COMMONAPI_DBUS_INCLUDE_DIRS}")

# CommonAPI
include(FindPkgConfig)
pkg_check_modules (DBUS "dbus-1 >= 1.4")

# Source Files
set(PRJ_SRC_PATH src)
set(PRJ_SRC_GEN_PATH src-gen/v1/commonapi/examples)

set(PRJ_NAME_CLIENT ${PRJ_NAME}Client)
set(PRJ_NAME_SERVICE ${PRJ_NAME}Service)

FILE(GLOB PRJ_DBUS_LIB_SRCS ${PRJ_SRC_GEN_PATH}/*DBus*.cpp)

FILE(GLOB PRJ_STUB_GEN_SRCS ${PRJ_SRC_GEN_PATH}/*StubDefault.cpp)
FILE(GLOB PRJ_STUB_IMPL_SRCS ${PRJ_SRC_PATH}/*Stub*.cpp)

set(PRJ_CLIENT_SRCS ${PRJ_SRC_PATH}/${PRJ_NAME_CLIENT}.cpp)
set(PRJ_SERVICE_SRCS ${PRJ_SRC_PATH}/${PRJ_NAME_SERVICE}.cpp ${PRJ_STUB_GEN_SRCS} ${PRJ_STUB_IMPL_SRCS})

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
)
else()
link_directories(
    ${COMMONAPI_LIBDIR}
    ${COMMONAPI_DBUS_LIBDIR}
    ${DBUS_LIBRARY_DIRS}
)
endif()

message(STATUS "DBUS_LIBRARIES = ${DBUS_LIBRARIES}")

set(LINK_LIBRARIES -Wl,--no-as-needed -Wl,--as-needed CommonAPI)

# Build Client
add_executable(${PRJ_NAME_CLIENT} ${PRJ_CLIENT_SRCS})
target_link_libraries(${PRJ_NAME_CLIENT} ${LINK_LIBRARIES})

# Build service
add_executable(${PRJ_NAME_SERVICE} ${PRJ_SERVICE_SRCS})
target_link_libraries(${PRJ_NAME_SERVICE} ${LINK_LIBRARIES})

# Build gluecode.so
add_library (${PRJ_NAME}-dbus SHARED ${PRJ_DBUS_LIB_SRCS})
target_link_libraries(${PRJ_NAME}-dbus CommonAPI-DBus ${DBUS_LIBRARIES})
