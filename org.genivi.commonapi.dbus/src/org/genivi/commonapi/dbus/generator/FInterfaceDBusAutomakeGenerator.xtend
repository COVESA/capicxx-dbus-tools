package org.genivi.commonapi.dbus.generator

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMapType
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FUnionType

class FInterfaceDBusAutomakeGenerator {
 
    /* @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

    def generateDBusAutomake(FInterface fInterface, IFileSystemAccess fileSystemAccess) {
        fileSystemAccess.generateFile(fInterface.dbusAutomakeAutogenPath, fInterface.generateAutogen)
        fileSystemAccess.generateFile(fInterface.dbusAutomakeMacroPath, fInterface.generateMakroAdditions)
        fileSystemAccess.generateFile(fInterface.dbusAutomakeConfigurePath, fInterface.generateConfig)
        fileSystemAccess.generateFile(fInterface.dbusAutomakeMakefilePath, fInterface.generateMakefile)
    }
    
    def private generateAutogen(FInterface fInterface) '''
        #! /bin/sh

        [ -e config.cache ] && rm -f config.cache

        libtoolize --automake
        aclocal -I m4 ${OECORE_ACLOCAL_OPTS}
        autoconf
        autoheader
        automake -a
        ./configure $@

        exit
    '''

    def private generateMakefile(FInterface fInterface) '''
        EXTRA_DIST = autogen.sh

        AM_CXXFLAGS = ${COMMON_API_CFLAGS}
        AM_LDFLAGS = ${COMMON_API_LIBS}

        CLEANFILES = *~

        MAINTAINERCLEANFILES = aclocal.m4 compile config.guess \
                               config.sub configure depcomp install-sh \
                               ltmain.sh Makefile.in missing \
                               config.h config.h.in \
                               *-poky-linux-libtool

        «val includes = fInterface.generateTypeIncludes»
        Typedefs =«IF includes.length > 0» \«ENDIF»
            «includes»

        bin_PROGRAMS = \
            bin/«fInterface.clientName» \
            bin/«fInterface.providerName»


        bin_«fInterface.clientName»_SOURCES = \
            ${Typedefs} \
            «fInterface.generateClientSourceIncludes»

        bin_«fInterface.providerName»_SOURCES = \
            ${Typedefs} \
            «fInterface.generateProviderSourceIncludes»

        bin_«fInterface.clientName»_LDADD = ${COMMON_API_LIBS}
        bin_«fInterface.clientName»_CPPFLAGS = ${COMMON_API_CFLAGS}

        bin_«fInterface.providerName»_LDADD = ${COMMON_API_LIBS}
        bin_«fInterface.providerName»_CPPFLAGS = ${COMMON_API_CFLAGS}
    '''
    
    def private dbusAutomakeAutogenPath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusAutomakeAutogenFile
    }

    def private dbusAutomakeAutogenFile(FInterface fInterface) {
        "/autogen.sh"
    }
    
    def private dbusAutomakeMacroPath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusMacroAutogenFile
    }

    def private dbusAutomakeMacroFile(FInterface fInterface) {
        "/m4/ax_cxx_compile_stdcxx_0x.m4"
    }
    
    def private dbusAutomakeConfigurePath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusAutomakeConfigureFile
    }

    def private dbusAutomakeConfigureFile(FInterface fInterface) {
        "/configure.ac"
    }
    
    def private dbusAutomakeMakefilePath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusAutomakeMakefileFile
    }

    def private dbusAutomakeMakefileFile(FInterface fInterface) {
        "/Makefile.am"
    }
 
    def private generateClientSourceIncludes(FInterface fInterface) '''
        «skeletonFolderPath + fInterface.clientAsSourceFileName» \
        «fInterface.generateClientSourceIncludesHelper»
    '''

    def private generateClientSourceIncludesHelper(FInterface fInterface) '''
        «IF fInterface.base != null»«fInterface.base.generateClientSourceIncludesHelper» \«ENDIF»
        «fInterface.absoluteFolderPathAsArray.join("/")»/«fInterface.proxyClassName.asSourceFileName»'''


    def private generateProviderSourceIncludes(FInterface fInterface) '''
        «skeletonFolderPath + fInterface.providerAsSourceFileName» \
        «fInterface.generateProviderSourceIncludesHelper» \
        «fInterface.generateProviderSourceSkeletonIncludesHelper»
    '''

    def private generateProviderSourceIncludesHelper(FInterface fInterface) '''
        «IF fInterface.base != null»«fInterface.base.generateProviderSourceIncludesHelper» \«ENDIF»
        «fInterface.absoluteFolderPathAsArray.join("/")»/«fInterface.interfaceAdapterClassName.asSourceFileName»'''
        
    def private generateProviderSourceSkeletonIncludesHelper(FInterface fInterface) '''
        «IF fInterface.base != null»«fInterface.base.generateProviderSourceSkeletonIncludesHelper(skeletonFolderPath)» \«ENDIF»
        «skeletonFolderPath»«fInterface.interfaceImplementationSkeletonClassName.asSourceFileName»'''

    def private generateTypeIncludes(FInterface fInterface) {
        var includes = new HashSet<String>()
        includes.addAll(listOfInterfaces.map[it.generateTypeIncludesHelper].flatten)
        return includes.filter[!it.equals("")].sort.join(" \\\n")
    }

    def private generateTypeIncludesHelper(FInterface fInterface) {
        var includes = new HashSet<String>()
        if(fInterface.base != null) {
            includes.addAll(fInterface.base.generateTypeIncludesHelper)
        }
        includes.addAll(fInterface.typeIncludes)
        return includes
    }

    def private dispatch HashSet<String> getTypeIncludes(FInterface fInterface) {
        var includes = new HashSet<String>()

        includes.addAll(fInterface.types.map[typeIncludes].flatten)
        includes.addAll(fInterface.attributes.map[type].map[typeIncludes].flatten)
        includes.addAll(fInterface.broadcasts.map[outArgs.map[type].map[typeIncludes].flatten].flatten)
        for(fMethod: fInterface.methods) {
            includes.addAll(fMethod.inArgs.map[type].map[typeIncludes].flatten)
            if(fMethod.hasErrors) {
                includes.addAll(fMethod.errors.typeIncludes)
            }
            includes.addAll(fMethod.outArgs.map[type].map[typeIncludes].flatten)
        }
        
        return includes
    }
    
    def private dispatch HashSet<String> getTypeIncludes(FTypeRef typeRef) {
        if(typeRef.derived != null) {
            return typeRef.derived.typeIncludes
        }
        return new HashSet<String>()
    }

    def private dispatch HashSet<String> getTypeIncludes(FType type) {
        var includes = new HashSet<String>()
        if(type == null) {
            return includes
        }
        val folderPath = type.absoluteFolderPathAsArray.join("/") + "/"

        if(type instanceof FUnionType) {
            val fUnion = (type as FUnionType)
            includes.add(folderPath + fUnion.asSourceFileName)
            includes.addAll(fUnion.elements.map[it.type].map[typeIncludes].flatten)
            if(fUnion.base != null) {
                includes.addAll(fUnion.base.typeIncludes)
            }
        }

        if(type instanceof FStructType) {
            val fStruct = type as FStructType
            includes.add(folderPath + fStruct.asSourceFileName)
            includes.addAll(fStruct.elements.map[it.type].map[typeIncludes].flatten)
            if(fStruct.base != null) {
                includes.addAll(fStruct.base.typeIncludes)
            }
        }

        if(type instanceof FArrayType) {
            val fArray = type as FArrayType
            includes.addAll(fArray.elementType.typeIncludes)
        }

        if(type instanceof FMapType) {
            val fMap = type as FMapType
            includes.addAll(fMap.keyType.typeIncludes)
            includes.addAll(fMap.valueType.typeIncludes)
        }

        if(type instanceof FTypeDef) {
            val fTypedef = type as FTypeDef
            includes.addAll(fTypedef.actualType.typeIncludes)
        }

        return includes
    }

    def private generateConfig(FInterface fInterface) '''
        AC_PREREQ(2.61)

        AC_INIT(«fInterface.getProjectName», 1)
        AM_INIT_AUTOMAKE([foreign 1.11 -Wall silent-rules subdir-objects])

        # Checks for programs
        AC_PROG_LIBTOOL
        AC_PROG_CXX
        AC_LANG([C++])

        AX_CXX_COMPILE_STDCXX_0X
        if test "x$ax_cv_cxx_compile_cxx0x_gxx" = xyes; then
                CXXFLAGS="$CXXFLAGS -std=gnu++0x"
        elif test "x$ax_cv_cxx_compile_cxx0x_cxx" = xyes; then
                CXXFLAGS="$CXXFLAGS -std=c++0x"
        fi

        AC_PROG_INSTALL

        dnl Switch if your target is a platform with no pkg-config available.
        PKG_CHECK_MODULES(COMMON_API, [common-api-dbus])
        dnl AM_LDFLAGS = "-L${top_builddir} -lcommon-api-dbus -ldbus-1 -lpthread -lrt"

        AC_CONFIG_HEADERS([config.h])
        AC_CONFIG_FILES([
            Makefile
        ])

        AC_OUTPUT

        AC_MSG_RESULT([
                ${PACKAGE_NAME}, version ${VERSION}

                CXXFLAGS:                ${CXXFLAGS}
                LDFLAGS:                 ${LDFLAGS}
                CFLAGS:                  ${COMMON_API_CFLAGS}
                LIBS:                    ${COMMON_API_LIBS}
                TOP BUILDDIR:            ${top_builddir}
        ])
    '''
    
    def private getProjectName(FInterface fInterface) {
        return fInterface.model.name.replace(".", "-")
    }

    def private generateMakroAdditions(FInterface fInterface) '''
        # ============================================================================
        #  http://www.gnu.org/software/autoconf-archive/ax_cxx_compile_stdcxx_0x.html
        # ============================================================================
        #
        # SYNOPSIS
        #
        #   AX_CXX_COMPILE_STDCXX_0X
        #
        # DESCRIPTION
        #
        #   Check for baseline language coverage in the compiler for the C++0x
        #   standard.
        #
        # LICENSE
        #
        #   Copyright (c) 2008 Benjamin Kosnik <bkoz@redhat.com>
        #
        #   Copying and distribution of this file, with or without modification, are
        #   permitted in any medium without royalty provided the copyright notice
        #   and this notice are preserved. This file is offered as-is, without any
        #   warranty.
        
        #serial 7
        
        AU_ALIAS([AC_CXX_COMPILE_STDCXX_0X], [AX_CXX_COMPILE_STDCXX_0X])
        AC_DEFUN([AX_CXX_COMPILE_STDCXX_0X], [
          AC_CACHE_CHECK(if g++ supports C++0x features without additional flags,
          ax_cv_cxx_compile_cxx0x_native,
          [AC_LANG_SAVE
          AC_LANG_CPLUSPLUS
          AC_TRY_COMPILE([
          template <typename T>
            struct check
            {
              static_assert(sizeof(int) <= sizeof(T), "not big enough");
            };
        
            typedef check<check<bool>> right_angle_brackets;
        
            int a;
            decltype(a) b;
        
            typedef check<int> check_type;
            check_type c;
            check_type&& cr = static_cast<check_type&&>(c);],,
          ax_cv_cxx_compile_cxx0x_native=yes, ax_cv_cxx_compile_cxx0x_native=no)
          AC_LANG_RESTORE
          ])
        
          AC_CACHE_CHECK(if g++ supports C++0x features with -std=c++0x,
          ax_cv_cxx_compile_cxx0x_cxx,
          [AC_LANG_SAVE
          AC_LANG_CPLUSPLUS
          ac_save_CXXFLAGS="$CXXFLAGS"
          CXXFLAGS="$CXXFLAGS -std=c++0x"
          AC_TRY_COMPILE([
          template <typename T>
            struct check
            {
              static_assert(sizeof(int) <= sizeof(T), "not big enough");
            };
        
            typedef check<check<bool>> right_angle_brackets;
        
            int a;
            decltype(a) b;
        
            typedef check<int> check_type;
            check_type c;
            check_type&& cr = static_cast<check_type&&>(c);],,
          ax_cv_cxx_compile_cxx0x_cxx=yes, ax_cv_cxx_compile_cxx0x_cxx=no)
          CXXFLAGS="$ac_save_CXXFLAGS"
          AC_LANG_RESTORE
          ])
        
          AC_CACHE_CHECK(if g++ supports C++0x features with -std=gnu++0x,
          ax_cv_cxx_compile_cxx0x_gxx,
          [AC_LANG_SAVE
          AC_LANG_CPLUSPLUS
          ac_save_CXXFLAGS="$CXXFLAGS"
          CXXFLAGS="$CXXFLAGS -std=gnu++0x"
          AC_TRY_COMPILE([
          template <typename T>
            struct check
            {
              static_assert(sizeof(int) <= sizeof(T), "not big enough");
            };
        
            typedef check<check<bool>> right_angle_brackets;
        
            int a;
            decltype(a) b;
        
            typedef check<int> check_type;
            check_type c;
            check_type&& cr = static_cast<check_type&&>(c);],,
          ax_cv_cxx_compile_cxx0x_gxx=yes, ax_cv_cxx_compile_cxx0x_gxx=no)
          CXXFLAGS="$ac_save_CXXFLAGS"
          AC_LANG_RESTORE
          ])
        
          if test "$ax_cv_cxx_compile_cxx0x_native" = yes ||
             test "$ax_cv_cxx_compile_cxx0x_cxx" = yes ||
             test "$ax_cv_cxx_compile_cxx0x_gxx" = yes; then
            AC_DEFINE(HAVE_STDCXX_0X,,[Define if g++ supports C++0x features. ])
          fi
        ])
    ''' */
}