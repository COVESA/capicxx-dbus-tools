This file contains information for executing the CommonAPI-D-Bus unit tests.

Required environment variables:
-------------------------------
LD_LIBRARY_PATH should contain the folder where the patched dbus libraries are.

export LD_LIBRARY_PATH=$HOME/git/ascgit017.CommonAPI-D-Bus/patched-dbus/lib:$HOME/git/ascgit017.CommonAPI-D-Bus/build/src/test

PKG_CONFIG_PATH should contain the folder where the pkg-config file for the patched lib dbus is.

export PKG_CONFIG_PATH=$HOME/git/ascgit017.CommonAPI-D-Bus/patched-dbus/lib/pkgconfig:$PKG_CONFIG_PATH

Building and executing the tests:
----------------------------------
You need:
1) The CommonAPI library
2) The CommonAPI-D-Bus library
3) The generator tool for CommonAPI. The cmake option -DCOMMONAPI_TOOL_GENERATOR needs to point to the executable.
4) The generator tool for CommonAPI-D-Bus. The cmake option -DCOMMONAPI_DBUS_TOOL_GENERATOR needs to point to the executable.
5) Google test (GTEST) framework. You need to have the enviroment variable GTEST_ROOT point to your installed framework.
6) GLIB.

Steps for building:

export GTEST_ROOT=$YOUR_PATH_HERE/gtest-1.7.0/

rm -rf build
rm -rf src-gen
mkdir build
cd build
cmake \
-DCommonAPI_DIR=$(readlink -f ../../../ascgit017.CommonAPI/build) \
-DCommonAPI-DBus_DIR=$(readlink -f ../../../ascgit017.CommonAPI-D-Bus/build) \
-DCOMMONAPI_TOOL_GENERATOR=$(readlink -f ../../../ascgit017.CommonAPI-Tools/org.genivi.commonapi.core.cli.product/target/products/org.genivi.commonapi.core.cli.product/linux/gtk/x86_64/commonapi-generator-linux-x86_64) \
-DCOMMONAPI_DBUS_TOOL_GENERATOR=$(readlink -f ../../org.genivi.commonapi.dbus.cli.product/target/products/org.genivi.commonapi.dbus.cli.product/linux/gtk/x86_64/commonapi-dbus-generator-linux-x86_64) \
..

make
ctest -V
