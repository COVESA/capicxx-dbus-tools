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
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessor

import static com.google.common.base.Preconditions.*
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessor$PropertiesType
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.eclipse.core.resources.IResource

class FInterfaceDBusProxyGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

    def generateDBusProxy(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        DeploymentInterfacePropertyAccessor deploymentAccessor, IResource modelid) {
        fileSystemAccess.generateFile(fInterface.dbusProxyHeaderPath,
            fInterface.generateDBusProxyHeader(deploymentAccessor, modelid))
        fileSystemAccess.generateFile(fInterface.dbusProxySourcePath,
            fInterface.generateDBusProxySource(deploymentAccessor, modelid))
    }

    def private generateDBusProxyHeader(FInterface fInterface, DeploymentInterfacePropertyAccessor deploymentAccessor,
        IResource modelid) '''
        «generateCommonApiLicenseHeader(fInterface, modelid)»
        «FTypeGenerator::generateComments(fInterface, false)»
        #ifndef «fInterface.defineName»_DBUS_PROXY_H_
        #define «fInterface.defineName»_DBUS_PROXY_H_

        #include <«fInterface.proxyBaseHeaderPath»>
        «IF fInterface.base != null»
            #include <«fInterface.base.dbusProxyHeaderPath»>
        «ENDIF»

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/DBus/DBusFactory.h>
        #include <CommonAPI/DBus/DBusProxy.h>
        «IF fInterface.hasAttributes»
            #include <CommonAPI/DBus/DBusAttribute.h>
        «ENDIF»
        «IF fInterface.hasBroadcasts»
            #include <CommonAPI/DBus/DBusEvent.h>
            «IF fInterface.hasSelectiveBroadcasts»
                #include <CommonAPI/types.h>
                #include <CommonAPI/DBus/DBusSelectiveEvent.h>
            «ENDIF»
        «ENDIF»
        «IF !fInterface.managedInterfaces.empty»
            #include <CommonAPI/DBus/DBusProxyManager.h>
        «ENDIF»

        #undef COMMONAPI_INTERNAL_COMPILATION

        #include <string>

        «fInterface.model.generateNamespaceBeginDeclaration»

        class «fInterface.dbusProxyClassName»: virtual public «fInterface.proxyBaseClassName», virtual public «IF fInterface.base != null»«fInterface.base.dbusProxyClassName»«ELSE»CommonAPI::DBus::DBusProxy«ENDIF» {
         public:
            «fInterface.dbusProxyClassName»(
                            const std::shared_ptr<CommonAPI::DBus::DBusFactory>& factory,
                            const std::string& commonApiAddress,
                            const std::string& interfaceName,
                            const std::string& busName,
                            const std::string& objectPath,
                            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyconnection);

            virtual ~«fInterface.dbusProxyClassName»() { }

            «FOR attribute : fInterface.attributes»
            virtual «attribute.generateGetMethodDefinition»;
            «ENDFOR»

            «FOR broadcast : fInterface.broadcasts»
            virtual «broadcast.generateGetMethodDefinition»;
            «ENDFOR»

            «FOR method : fInterface.methods»
            «FTypeGenerator::generateComments(method, false)»
            virtual «method.generateDefinition»;
            «IF !method.isFireAndForget»
                virtual «method.generateAsyncDefinition»;
            «ENDIF»
            «ENDFOR»

            «FOR managed : fInterface.managedInterfaces»
                virtual CommonAPI::ProxyManager& «managed.proxyManagerGetterName»();
            «ENDFOR»

            virtual void getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const;

         private:
           «FOR attribute : fInterface.attributes»
               «attribute.dbusClassName(deploymentAccessor, fInterface)» «attribute.dbusClassVariableName»;
           «ENDFOR»

            «FOR broadcast : fInterface.broadcasts»
            «broadcast.dbusClassName» «broadcast.dbusClassVariableName»;
            «ENDFOR»

            «FOR managed : fInterface.managedInterfaces»
                CommonAPI::DBus::DBusProxyManager «managed.proxyManagerMemberName»;
            «ENDFOR»
        };
        
        

        «fInterface.model.generateNamespaceEndDeclaration»

        #endif // «fInterface.defineName»_DBUS_PROXY_H_
    '''

    def private generateDBusProxySource(FInterface fInterface, DeploymentInterfacePropertyAccessor deploymentAccessor,
        IResource modelid) '''
        «generateCommonApiLicenseHeader(fInterface, modelid)»
        «FTypeGenerator::generateComments(fInterface, false)»
        #include "«fInterface.dbusProxyHeaderFile»"

        «fInterface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::DBus::DBusProxy> create«fInterface.dbusProxyClassName»(
                            const std::shared_ptr<CommonAPI::DBus::DBusFactory>& factory,
                            const std::string& commonApiAddress,
                            const std::string& interfaceName,
                            const std::string& busName,
                            const std::string& objectPath,
                            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyConnection) {
            return std::make_shared<«fInterface.dbusProxyClassName»>(factory, commonApiAddress, interfaceName, busName, objectPath, dbusProxyConnection);
        }

        INITIALIZER(register«fInterface.dbusProxyClassName») {
            CommonAPI::DBus::DBusFactory::registerProxyFactoryMethod(«fInterface.elementName»::getInterfaceId(),
               &create«fInterface.dbusProxyClassName»);
        }

        «fInterface.dbusProxyClassName»::«fInterface.dbusProxyClassName»(
                            const std::shared_ptr<CommonAPI::DBus::DBusFactory>& factory,
                            const std::string& commonApiAddress,
                            const std::string& interfaceName,
                            const std::string& busName,
                            const std::string& objectPath,
                            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyconnection):
                CommonAPI::DBus::DBusProxy(factory, commonApiAddress, interfaceName, busName, objectPath, dbusProxyconnection)
                «IF fInterface.base != null»
                , «fInterface.base.dbusProxyClassName»(
                            factory,
                            commonApiAddress,
                            interfaceName,
                            busName,
                            objectPath,
                            dbusProxyconnection)
                «ENDIF»
                «FOR attribute : fInterface.attributes BEFORE ',' SEPARATOR ','»
            «attribute.generateDBusVariableInit(deploymentAccessor, fInterface)»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts BEFORE ',' SEPARATOR ','»
                    «broadcast.dbusClassVariableName»(*this, "«broadcast.elementName»", "«broadcast.dbusSignature(deploymentAccessor)»")
                «ENDFOR»
                «FOR managed : fInterface.managedInterfaces BEFORE ',' SEPARATOR ','»
                    «managed.proxyManagerMemberName»(*this, "«managed.fullyQualifiedName»", factory)
                «ENDFOR»
            {
            }

        «FOR attribute : fInterface.attributes»
            «attribute.generateGetMethodDefinitionWithin(fInterface.dbusProxyClassName)» {
                return «attribute.dbusClassVariableName»;
            }
        «ENDFOR»

        «FOR broadcast : fInterface.broadcasts»
            «broadcast.generateGetMethodDefinitionWithin(fInterface.dbusProxyClassName)» {
                return «broadcast.dbusClassVariableName»;
            }
        «ENDFOR»

        «FOR method : fInterface.methods»
            «FTypeGenerator::generateComments(method, false)»
            «method.generateDefinitionWithin(fInterface.dbusProxyClassName)» {
                «method.generateDBusProxyHelperClass»::callMethodWithReply(
                    *this,
                    "«method.elementName»",
                    "«method.dbusInSignature(deploymentAccessor)»",
                    «method.inArgs.map[elementName].join('', ', ', ',', [toString])»
                    callStatus«IF method.hasError»,
                    methodError«ENDIF»
                    «method.outArgs.map[elementName].join(', ', ', ', '', [toString])»);
            }
            «IF !method.isFireAndForget»
                «method.generateAsyncDefinitionWithin(fInterface.dbusProxyClassName)» {
                    return «method.generateDBusProxyHelperClass»::callMethodAsync(
                        *this,
                        "«method.elementName»",
                        "«method.dbusInSignature(deploymentAccessor)»",
                        «method.inArgs.map[elementName].join('', ', ', ', ', [toString])»
                        std::move(callback));
                }
            «ENDIF»
        «ENDFOR»
        
        «FOR managed : fInterface.managedInterfaces»
            CommonAPI::ProxyManager& «fInterface.dbusProxyClassName»::«managed.proxyManagerGetterName»() {
                return «managed.proxyManagerMemberName»;
            }
        «ENDFOR»


        void «fInterface.dbusProxyClassName»::getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const {
            ownVersionMajor = «fInterface.version.major»;
            ownVersionMinor = «fInterface.version.minor»;
        }

        «fInterface.model.generateNamespaceEndDeclaration»
    '''

    def private dbusClassVariableName(FModelElement fModelElement) {
        checkArgument(!fModelElement.elementName.nullOrEmpty, 'FModelElement has no name: ' + fModelElement)
        fModelElement.elementName.toFirstLower + '_'
    }

    def private dbusClassVariableName(FBroadcast fBroadcast) {
        checkArgument(!fBroadcast.elementName.nullOrEmpty, 'FModelElement has no name: ' + fBroadcast)
        var classVariableName = fBroadcast.elementName.toFirstLower

        if (!fBroadcast.selective.nullOrEmpty)
            classVariableName = classVariableName + 'Selective'

        classVariableName = classVariableName + '_'

        return classVariableName
    }

    def private dbusProxyHeaderFile(FInterface fInterface) {
        fInterface.elementName + "DBusProxy.h"
    }

    def private dbusProxyHeaderPath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusProxyHeaderFile
    }

    def private dbusProxySourceFile(FInterface fInterface) {
        fInterface.elementName + "DBusProxy.cpp"
    }

    def private dbusProxySourcePath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusProxySourceFile
    }

    def private dbusProxyClassName(FInterface fInterface) {
        fInterface.elementName + 'DBusProxy'
    }

    def private generateDBusProxyHelperClass(FMethod fMethod) '''
    CommonAPI::DBus::DBusProxyHelper<CommonAPI::DBus::DBusSerializableArguments<«fMethod.inArgs.map[
        getTypeName(fMethod.model)].join(', ')»>,
                                     CommonAPI::DBus::DBusSerializableArguments<«IF fMethod.hasError»«fMethod.
        getErrorNameReference(fMethod.eContainer)»«IF !fMethod.outArgs.empty», «ENDIF»«ENDIF»«fMethod.outArgs.map[
        getTypeName(fMethod.model)].join(', ')»> >'''

    def private dbusClassName(FAttribute fAttribute, DeploymentInterfacePropertyAccessor deploymentAccessor,
        FInterface fInterface) {
        var type = 'CommonAPI::DBus::DBus'
        if (deploymentAccessor.getPropertiesType(fInterface) == PropertiesType::freedesktop) {
            type = type + 'Freedesktop'

            if (fAttribute.getType.getDerived instanceof FUnionType) {
                type = type + 'Union'
            }
        }

        if (fAttribute.isReadonly)
            type = type + 'Readonly'

        type = type + 'Attribute<' + fAttribute.className + '>'

        if (fAttribute.isObservable)
            if (deploymentAccessor.getPropertiesType(fInterface) == PropertiesType::freedesktop) {
                if (fAttribute.getType.getDerived instanceof FUnionType) {
                    type = 'CommonAPI::DBus::DBusFreedesktopUnionObservableAttribute<' + type + '>'
                } else {
                    type = 'CommonAPI::DBus::DBusFreedesktopObservableAttribute<' + type + '>'
                }
            } else {
                type = 'CommonAPI::DBus::DBusObservableAttribute<' + type + '>'
            }

        return type
    }

    def private generateDBusVariableInit(FAttribute fAttribute, DeploymentInterfacePropertyAccessor deploymentAccessor,
        FInterface fInterface) {
        var ret = fAttribute.dbusClassVariableName + '(*this'

        if (deploymentAccessor.getPropertiesType(fInterface) == PropertiesType::freedesktop) {
            ret = ret + ', interfaceName.c_str(), "' + fAttribute.elementName + '")'
        } else {

            if (fAttribute.isObservable)
                ret = ret + ', "' + fAttribute.dbusSignalName + '"'

            if (!fAttribute.isReadonly)
                ret = ret + ', "' + fAttribute.dbusSetMethodName + '", "' + fAttribute.dbusSignature(deploymentAccessor) + '", "' + fAttribute.dbusGetMethodName + '")'
            else
                ret = ret + ', "' + fAttribute.dbusSignature(deploymentAccessor) + '", "' + fAttribute.dbusGetMethodName + '")'
        }
        return ret
    }

    def private dbusClassName(FBroadcast fBroadcast) {
        var ret = 'CommonAPI::DBus::'

        if (fBroadcast.isSelective)
            ret = ret + 'DBusSelectiveEvent'
        else
            ret = ret + 'DBusEvent'

        ret = ret + '<' + fBroadcast.className + '>'

        return ret
    }
}
