# Copyright (C) 2013-2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required (VERSION 2.8.1)

SET( ${PROJECT_NAME}_MAJOR_VERSION 3 )
SET( ${PROJECT_NAME}_MINOR_VERSION 1 )
SET( ${PROJECT_NAME}_PATCH_LEVEL 5 )

##############################################################################

# create the commandline variables:
OPTION(BUILD_SHARED_LIBS "Set to OFF to build static libraries" ON )
message("BUILD_SHARED_LIBS is set to value: ${BUILD_SHARED_LIBS}")

OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message("USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

OPTION(USE_INSTALLED_DBUS "Set to OFF to use the local (build tree) version of DBUS" ON)
message(STATUS "USE_INSTALLED_DBUS is set to value: ${USE_INSTALLED_DBUS}")

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
# CommonAPI
include(FindPkgConfig)
###############################################################################
# find DBus by using the 'pkg-config' tool
if (MSVC)
    #Not beautiful, but it works
    if (DBus_DIR)
        if (DBus_BUILD_DIR)
            set(DBus_INCLUDE_DIRS "${DBus_DIR};${DBus_BUILD_DIR};")
        else ()
            message (FATAL_ERROR "DBus_BUILD_DIR not set! Cannot continue.")
        endif ()
    else()
        message (FATAL_ERROR "DBus_DIR not set! Cannot continue.")
    endif ()
else()
    pkg_check_modules(DBus REQUIRED dbus-1>=1.4)
endif()

##############################################################################

##############################################################################
# google test

# check for set environment variable
if(DEFINED ENV{GTEST_ROOT})
    message("GTEST_ROOT is set. GTEST_ROOT = $ENV{GTEST_ROOT}")
else()
    message("GTEST_ROOT is not defined. For building the tests environment variable
             GTEST_ROOT have to be defined. Tests can not be built.")
    # early exit
    return()  # test can not be build -> make check is not available
endif()

# build google test as static library (always) -> therefore deactivate BUILD_SHARED_LIBS in case it is active
set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 0)
if ("${BUILD_SHARED_LIBS}" STREQUAL "ON")
    set(BUILD_SHARED_LIBS OFF)
    set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 1)
endif()

# ...but visual studio needs a shared CRT for gtest, otherwise the linker won't work correctly with the testcases.
if (MSVC)
    set( gtest_force_shared_crt ON CACHE BOOL "Always use msvcrt.dll" )
endif()

add_subdirectory($ENV{GTEST_ROOT} ${CMAKE_CURRENT_BINARY_DIR}/gtest EXCLUDE_FROM_ALL)
if ("${BUILD_SHARED_LIBS_AUTOMATIC_OFF}" STREQUAL "1")
    set(BUILD_SHARED_LIBS ON)
    set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 0)
endif()

pkg_check_modules(GLIB glib-2.0)

# build tests

enable_testing()

add_custom_target(build_tests)

set(CMAKE_CTEST_COMMAND ctest -V)
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})

add_dependencies(check build_tests)

if (MSVC)
# Visual C++ is not always sure whether he is really C++
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_CRT_SECURE_NO_WARNINGS /EHsc -DCOMMONAPI_INTERNAL_COMPILATION")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -D_CRT_SECURE_NO_WARNINGS -DCOMMONAPI_INTERNAL_COMPILATION")
else()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x -Wall -Wextra -Wformat -Wformat-security -Wconversion -fexceptions -fstrict-aliasing -fstack-protector -fasynchronous-unwind-tables -fno-omit-frame-pointer -D_GLIBCXX_USE_NANOSLEEP")
endif()

message("Compiler options: ${CMAKE_CXX_FLAGS}")

