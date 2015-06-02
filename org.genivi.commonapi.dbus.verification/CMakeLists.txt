cmake_minimum_required (VERSION 2.8.1)

PROJECT(libdbusglue)

SET( ${PROJECT_NAME}_MAJOR_VERSION 3 )
SET( ${PROJECT_NAME}_MINOR_VERSION 0 )
SET( ${PROJECT_NAME}_PATCH_LEVEL 1 ) 

message("Project name: ${PROJECT_NAME}")

SET(PACKAGE_VERSION "${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}.${${PROJECT_NAME}_PATCH_LEVEL}")
SET(COMMONAPI_API_HEADER_VERSION ${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}) # used in *.cmake.in

##############################################################################

# create the commandline variables:
OPTION(BUILD_SHARED_LIBS "Set to OFF to build static libraries" ON )
message("BUILD_SHARED_LIBS is set to value: ${BUILD_SHARED_LIBS}")

OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message("USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif(NOT CMAKE_BUILD_TYPE)

SET(COMMONAPI_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI install path of the cmake files")
SET(COMMONAPI_DBUS_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI-DBus install path of the cmake files")
SET(COMMONAPI_DBUS_TOOL_GENERATOR "na" CACHE STRING "CommonAPI-DBus-Tools generator install path")
SET(COMMONAPI_TEST_FIDL_PATH "na" CACHE STRING "Path to directory with test fidl files for code generation")

if("${COMMONAPI_DBUS_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi_dbus_generator needs to be specified! Use '-DCOMMONAPI_DBUS_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_DBUS_TOOL_GENERATOR specified: ${COMMONAPI_DBUS_TOOL_GENERATOR}")
endif()

if("${COMMONAPI_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi_dbus_generator needs to be specified! Use '-DCOMMONAPI_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_TOOL_GENERATOR specified: ${COMMONAPI_TOOL_GENERATOR}")
endif()
message("Build type: ${CMAKE_BUILD_TYPE}")

##############################################################################
# add COMMONAPI install path to cmake find root path

if(NOT "${COMMONAPI_CMAKE_INSTALL_PATH}" STREQUAL "na")
  set( CMAKE_FIND_ROOT_PATH ${COMMONAPI_CMAKE_INSTALL_PATH};${CMAKE_FIND_ROOT_PATH} )
endif()
if(NOT "${COMMONAPI_DBUS_CMAKE_INSTALL_PATH}" STREQUAL "na")
  set( CMAKE_FIND_ROOT_PATH ${COMMONAPI_DBUS_CMAKE_INSTALL_PATH};${CMAKE_FIND_ROOT_PATH} )
endif()
message("CMAKE_FIND_ROOT_PATH: ${CMAKE_FIND_ROOT_PATH}")

FIND_PACKAGE(PkgConfig)

if ("${USE_INSTALLED_COMMONAPI}" STREQUAL "ON")
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    FIND_PACKAGE(CommonAPI-DBus REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
else()
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(CommonAPI-DBus REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
endif()

message("CommonAPI_CONSIDERED_CONFIGS: ${CommonAPI_CONSIDERED_CONFIGS}")
message("COMMONAPI_INCLUDE_DIRS: ${COMMONAPI_INCLUDE_DIRS}")
message("CommonAPI-DBus_CONSIDERED_CONFIGS: ${CommonAPI-DBus_CONSIDERED_CONFIGS}")
message("COMMONAPI_DBUS_INCLUDE_DIRS: ${COMMONAPI_DBUS_INCLUDE_DIRS}")

###############################################################################
# find DBus by using the 'pkg-config' tool
pkg_check_modules(DBus	dbus-1)

##############################################################################
# generate code from fidl
file(GLOB FIDL_FILES "${COMMONAPI_TEST_FIDL_PATH}/*.fidl")
message("FIDL_FILES: ${FIDL_FILES}")
execute_process(COMMAND ${COMMONAPI_DBUS_TOOL_GENERATOR} -dest src-gen ${FIDL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -dest src-gen -sk Default ${FIDL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
##############################################################################
# dbus glue build section

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x -Wall -DCOMMONAPI_INTERNAL_COMPILATION")

message("Compiler options: ${CMAKE_CXX_FLAGS}") 

include_directories(
    src
    src-gen
    ${COMMONAPI_INCLUDE_DIRS}
    ${DBus_INCLUDE_DIRS}
    ${COMMONAPI_DBUS_INCLUDE_DIRS}
)

# source files
file(GLOB GLUE_SRCS "src-gen/v1_0/commonapi/runtime/*.cpp"
    "src-gen/v1_0/commonapi/communication/*.cpp"
    "src-gen/v1_0/commonapi/datatypes/primitive/*.cpp"
    "src-gen/v1_0/commonapi/datatypes/advanced/*.cpp"
    "src-gen/v1_0/commonapi/datatypes/derived/*.cpp"
    "src-gen/v1_0/commonapi/datatypes/combined/*.cpp"
    "src-gen/v1_0/commonapi/threading/*.cpp"
    "src-gen/v1_0/commonapi/performance/primitive/*.cpp"
    "src-gen/v1_0/commonapi/performance/complex/*.cpp"
    "src-gen/v1_0/commonapi/stability/mp/*.cpp"
    "src-gen/v1_0/commonapi/stability/sp/*.cpp")

# CommonAPI-DBus library
add_library(DBusGlue ${GLUE_SRCS})
target_link_libraries(DBusGlue CommonAPI-DBus)

set_target_properties(DBusGlue PROPERTIES VERSION 0.0.0 SOVERSION 0 LINKER_LANGUAGE C)

##############################################################################
# exporting, configuring and installing of cmake files

# Add all targets to the build-tree export set
export(TARGETS DBusGlue
  FILE "${PROJECT_BINARY_DIR}/DBusGlueTargets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE DBusGlue)

# Create the DBusGlueConfig.cmake and DBusGlueConfigVersion files ...
# ... for the build tree
set(CONF_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/src")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/DBusGlueConfig.cmake.in
  "${PROJECT_BINARY_DIR}/DBusGlueConfig.cmake" @ONLY)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/DBusGlueConfigVersion.cmake.in
  "${PROJECT_BINARY_DIR}/DBusGlueConfigVersion.cmake" @ONLY)

##############################################################################
# maintainer-clean
add_custom_target(maintainer-clean COMMAND rm -rf *)
