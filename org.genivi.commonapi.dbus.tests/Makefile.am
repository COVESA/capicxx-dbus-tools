ACLOCAL_AMFLAGS = -I m4

AM_CPPFLAGS = \
		${COMMONAPI_DBUS_CFLAGS} \
		${GMOCK_CPPFLAGS} \
		-Isrc-gen
AM_CXXFLAGS = \
		${GMOCK_CXXFLAGS}
AM_LDFLAGS = \
		${GMOCK_LDFLAGS}
LDADD = \
		${COMMONAPI_DBUS_LIBS} \
		${GMOCK_LIBS}

lib_LTLIBRARIES =

# ------------------------------------------------------------------------------
lib_LTLIBRARIES += libcommonapi-tests-PredefinedTypeCollection.la

libcommonapi_tests_PredefinedTypeCollection_la_SOURCES = \
		src-gen/commonapi/tests/PredefinedTypeCollection.h

# ------------------------------------------------------------------------------
lib_LTLIBRARIES += libcommonapi-tests-DerivedTypeCollection.la

libcommonapi_tests_DerivedTypeCollection_la_SOURCES = \
		src-gen/commonapi/tests/DerivedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.cpp
libcommonapi_tests_DerivedTypeCollection_la_LIBADD = \
		libcommonapi-tests-PredefinedTypeCollection.la

# ------------------------------------------------------------------------------
lib_LTLIBRARIES += libcommonapi-tests-TestInterface.la

libcommonapi_tests_TestInterface_la_SOURCES = \
		src-gen/commonapi/tests/TestInterface.h \
		src-gen/commonapi/tests/TestInterfaceProxy.h \
		src-gen/commonapi/tests/TestInterfaceProxyBase.h
libcommonapi_tests_TestInterface_la_LIBADD = \
		libcommonapi-tests-PredefinedTypeCollection.la \
		libcommonapi-tests-DerivedTypeCollection.la

# ------------------------------------------------------------------------------
lib_LTLIBRARIES += libcommonapi-tests-TestInterfaceDBusProxy.la

libcommonapi_tests_TestInterfaceDBusProxy_la_SOURCES = \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.cpp
libcommonapi_tests_TestInterfaceDBusProxy_la_LIBADD = libcommonapi-tests-TestInterface.la

# ------------------------------------------------------------------------------
lib_LTLIBRARIES += libcommonapi-tests-TestInterfaceDBusStubAdapter.la

libcommonapi_tests_TestInterfaceDBusStubAdapter_la_SOURCES = \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.h \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.cpp \
		src-gen/commonapi/tests/TestInterfaceStubDefault.h \
		src-gen/commonapi/tests/TestInterfaceStubDefault.cpp
libcommonapi_tests_TestInterfaceDBusStubAdapter_la_LIBADD = libcommonapi-tests-TestInterface.la

# ------------------------------------------------------------------------------
check_PROGRAMS = \
		test-proxy \
		test-interface-stub

test_proxy_SOURCES = src/test-proxy.cpp
test_proxy_LDADD = ${LDADD}  ${GMOCK_LIBS} libcommonapi-tests-TestInterfaceDBusProxy.la
test_proxy_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_proxy_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

test_interface_stub_SOURCES = src/test-interface-stub.cpp
test_interface_stub_LDADD = ${LDADD} ${GMOCK_LIBS} libcommonapi-tests-TestInterfaceDBusStubAdapter.la
test_interface_stub_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_interface_stub_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

TESTS = ${check_PROGRAMS}
bin_PROGRAMS = ${check_PROGRAMS}

# ------------------------------------------------------------------------------
MAINTAINERCLEANFILES = \
		Makefile.in \
		aclocal.m4 \
		configure

maintainer-clean-local:
	-rm -rf src-gen
	-rm -rf build-aux
	-rm -f config.h.in*
	-rm -f m4/libtool*.m4
	-rm -f m4/lt*.m4
