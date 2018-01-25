#!/bin/sh
rm -rf src-gen
rm -rf build
mkdir build
cd build/

export PKG_CONFIG_PATH=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus/patched-dbus/lib/pkgconfig/)
export LD_LIBRARY_PATH=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus/patched-dbus/lib)
export LIBRARY_PATH=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus/patched-dbus/lib)

cmake \
-DCOMMONAPI_TOOL_GENERATOR=$(readlink -f ../../../ascgit017.CommonAPI-Tools/org.genivi.commonapi.core.cli.product/target/products/org.genivi.commonapi.core.cli.product/linux/gtk/x86_64/commonapi-generator-linux-x86_64) \
-DCOMMONAPI_DBUS_TOOL_GENERATOR=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus-Tools/org.genivi.commonapi.dbus.cli.product/target/products/org.genivi.commonapi.dbus.cli.product/linux/gtk/x86_64/commonapi-dbus-generator-linux-x86_64) \
-DCommonAPI_DIR=$(readlink -f ../../../ascgit017.CommonAPI/build) \
-DCommonAPI-DBus_DIR=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus/build) \
-DCOMMONAPI_TEST_FIDL_PATH=$(readlink -f ../../../ascgit017.CommonAPI-Tools/org.genivi.commonapi.core.verification/fidl) \
..

make