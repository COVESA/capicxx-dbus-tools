ACLOCAL_AMFLAGS = -I m4

#SUBDIRS=src
#verify_SOURCES = \
#		src/org.genivi.commonapi.core.verification.cpp

AM_CPPFLAGS = \
        -I$(top_srcdir)/src \
        -I$(includedir) \
        -Isrc-gen \
        ${COMMONAPI_CFLAGS} \
        ${DBUS_CFLAGS} \
        ${COMMONAPI_DBUS_CFLAGS} \
        ${GTEST_CPPFLAGS}

LD_ADD = \
		${COMMONAPI_DBUS_LIBS}


#bin_PROGRAMS = \
#		test-proxy \
#		test-interface-stub

		
test_proxy_FILES = \
		src-gen/commonapi/tests/PredefinedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.cpp \
		src-gen/commonapi/tests/TestInterface.h \
		src-gen/commonapi/tests/TestInterfaceProxy.h \
		src-gen/commonapi/tests/TestInterfaceProxyBase.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.cpp

		
#test_proxy_LDADD = ${LDADD}  ${GMOCK_LIBS}
#test_proxy_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
#test_proxy_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}

lib_LTLIBRARIES = libDBusGlue.la

libDBusGlue_la_SOURCES = \
		src-gen/commonapi/tests/PredefinedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.h \
		src-gen/commonapi/tests/DerivedTypeCollection.cpp \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.h \
		src-gen/commonapi/tests/TestInterfaceDBusStubAdapter.cpp \
		src-gen/commonapi/tests/TestInterfaceStubDefault.h \
		src-gen/commonapi/tests/TestInterfaceStubDefault.cpp \
		src-gen/commonapi/tests/TestInterface.h \
		src-gen/commonapi/tests/TestInterfaceProxy.h \
		src-gen/commonapi/tests/TestInterfaceProxyBase.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.h \
		src-gen/commonapi/tests/TestInterfaceDBusProxy.cpp

#test_interface_stub_LDADD = ${LDADD} ${GMOCK_LIBS}
#test_interface_stub_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
#test_interface_stub_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}


#libDBusGlue_la_SOURCES = ${test_proxy_FILES} ${test_interface_stub_FILES}
libDBusGlue_la_LIBADD = ${LDADD} ${GMOCK_LIBS}
libDBusGlue_la_CPPFLAGS = ${AM_CPPFLAGS} ${GMOCK_CPPFLAGS} ${GTEST_CPPFLAGS}
libDBusGlue_la_CXXFLAGS = ${GMOCK_CXXFLAGS} ${GETST_CXXFLAGS}
libDBusGlue_la_LDFLAGS = -lCommonAPI-DBus
