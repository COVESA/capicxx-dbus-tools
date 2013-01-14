/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions

class FInterfaceDBusStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

	def generateDBusStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess) {
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterHeaderPath, fInterface.generateDBusStubAdapterHeader)
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterSourcePath, fInterface.generateDBusStubAdapterSource)
	}

    def private generateDBusStubAdapterHeader(FInterface fInterface) '''
        «generateCommonApiLicenseHeader»
        #ifndef «fInterface.defineName»_DBUS_STUB_ADAPTER_H_
        #define «fInterface.defineName»_DBUS_STUB_ADAPTER_H_

        #include <«fInterface.stubHeaderPath»>

        #include <CommonAPI/DBus/DBusStubAdapterHelper.h>
        #include <CommonAPI/DBus/DBusFactory.h>

        «fInterface.model.generateNamespaceBeginDeclaration»

        typedef CommonAPI::DBus::DBusStubAdapterHelper<«fInterface.stubClassName»> «fInterface.dbusStubAdapterHelperClassName»;

        class «fInterface.dbusStubAdapterClassName»: public «fInterface.stubAdapterClassName», public «fInterface.dbusStubAdapterHelperClassName» {
         public:
            «fInterface.dbusStubAdapterClassName»(
                    const std::string& dbusBusName,
                    const std::string& dbusObjectPath,
                    const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusConnection,
                    const std::shared_ptr<CommonAPI::StubBase>& stub);
            
            «FOR attribute : fInterface.attributes»
                «IF attribute.isObservable»
                    void «attribute.stubAdapterClassFireChangedMethodName»(const «attribute.type.getNameReference(fInterface.model)»& value);
                «ENDIF»
            «ENDFOR»
        
            «FOR broadcast: fInterface.broadcasts»
                void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + type.getNameReference(fInterface.model) + '& ' + name].join(', ')»);
            «ENDFOR»

         protected:
            virtual const char* getMethodsDBusIntrospectionXmlData() const;
        };

        «fInterface.model.generateNamespaceEndDeclaration»

        #endif // «fInterface.defineName»_DBUS_STUB_ADAPTER_H_
    '''

    def private generateDBusStubAdapterSource(FInterface fInterface) '''
        «generateCommonApiLicenseHeader»
        #include "«fInterface.dbusStubAdapterHeaderFile»"
        #include <«fInterface.headerPath»>

        «fInterface.model.generateNamespaceBeginDeclaration»
        
        std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> create«fInterface.dbusStubAdapterClassName»(std::string busName,
                                                                   std::string objectPath,
                                                                   std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> dbusProxyConnection,
                                                                   std::shared_ptr<CommonAPI::StubBase> stubBase) {
            return std::make_shared<«fInterface.dbusStubAdapterClassName»>(busName, objectPath, dbusProxyConnection, stubBase);
        }

        __attribute__((constructor)) void register«fInterface.dbusStubAdapterClassName»(void) {
            CommonAPI::DBus::DBusFactory::registerAdapterFactoryMethod(«fInterface.name»::getInterfaceName(),
                                                                       &create«fInterface.dbusStubAdapterClassName»);
        }

        «fInterface.dbusStubAdapterClassName»::«fInterface.dbusStubAdapterClassName»(
                const std::string& dbusBusName,
                const std::string& dbusObjectPath,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusConnection,
                const std::shared_ptr<CommonAPI::StubBase>& stub):
                «fInterface.dbusStubAdapterHelperClassName»(dbusBusName, dbusObjectPath, «fInterface.name»::getInterfaceName(), dbusConnection, std::dynamic_pointer_cast<«fInterface.stubClassName»>(stub)) {
        }

        const char* «fInterface.dbusStubAdapterClassName»::getMethodsDBusIntrospectionXmlData() const {
            return
                «FOR attribute : fInterface.attributes»
                    "<method name=\"«attribute.dbusGetMethodName»\">\n"
                    	"<arg name=\"value\" type=\"«attribute.dbusSignature»\" direction=\"out\" />"
                    "</method>\n"
                    «IF !attribute.isReadonly»
                        "<method name=\"«attribute.dbusSetMethodName»\">\n"
                            "<arg name=\"requestedValue\" type=\"«attribute.dbusSignature»\" direction=\"in\" />\n"
                            "<arg name=\"setValue\" type=\"«attribute.dbusSignature»\" direction=\"out\" />\n"
                        "</method>\n"
                    «ENDIF»
                    «IF attribute.isObservable»
                        "<signal name=\"«attribute.dbusSignalName»\">\n"
                            "<arg name=\"changedValue\" type=\"«attribute.dbusSignature»\" />\n"
                        "</signal>\n"
                    «ENDIF»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts»
                    "<signal name=\"«broadcast.name»\">\n"
                        «FOR outArg : broadcast.outArgs»
                            "<arg name=\"«outArg.name»\" type=\"«outArg.type.dbusSignature»\" />\n"
                        «ENDFOR»
                    "</signal>\n"
                «ENDFOR»
                «FOR method : fInterface.methods»
                    "<method name=\"«method.name»\">\n"
                        «FOR inArg : method.inArgs»
                            "<arg name=\"«inArg.name»\" type=\"«inArg.type.dbusSignature»\" direction=\"in\" />\n"
                        «ENDFOR»
                    	«IF method.hasError»
                    		"<arg name=\"methodError\" type=\"«method.dbusErrorSignature»\" direction=\"out\" />\n"
                    	«ENDIF»
                        «FOR outArg : method.outArgs»
                            "<arg name=\"«outArg.name»\" type=\"«outArg.type.dbusSignature»\" direction=\"out\" />\n"
                        «ENDFOR»
                    "</method>\n"
                «ENDFOR»
            ;
        }


        «FOR attribute : fInterface.attributes»
            static CommonAPI::DBus::DBusGetAttributeStubDispatcher<
                    «fInterface.stubClassName»,
                    «attribute.type.getNameReference(fInterface.model)»
                    > «attribute.dbusGetStubDispatcherVariable»(&«fInterface.stubClassName»::«attribute.stubClassGetMethodName», "«attribute.dbusSignature»");
            «IF !attribute.isReadonly»
                static CommonAPI::DBus::DBusSet«IF attribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                        «fInterface.stubClassName»,
                        «attribute.type.getNameReference(fInterface.model)»
                        > «attribute.dbusSetStubDispatcherVariable»(
                                &«fInterface.stubClassName»::«attribute.stubClassGetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«attribute.stubRemoteEventClassSetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«attribute.stubRemoteEventClassChangedMethodName»,
                                «IF attribute.observable»&«fInterface.stubAdapterClassName»::«attribute.stubAdapterClassFireChangedMethodName»,«ENDIF»
                                "«attribute.dbusSignature»");
            «ENDIF»
            
        «ENDFOR»
        
        «FOR method : fInterface.methods»
            «IF !method.isFireAndForget»
                static CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>,
                    std::tuple<«method.allOutTypes»>
                    > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature»");
            «ELSE»
                static CommonAPI::DBus::DBusMethodStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>
                    > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature»");
            «ENDIF»
            
        «ENDFOR»

        template<>
        const «fInterface.dbusStubAdapterHelperClassName»::StubDispatcherTable «fInterface.dbusStubAdapterHelperClassName»::stubDispatcherTable_ = {
            «FOR attribute : fInterface.attributes SEPARATOR ','»
                { { "«attribute.dbusGetMethodName»", "" }, &«fInterface.absoluteNamespace»::«attribute.dbusGetStubDispatcherVariable» }
                «IF !attribute.isReadonly»
                    , { { "«attribute.dbusSetMethodName»", "«attribute.dbusSignature»" }, &«fInterface.absoluteNamespace»::«attribute.dbusSetStubDispatcherVariable» }
                «ENDIF»
            «ENDFOR»
            «IF !fInterface.attributes.empty && !fInterface.methods.empty»,«ENDIF»
            «FOR method : fInterface.methods SEPARATOR ','»
                { { "«method.name»", "«method.dbusInSignature»" }, &«fInterface.absoluteNamespace»::«method.dbusStubDispatcherVariable» }
            «ENDFOR»
        };

        «FOR attribute : fInterface.attributes»
            «IF attribute.isObservable»
                void «fInterface.dbusStubAdapterClassName»::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.type.getNameReference(fInterface.model)»& value) {
                	CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«attribute.type.getNameReference(fInterface.model)»>>
                        ::sendSignal(
                            *this,
                            "«attribute.dbusSignalName»",
                            "«attribute.dbusSignature»",
                            value
                    );
                }
            «ENDIF»
        «ENDFOR»

        «FOR broadcast: fInterface.broadcasts»
            void «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + type.getNameReference(fInterface.model) + '& ' + name].join(', ')») {
                CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«broadcast.outArgs.map[type.getNameReference(fInterface.model)].join(', ')»>>
                        ::sendSignal(
                            *this,
                            "«broadcast.name»",
                            "«broadcast.dbusSignature»",
                            «broadcast.outArgs.map[name].join(', ')»
                    );
            }
        «ENDFOR»

        «fInterface.model.generateNamespaceEndDeclaration»
    '''

    def private getAbsoluteNamespace(FModelElement fModelElement) {
        fModelElement.model.name.replace('.', '::')
    }

    def private dbusStubAdapterHeaderFile(FInterface fInterface) {
        fInterface.name + "DBusStubAdapter.h"
    }

    def private dbusStubAdapterHeaderPath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusStubAdapterHeaderFile
    }

    def private dbusStubAdapterSourceFile(FInterface fInterface) {
        fInterface.name + "DBusStubAdapter.cpp"
    }

    def private dbusStubAdapterSourcePath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusStubAdapterSourceFile
    }

    def private dbusStubAdapterClassName(FInterface fInterface) {
        fInterface.name + 'DBusStubAdapter'
    }

    def private dbusStubAdapterHelperClassName(FInterface fInterface) {
        fInterface.name + 'DBusStubAdapterHelper'
    }

    def private getAllInTypes(FMethod fMethod) {
        fMethod.inArgs.map[type.getNameReference(fMethod)].join(', ')
    }

    def private getAllOutTypes(FMethod fMethod) {
        var types = fMethod.outArgs.map[type.getNameReference(fMethod)].join(', ')

        if (fMethod.hasError) {
            if (!fMethod.outArgs.empty)
                types = ', ' + types
            types = fMethod.getErrorNameReference(fMethod.eContainer) + types
        }

        return types
    }

    def private dbusStubDispatcherVariable(FMethod fMethod) {
        fMethod.name.toFirstLower + 'StubDispatcher'
    }

    def private dbusGetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.dbusGetMethodName + 'StubDispatcher'
    }

    def private dbusSetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.dbusSetMethodName + 'StubDispatcher'
    }
}