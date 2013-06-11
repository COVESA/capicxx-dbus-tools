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
import org.genivi.commonapi.core.deployment.DeploymentInterfacePropertyAccessor

class FInterfaceDBusStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

	def generateDBusStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterHeaderPath, fInterface.generateDBusStubAdapterHeader)
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterSourcePath, fInterface.generateDBusStubAdapterSource(deploymentAccessor))
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
                    const std::string& commonApiAddress,
                    const std::string& dbusInterfaceName,
                    const std::string& dbusBusName,
                    const std::string& dbusObjectPath,
                    const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusConnection,
                    const std::shared_ptr<CommonAPI::StubBase>& stub);
            
            «FOR attribute : fInterface.attributes»
                «IF attribute.isObservable»
                    void «attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(fInterface.model)»& value);
                «ENDIF»
            «ENDFOR»
        
            «FOR broadcast: fInterface.broadcasts»
                void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface.model) + '& ' + name].join(', ')»);
            «ENDFOR»

         protected:
            virtual const char* getMethodsDBusIntrospectionXmlData() const;
        };

        «fInterface.model.generateNamespaceEndDeclaration»

        #endif // «fInterface.defineName»_DBUS_STUB_ADAPTER_H_
    '''

    def private generateDBusStubAdapterSource(FInterface fInterface, DeploymentInterfacePropertyAccessor deploymentAccessor) '''
        «generateCommonApiLicenseHeader»
        #include "«fInterface.dbusStubAdapterHeaderFile»"
        #include <«fInterface.headerPath»>

        «fInterface.model.generateNamespaceBeginDeclaration»
        
        std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> create«fInterface.dbusStubAdapterClassName»(
                           const std::string& commonApiAddress,
                           const std::string& interfaceName,
                           const std::string& busName,
                           const std::string& objectPath,
                           const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyConnection,
                           const std::shared_ptr<CommonAPI::StubBase>& stubBase) {
            return std::make_shared<«fInterface.dbusStubAdapterClassName»>(commonApiAddress, interfaceName, busName, objectPath, dbusProxyConnection, stubBase);
        }

        __attribute__((constructor)) void register«fInterface.dbusStubAdapterClassName»(void) {
            CommonAPI::DBus::DBusFactory::registerAdapterFactoryMethod(«fInterface.name»::getInterfaceId(),
                                                                       &create«fInterface.dbusStubAdapterClassName»);
        }

        «fInterface.dbusStubAdapterClassName»::«fInterface.dbusStubAdapterClassName»(
                const std::string& commonApiAddress,
                const std::string& dbusInterfaceName,
                const std::string& dbusBusName,
                const std::string& dbusObjectPath,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusConnection,
                const std::shared_ptr<CommonAPI::StubBase>& stub):
                «fInterface.dbusStubAdapterHelperClassName»(commonApiAddress, dbusInterfaceName, dbusBusName, dbusObjectPath, dbusConnection, std::dynamic_pointer_cast<«fInterface.stubClassName»>(stub)) {
        }

        const char* «fInterface.dbusStubAdapterClassName»::getMethodsDBusIntrospectionXmlData() const {
            return
                «FOR attribute : fInterface.attributes»
                    "<method name=\"«attribute.dbusGetMethodName»\">\n"
                    	"<arg name=\"value\" type=\"«attribute.dbusSignature(deploymentAccessor)»\" direction=\"out\" />"
                    "</method>\n"
                    «IF !attribute.isReadonly»
                        "<method name=\"«attribute.dbusSetMethodName»\">\n"
                            "<arg name=\"requestedValue\" type=\"«attribute.dbusSignature(deploymentAccessor)»\" direction=\"in\" />\n"
                            "<arg name=\"setValue\" type=\"«attribute.dbusSignature(deploymentAccessor)»\" direction=\"out\" />\n"
                        "</method>\n"
                    «ENDIF»
                    «IF attribute.isObservable»
                        "<signal name=\"«attribute.dbusSignalName»\">\n"
                            "<arg name=\"changedValue\" type=\"«attribute.dbusSignature(deploymentAccessor)»\" />\n"
                        "</signal>\n"
                    «ENDIF»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts»
                    "<signal name=\"«broadcast.name»\">\n"
                        «FOR outArg : broadcast.outArgs»
                            "<arg name=\"«outArg.name»\" type=\"«outArg.getTypeDbusSignature(deploymentAccessor)»\" />\n"
                        «ENDFOR»
                    "</signal>\n"
                «ENDFOR»
                «FOR method : fInterface.methods»
                    "<method name=\"«method.name»\">\n"
                        «FOR inArg : method.inArgs»
                            "<arg name=\"«inArg.name»\" type=\"«inArg.getTypeDbusSignature(deploymentAccessor)»\" direction=\"in\" />\n"
                        «ENDFOR»
                    	«IF method.hasError»
                    		"<arg name=\"methodError\" type=\"«method.dbusErrorSignature(deploymentAccessor)»\" direction=\"out\" />\n"
                    	«ENDIF»
                        «FOR outArg : method.outArgs»
                            "<arg name=\"«outArg.name»\" type=\"«outArg.getTypeDbusSignature(deploymentAccessor)»\" direction=\"out\" />\n"
                        «ENDFOR»
                    "</method>\n"
                «ENDFOR»
            ;
        }


        «FOR attribute : fInterface.attributes»
            static CommonAPI::DBus::DBusGetAttributeStubDispatcher<
                    «fInterface.stubClassName»,
                    «attribute.getTypeName(fInterface.model)»
                    > «attribute.dbusGetStubDispatcherVariable»(&«fInterface.stubClassName»::«attribute.stubClassGetMethodName», "«attribute.dbusSignature(deploymentAccessor)»");
            «IF !attribute.isReadonly»
                static CommonAPI::DBus::DBusSet«IF attribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                        «fInterface.stubClassName»,
                        «attribute.getTypeName(fInterface.model)»
                        > «attribute.dbusSetStubDispatcherVariable»(
                                &«fInterface.stubClassName»::«attribute.stubClassGetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«attribute.stubRemoteEventClassSetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«attribute.stubRemoteEventClassChangedMethodName»,
                                «IF attribute.observable»&«fInterface.stubAdapterClassName»::«attribute.stubAdapterClassFireChangedMethodName»,«ENDIF»
                                "«attribute.dbusSignature(deploymentAccessor)»");
            «ENDIF»
            
        «ENDFOR»
        
        «FOR method : fInterface.methods»
            «IF !method.isFireAndForget»
                static CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>,
                    std::tuple<«method.allOutTypes»>
                    > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
            «ELSE»
                static CommonAPI::DBus::DBusMethodStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>
                    > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
            «ENDIF»
            
        «ENDFOR»

        «FOR attribute : fInterface.attributes»
            «IF attribute.isObservable»
                void «fInterface.dbusStubAdapterClassName»::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(fInterface.model)»& value) {
                	CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«attribute.getTypeName(fInterface.model)»>>
                        ::sendSignal(
                            *this,
                            "«attribute.dbusSignalName»",
                            "«attribute.dbusSignature(deploymentAccessor)»",
                            value
                    );
                }
            «ENDIF»
        «ENDFOR»

        «FOR broadcast: fInterface.broadcasts»
            void «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface.model) + '& ' + name].join(', ')») {
                CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«broadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>>
                        ::sendSignal(
                            *this,
                            "«broadcast.name»",
                            "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                            «broadcast.outArgs.map[name].join(', ')»
                    );
            }
        «ENDFOR»

        «fInterface.model.generateNamespaceEndDeclaration»

        template<>
        const «fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterHelperClassName»::StubDispatcherTable «fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterHelperClassName»::stubDispatcherTable_ = {
            «FOR attribute : fInterface.attributes SEPARATOR ','»
                { { "«attribute.dbusGetMethodName»", "" }, &«fInterface.absoluteNamespace»::«attribute.dbusGetStubDispatcherVariable» }
                «IF !attribute.isReadonly»
                    , { { "«attribute.dbusSetMethodName»", "«attribute.dbusSignature(deploymentAccessor)»" }, &«fInterface.absoluteNamespace»::«attribute.dbusSetStubDispatcherVariable» }
                «ENDIF»
            «ENDFOR»
            «IF !fInterface.attributes.empty && !fInterface.methods.empty»,«ENDIF»
            «FOR method : fInterface.methods SEPARATOR ','»
                { { "«method.name»", "«method.dbusInSignature(deploymentAccessor)»" }, &«fInterface.absoluteNamespace»::«method.dbusStubDispatcherVariable» }
            «ENDFOR»
        };
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
        fMethod.inArgs.map[getTypeName(fMethod.model)].join(', ')
    }

    def private getAllOutTypes(FMethod fMethod) {
        var types = fMethod.outArgs.map[getTypeName(fMethod.model)].join(', ')

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
