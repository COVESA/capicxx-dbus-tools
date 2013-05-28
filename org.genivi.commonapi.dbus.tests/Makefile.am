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

check_PROGRAMS = \
		test-proxy \
		test-interface-stub \
		test-polymorphic-interface-proxy \
		test-polymorphic-interface-stub

test_proxy_SOURCES = src/test-proxy.cpp src-gen/commonapi/tests/PredefinedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.cpp \
		src-gen/commonapi/tests/TestInterface.h \
		src-gen/commonapi/tests/TestInterfaceProxy.h \
		src-gen/commonapi/tests/TestInterfaceProxyBase.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.cpp \
		src-gen/test/bmw/TestDBusProxy.cpp \
		src-gen/test/bmw/Test.cpp
		
test_proxy_LDADD = ${LDADD}  ${GMOCK_LIBS}
test_proxy_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_proxy_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

test_interface_stub_SOURCES = src/test-interface-stub.cpp src-gen/commonapi/tests/PredefinedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.cpp \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.h \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.cpp \
		src-gen/commonapi/tests/TestInterfaceStubDefault.h \
		src-gen/commonapi/tests/TestInterfaceStubDefault.cpp \
		src-gen/test/bmw/TestStubDefault.cpp \
		src-gen/test/bmw/TestDBusStubAdapter.cpp \
		src-gen/test/bmw/Test.cpp
test_interface_stub_LDADD = ${LDADD} ${GMOCK_LIBS}
test_interface_stub_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_interface_stub_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

test_polymorphic_interface_proxy_SOURCES = \
		src/test-polymorphic-interface-proxy.cpp \
		src-gen/commonapi/tests/TestPolymorphicInterface.h \
		src-gen/commonapi/tests/TestPolymorphicInterface.cpp \
		src-gen/commonapi/tests/TestPolymorphicInterfaceProxyBase.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceProxy.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceDBusProxy.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceDBusProxy.cpp
test_polymorphic_interface_proxy_LDADD = ${LDADD} ${GMOCK_LIBS}
test_polymorphic_interface_proxy_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_polymorphic_interface_proxy_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

test_polymorphic_interface_stub_SOURCES = \
		src/test-polymorphic-interface-stub.cpp \
		src-gen/commonapi/tests/TestPolymorphicInterface.h \
		src-gen/commonapi/tests/TestPolymorphicInterface.cpp \
		src-gen/commonapi/tests/TestPolymorphicInterfaceStub.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceStubDefault.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceStubDefault.cpp \
		src-gen/commonapi/tests/TestPolymorphicInterfaceDBusStubAdapter.h \
		src-gen/commonapi/tests/TestPolymorphicInterfaceDBusStubAdapter.cpp
test_polymorphic_interface_stub_LDADD = ${LDADD} ${GMOCK_LIBS}
test_polymorphic_interface_stub_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
test_polymorphic_interface_stub_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

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