include_directories(
    src
    src-gen/dbus
    src-gen/core
    ${COMMONAPI_INCLUDE_DIRS}
    ${DBus_INCLUDE_DIRS}
    ${COMMONAPI_DBUS_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
    ${gtest_SOURCE_DIR}/include
)

if ("${USE_INSTALLED_DBUS}" STREQUAL "OFF")
    link_directories(
        ${DBus_INCLUDE_DIRS}/dbus/.libs
    )
endif()


##############################################################################
# generate code from fidl
file(GLOB FIDL_FILES "fidl/*.fidl")
message("FIDL_FILES: ${FIDL_FILES}")
file(GLOB FDEPL_FILES "fidl/*.fdepl")
message("FDEPL_FILES: ${FDEPL_FILES}")

execute_process(COMMAND ${COMMONAPI_DBUS_TOOL_GENERATOR} -dest src-gen/dbus ${FIDL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
execute_process(COMMAND ${COMMONAPI_DBUS_TOOL_GENERATOR} -dest src-gen/dbus ${FDEPL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest src-gen/core ${FIDL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest src-gen/core ${FDEPL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
##############################################################################

set(VERSION "v1")

set(TestInterfaceSources src-gen/core/commonapi/tests/DerivedTypeCollection.cpp
                         src-gen/core/${VERSION}/commonapi/tests/TestInterfaceStubDefault.cpp)

set(TestInterfaceDBusSources ${TestInterfaceSources}
                             src-gen/dbus/${VERSION}/commonapi/tests/TestInterfaceDBusProxy.cpp
                             src-gen/dbus/${VERSION}/commonapi/tests/TestInterfaceDBusStubAdapter.cpp
                             src-gen/dbus/${VERSION}/fake/legacy/service/LegacyInterfaceDBusProxy.cpp
                             src-gen/dbus/${VERSION}/fake/legacy/service/LegacyInterfaceNoObjectManagerDBusProxy.cpp)

set(TestInterfaceManagerSources src-gen/core/${VERSION}/commonapi/tests/TestInterfaceManagerStubDefault.cpp)

set(TestInterfaceManagerDBusSources ${TestInterfaceManagerSources}
                                    src-gen/dbus/${VERSION}/commonapi/tests/TestInterfaceManagerDBusProxy.cpp
                                    src-gen/dbus/${VERSION}/commonapi/tests/TestInterfaceManagerDBusStubAdapter.cpp)

set(FreedesktopPropertiesSources src-gen/core/${VERSION}/commonapi/tests/TestFreedesktopInterfaceStubDefault.cpp
                                 src-gen/core/${VERSION}/commonapi/tests/TestFreedesktopDerivedInterfaceStubDefault.cpp)

set(FreedesktopPropertiesDBusSources ${FreedesktopPropertiesSources}
                                     src-gen/dbus/${VERSION}/commonapi/tests/TestFreedesktopInterfaceDBusProxy.cpp
                                     src-gen/dbus/${VERSION}/commonapi/tests/TestFreedesktopInterfaceDBusStubAdapter.cpp
                                     src-gen/dbus/${VERSION}/commonapi/tests/TestFreedesktopDerivedInterfaceDBusProxy.cpp
                                     src-gen/dbus/${VERSION}/commonapi/tests/TestFreedesktopDerivedInterfaceDBusStubAdapter.cpp)

set(ManagedSources src-gen/core/${VERSION}/commonapi/tests/managed/LeafInterfaceStubDefault.cpp
                   src-gen/core/${VERSION}/commonapi/tests/managed/BranchInterfaceStubDefault.cpp
                   src-gen/core/${VERSION}/commonapi/tests/managed/RootInterfaceStubDefault.cpp
                   src-gen/core/${VERSION}/commonapi/tests/managed/SecondRootStubDefault.cpp)

set(ManagedDBusSources ${ManagedSources}
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/RootInterfaceDBusProxy.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/RootInterfaceDBusStubAdapter.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/LeafInterfaceDBusProxy.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/LeafInterfaceDBusStubAdapter.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/BranchInterfaceDBusProxy.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/BranchInterfaceDBusStubAdapter.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/SecondRootDBusProxy.cpp
                       src-gen/dbus/${VERSION}/commonapi/tests/managed/SecondRootDBusStubAdapter.cpp)

set(ExtendedInterfaceSources src-gen/core/${VERSION}/commonapi/tests/ExtendedInterfaceStubDefault.cpp)

set(ExtendedInterfaceDBusSources ${ExtendedInterfaceSources}
                                 src-gen/dbus/${VERSION}/commonapi/tests/ExtendedInterfaceDBusProxy.cpp
                                 src-gen/dbus/${VERSION}/commonapi/tests/ExtendedInterfaceDBusStubAdapter.cpp)

set(ObjectPathSources src-gen/core/${VERSION}/test/objectpath/TestInterfaceStubDefault.cpp)

set(ObjectPathDBusSources ${ObjectPathSources}
                          src-gen/dbus/${VERSION}/test/objectpath/TestInterfaceDBusProxy.cpp
                          src-gen/dbus/${VERSION}/test/objectpath/TestInterfaceDBusDeployment.cpp
                          src-gen/dbus/${VERSION}/test/objectpath/TestInterfaceDBusStubAdapter.cpp)

set(UnixFDSources src-gen/core/${VERSION}/test/unixfd/TestInterfaceStubDefault.cpp)

set(UnixFDDBusSources ${UnixFDSources}
                          src-gen/dbus/${VERSION}/test/unixfd/TestInterfaceDBusProxy.cpp
                          src-gen/dbus/${VERSION}/test/unixfd/TestInterfaceDBusDeployment.cpp
                          src-gen/dbus/${VERSION}/test/unixfd/TestInterfaceDBusStubAdapter.cpp)

set(TEST_LINK_LIBRARIES -Wl,--no-as-needed CommonAPI-DBus -Wl,--as-needed CommonAPI ${DBus_LDFLAGS} ${DL_LIBRARY} gtest ${PTHREAD_LIBRARY})

set(TEST_LINK_LIBRARIES_WITHOUT_COMMONAPI_DBUS CommonAPI gtest ${PTHREAD_LIBRARY})

##############################################################################
# DBusObjectPathTest
##############################################################################

add_executable(DBusObjectPathTest src/DBusObjectPathTest.cpp
                               src/stubs/ObjectPathStubImpl.cpp
                               ${ObjectPathDBusSources})
target_link_libraries(DBusObjectPathTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusUnixFDTest
##############################################################################

add_executable(DBusUnixFDTest src/DBusUnixFDTest.cpp
                               src/stubs/UnixFDStubImpl.cpp
                               ${UnixFDDBusSources})
target_link_libraries(DBusUnixFDTest ${TEST_LINK_LIBRARIES})


##############################################################################
# DBusManagedTest
##############################################################################

add_executable(DBusManagedTest src/DBusManagedTest.cpp
                               ${ManagedDBusSources})
target_link_libraries(DBusManagedTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusMainLoopIntegrationTest
##############################################################################

add_executable(DBusMainLoopIntegrationTest src/DBusMainLoopIntegrationTest.cpp
                                           ${TestInterfaceDBusSources})
if (MSVC)
target_link_libraries(DBusMainLoopIntegrationTest ${TEST_LINK_LIBRARIES} ws2_32)
else()
target_link_libraries(DBusMainLoopIntegrationTest ${TEST_LINK_LIBRARIES} ${GLIB_LDFLAGS})
endif()

##############################################################################
# DBusAddressTranslatorTest
##############################################################################


add_executable(DBusAddressTranslatorTest src/DBusAddressTranslatorTest.cpp
                                         ${TestInterfaceDBusSources})

target_link_libraries(DBusAddressTranslatorTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusCommunicationTest
##############################################################################

add_executable(DBusCommunicationTest src/DBusCommunicationTest.cpp
                                     src/stubs/TestInterfaceStubImpl.cpp
                                     ${TestInterfaceDBusSources})

target_link_libraries(DBusCommunicationTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusInputStreamTest
##############################################################################

add_executable(DBusInputStreamTest src/DBusInputStreamTest.cpp
                                   ${TestInterfaceDBusSources})

target_link_libraries(DBusInputStreamTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusOutputStreamTest
##############################################################################


add_executable(DBusOutputStreamTest src/DBusOutputStreamTest.cpp
                                    ${TestInterfaceDBusSources})

target_link_libraries(DBusOutputStreamTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusFactoryTest
##############################################################################

add_executable(DBusFactoryTest src/DBusFactoryTest.cpp
                               ${TestInterfaceDBusSources})

target_link_libraries(DBusFactoryTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusMultipleConnectionTest
##############################################################################

add_executable(DBusMultipleConnectionTest src/DBusMultipleConnectionTest.cpp
                                          ${TestInterfaceDBusSources})

target_link_libraries(DBusMultipleConnectionTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusProxyTest
##############################################################################

add_executable(DBusProxyTest src/DBusProxyTest.cpp
                             ${TestInterfaceDBusSources}
                             ${ExtendedInterfaceDBusSources})

target_link_libraries(DBusProxyTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusFreedesktopPropertiesTest
##############################################################################

add_executable(DBusFreedesktopPropertiesTest src/DBusFreedesktopPropertiesTest.cpp
                                             ${TestInterfaceSources}
                                             ${FreedesktopPropertiesDBusSources})

target_link_libraries(DBusFreedesktopPropertiesTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusRuntimeTest
##############################################################################

add_executable(DBusRuntimeTest src/DBusRuntimeTest.cpp)

target_link_libraries(DBusRuntimeTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusBroadcastTest
##############################################################################

add_executable(DBusBroadcastTest ${TestInterfaceDBusSources}
                                 ${TestInterfaceManagerDBusSources}
                                 src/DBusBroadcastTest.cpp)

target_link_libraries(DBusBroadcastTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusPolymorphicTest
##############################################################################


add_executable(DBusPolymorphicTest ${TestInterfaceDBusSources}
                                   src/DBusPolymorphicTest.cpp)

target_link_libraries(DBusPolymorphicTest ${TEST_LINK_LIBRARIES})

##############################################################################
# DBusLoadTest
##############################################################################

add_executable(DBusLoadTest src/DBusLoadTest.cpp
                            ${TestInterfaceDBusSources})

target_link_libraries(DBusLoadTest ${TEST_LINK_LIBRARIES})

##############################################################################
# Add for every test a dependency to gtest
##############################################################################

add_dependencies(DBusManagedTest gtest)
add_dependencies(DBusMainLoopIntegrationTest gtest)
add_dependencies(DBusAddressTranslatorTest gtest)
add_dependencies(DBusCommunicationTest gtest)
add_dependencies(DBusInputStreamTest gtest)
add_dependencies(DBusOutputStreamTest gtest)
add_dependencies(DBusFactoryTest gtest)
add_dependencies(DBusMultipleConnectionTest gtest)
add_dependencies(DBusProxyTest gtest)
add_dependencies(DBusFreedesktopPropertiesTest gtest)
add_dependencies(DBusRuntimeTest gtest)
add_dependencies(DBusBroadcastTest gtest)
add_dependencies(DBusPolymorphicTest gtest)
add_dependencies(DBusLoadTest gtest)
add_dependencies(DBusObjectPathTest gtest)
add_dependencies(DBusUnixFDTest gtest)

##############################################################################
# Add tests to the target build_tests
##############################################################################

add_dependencies(build_tests DBusManagedTest)
add_dependencies(build_tests DBusMainLoopIntegrationTest)
add_dependencies(build_tests DBusAddressTranslatorTest)
add_dependencies(build_tests DBusCommunicationTest)
add_dependencies(build_tests DBusInputStreamTest)
add_dependencies(build_tests DBusOutputStreamTest)
add_dependencies(build_tests DBusFactoryTest)
add_dependencies(build_tests DBusMultipleConnectionTest)
add_dependencies(build_tests DBusProxyTest)
add_dependencies(build_tests DBusFreedesktopPropertiesTest)
add_dependencies(build_tests DBusRuntimeTest)
add_dependencies(build_tests DBusBroadcastTest)
add_dependencies(build_tests DBusPolymorphicTest)
add_dependencies(build_tests DBusLoadTest)
add_dependencies(build_tests DBusObjectPathTest)
add_dependencies(build_tests DBusUnixFDTest)

##############################################################################
# Add tests
##############################################################################

get_filename_component(INI_FILE commonapi4dbus.ini ABSOLUTE)
get_filename_component(TEST_INI_FILE test-commonapi-dbus.ini ABSOLUTE)
get_filename_component(PYTHON_TEST_DIR fakeLegacyService ABSOLUTE)

set(DBUS_COMMONAPI_CONFIG "COMMONAPI_CONFIG=${INI_FILE}")
set(DBUS_TEST_ENVIRONMENT
    ${DBUS_COMMONAPI_CONFIG}
)

add_test(NAME DBusManagedTest COMMAND DBusManagedTest)
set_property(TEST DBusManagedTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})
set_property(TEST DBusManagedTest APPEND PROPERTY ENVIRONMENT "COMMONAPI_DBUS_CONFIG=${TEST_INI_FILE}")

add_test(NAME DBusMainLoopIntegrationTest COMMAND DBusMainLoopIntegrationTest)
set_property(TEST DBusMainLoopIntegrationTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusAddressTranslatorTest WORKING_DIRECTORY ${libcommonapi-dbus_SOURCE_DIR} COMMAND DBusAddressTranslatorTest)
set_property(TEST DBusAddressTranslatorTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})
set_property(TEST DBusAddressTranslatorTest APPEND PROPERTY ENVIRONMENT "COMMONAPI_DBUS_CONFIG=${TEST_INI_FILE}")
set_property(TEST DBusAddressTranslatorTest APPEND PROPERTY ENVIRONMENT "TEST_COMMONAPI_DBUS_FAKE_LEGACY_SERVICE_FOLDER=${PYTHON_TEST_DIR}")

add_test(NAME DBusCommunicationTest COMMAND DBusCommunicationTest)
set_property(TEST DBusCommunicationTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusInputStreamTest COMMAND DBusInputStreamTest)
set_property(TEST DBusInputStreamTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusOutputStreamTest COMMAND DBusOutputStreamTest)
set_property(TEST DBusOutputStreamTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusFactoryTest COMMAND DBusFactoryTest)
set_property(TEST DBusFactoryTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusMultipleConnectionTest COMMAND DBusMultipleConnectionTest)
set_property(TEST DBusMultipleConnectionTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusProxyTest COMMAND DBusProxyTest)
set_property(TEST DBusProxyTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})
set_property(TEST DBusProxyTest APPEND PROPERTY ENVIRONMENT "TEST_COMMONAPI_DBUS_FAKE_LEGACY_SERVICE_FOLDER=${PYTHON_TEST_DIR}")

add_test(NAME DBusFreedesktopPropertiesTest COMMAND DBusFreedesktopPropertiesTest)
set_property(TEST DBusFreedesktopPropertiesTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusRuntimeTest COMMAND DBusRuntimeTest)
set_property(TEST DBusRuntimeTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusBroadcastTest COMMAND DBusBroadcastTest)
set_property(TEST DBusBroadcastTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusPolymorphicTest COMMAND DBusPolymorphicTest)
set_property(TEST DBusPolymorphicTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusLoadTest COMMAND DBusLoadTest)
set_property(TEST DBusLoadTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusObjectPathTest COMMAND DBusObjectPathTest)
set_property(TEST DBusObjectPathTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

add_test(NAME DBusUnixFDTest COMMAND DBusUnixFDTest)
set_property(TEST DBusUnixFDTest APPEND PROPERTY ENVIRONMENT ${DBUS_TEST_ENVIRONMENT})

message("TEST_COMMONAPI_DBUS_FAKE_LEGACY_SERVICE_FOLDER: = ${PYTHON_TEST_DIR}")
