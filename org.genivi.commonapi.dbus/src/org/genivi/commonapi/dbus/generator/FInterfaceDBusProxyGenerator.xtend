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

class FInterfaceDBusProxyGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

    def generateDBusProxy(FInterface fInterface, IFileSystemAccess fileSystemAccess, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        fileSystemAccess.generateFile(fInterface.dbusProxyHeaderPath, fInterface.generateDBusProxyHeader(deploymentAccessor))
        fileSystemAccess.generateFile(fInterface.dbusProxySourcePath, fInterface.generateDBusProxySource(deploymentAccessor))
    }

    def private generateDBusProxyHeader(FInterface fInterface, DeploymentInterfacePropertyAccessor deploymentAccessor) '''
        «generateCommonApiLicenseHeader»
        #ifndef «fInterface.defineName»_DBUS_PROXY_H_
        #define «fInterface.defineName»_DBUS_PROXY_H_

        #include <«fInterface.proxyBaseHeaderPath»>

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
            «ENDIF»
        «ENDIF»

        #undef COMMONAPI_INTERNAL_COMPILATION

        #include <string>

        «fInterface.model.generateNamespaceBeginDeclaration»

        class «fInterface.dbusProxyClassName»: virtual public «fInterface.proxyBaseClassName», virtual public CommonAPI::DBus::DBusProxy {
         public:
            «fInterface.dbusProxyClassName»(
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

                «IF !broadcast.selective.nullOrEmpty»
                    virtual CommonAPI::SelectiveBroadcastSubscriptionResult<«broadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>::SubscriptionResult «broadcast.subscribeSelectiveMethodName»(CommonAPI::SelectiveBroadcastFunctorHelper<«broadcast.outArgs.map[getTypeName(fInterface.model)].join(", ")»>::SelectiveBroadcastFunctor callback);
                    virtual void «broadcast.unsubscribeSelectiveMethodName»(«broadcast.className»::Subscription subscription);
                «ENDIF»
            «ENDFOR»

            «FOR method : fInterface.methods»

                virtual «method.generateDefinition»;
                «IF !method.isFireAndForget»
                    virtual «method.generateAsyncDefinition»;
                «ENDIF»
            «ENDFOR»

            virtual void getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const;

         private:
            «FOR attribute : fInterface.attributes»
                «attribute.dbusClassName(deploymentAccessor, fInterface)» «attribute.dbusClassVariableName»;
            «ENDFOR»

            «FOR broadcast : fInterface.broadcasts»
                «broadcast.dbusClassName» «broadcast.dbusClassVariableName»;
            «ENDFOR»
        };

        «fInterface.model.generateNamespaceEndDeclaration»

        #endif // «fInterface.defineName»_DBUS_PROXY_H_
    '''

    def private generateDBusProxySource(FInterface fInterface, DeploymentInterfacePropertyAccessor deploymentAccessor) '''
        «generateCommonApiLicenseHeader»
        #include "«fInterface.dbusProxyHeaderFile»"

        «fInterface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::DBus::DBusProxy> create«fInterface.dbusProxyClassName»(
                            const std::string& commonApiAddress,
                            const std::string& interfaceName,
                            const std::string& busName,
                            const std::string& objectPath,
                            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyConnection) {
            return std::make_shared<«fInterface.dbusProxyClassName»>(commonApiAddress, interfaceName, busName, objectPath, dbusProxyConnection);
        }

        __attribute__((constructor)) void register«fInterface.dbusProxyClassName»(void) {
            CommonAPI::DBus::DBusFactory::registerProxyFactoryMethod(«fInterface.name»::getInterfaceId(),
               &create«fInterface.dbusProxyClassName»);
        }

        «fInterface.dbusProxyClassName»::«fInterface.dbusProxyClassName»(
                            const std::string& commonApiAddress,
                            const std::string& interfaceName,
                            const std::string& busName,
                            const std::string& objectPath,
                            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection>& dbusProxyconnection):
                CommonAPI::DBus::DBusProxy(commonApiAddress, interfaceName, busName, objectPath, dbusProxyconnection)
                «FOR attribute : fInterface.attributes BEFORE ',' SEPARATOR ','»
                    «attribute.generateDBusVariableInit(deploymentAccessor, fInterface)»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts BEFORE ',' SEPARATOR ','»
                    «broadcast.dbusClassVariableName»(*this, "«broadcast.name»", "«broadcast.dbusSignature(deploymentAccessor)»", «(!broadcast.selective.nullOrEmpty).toString»)
                «ENDFOR» {
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
            «method.generateDefinitionWithin(fInterface.dbusProxyClassName)» {
                «method.generateDBusProxyHelperClass»::callMethodWithReply(
                    *this,
                    "«method.name»",
                    "«method.dbusInSignature(deploymentAccessor)»",
                    «method.inArgs.map[name].join('', ', ', ', ', [toString])»
                    callStatus«IF method.hasError»,
                    methodError«ENDIF»
                    «method.outArgs.map[name].join(', ', ', ', '', [toString])»);
            }
            «IF !method.isFireAndForget»
                «method.generateAsyncDefinitionWithin(fInterface.dbusProxyClassName)» {
                    return «method.generateDBusProxyHelperClass»::callMethodAsync(
                        *this,
                        "«method.name»",
                        "«method.dbusInSignature(deploymentAccessor)»",
                        «method.inArgs.map[name].join('', ', ', ', ', [toString])»
                        std::move(callback));
                }
            «ENDIF»
        «ENDFOR»

        «FOR selectiveBroadcast : fInterface.broadcasts.filter[!selective.nullOrEmpty]»
            CommonAPI::SelectiveBroadcastSubscriptionResult<«selectiveBroadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>::SubscriptionResult «fInterface.dbusProxyClassName»::«selectiveBroadcast.subscribeSelectiveMethodName»(CommonAPI::SelectiveBroadcastFunctorHelper<«selectiveBroadcast.outArgs.map[getTypeName(fInterface.model)].join(", ")»>::SelectiveBroadcastFunctor callback) {
                bool success = false;
                CommonAPI::CallStatus callStatus;

                CommonAPI::Event<«selectiveBroadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>::Subscription subscription = «selectiveBroadcast.generateDBusProxyHelperClass»::callSubscribeForSelectiveBroadcast<«selectiveBroadcast.className», void(«selectiveBroadcast.outArgs.map[getTypeName(fInterface.model)].join(", ")»), CommonAPI::DBus::DBusProxy>(
                    *this,
                    "«selectiveBroadcast.name»",
                    &«selectiveBroadcast.dbusClassVariableName»,
                    "",
                    callStatus,
                    success,
                    callback
                    );

                return CommonAPI::SelectiveBroadcastSubscriptionResult<«selectiveBroadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>::SubscriptionResult(success, subscription);
            }
            void «fInterface.dbusProxyClassName»::«selectiveBroadcast.unsubscribeSelectiveMethodName»(«selectiveBroadcast.className»::Subscription subscription) {
                CommonAPI::CallStatus callStatus;

                «selectiveBroadcast.generateDBusProxyHelperClassUnsubscribe»::callUnsubscribeFromSelectiveBroadcast<«selectiveBroadcast.className», CommonAPI::DBus::DBusProxy>(
                    *this,
                    "«selectiveBroadcast.name»",
                    &«selectiveBroadcast.dbusClassVariableName»,
                    callStatus,
                    subscription
                    );
            }
        «ENDFOR»

        void «fInterface.dbusProxyClassName»::getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const {
            ownVersionMajor = «fInterface.version.major»;
            ownVersionMinor = «fInterface.version.minor»;
        }

        «fInterface.model.generateNamespaceEndDeclaration»
    '''

    def private dbusClassVariableName(FModelElement fModelElement) {
        checkArgument(!fModelElement.name.nullOrEmpty, 'FModelElement has no name: ' + fModelElement)
        fModelElement.name.toFirstLower + '_'
    }

    def private dbusClassVariableName(FBroadcast fBroadcast) {
        checkArgument(!fBroadcast.name.nullOrEmpty, 'FModelElement has no name: ' + fBroadcast)
        var classVariableName = fBroadcast.name.toFirstLower

        if(!fBroadcast.selective.nullOrEmpty)
            classVariableName = classVariableName + 'Selective'

        classVariableName = classVariableName + '_'

        return classVariableName
    }

    def private dbusProxyHeaderFile(FInterface fInterface) {
        fInterface.name + "DBusProxy.h"
    }

    def private dbusProxyHeaderPath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusProxyHeaderFile
    }

    def private dbusProxySourceFile(FInterface fInterface) {
        fInterface.name + "DBusProxy.cpp"
    }

    def private dbusProxySourcePath(FInterface fInterface) {
        fInterface.model.directoryPath + '/' + fInterface.dbusProxySourceFile
    }

    def private dbusProxyClassName(FInterface fInterface) {
        fInterface.name + 'DBusProxy'
    }

    def private generateDBusProxyHelperClass(FMethod fMethod) '''
        CommonAPI::DBus::DBusProxyHelper<CommonAPI::DBus::DBusSerializableArguments<«fMethod.inArgs.map[getTypeName(fMethod.model)].join(', ')»>,
                                         CommonAPI::DBus::DBusSerializableArguments<«IF fMethod.hasError»«fMethod.getErrorNameReference(fMethod.eContainer)»«IF !fMethod.outArgs.empty», «ENDIF»«ENDIF»«fMethod.outArgs.map[getTypeName(fMethod.model)].join(', ')»> >'''

    def private generateDBusProxyHelperClass(FBroadcast fBroadcast) '''
        CommonAPI::DBus::DBusProxyHelper<CommonAPI::DBus::DBusSerializableArguments<>,
                                         CommonAPI::DBus::DBusSerializableArguments<bool> >'''

    def private generateDBusProxyHelperClassUnsubscribe(FBroadcast fBroadcast) '''
        CommonAPI::DBus::DBusProxyHelper<CommonAPI::DBus::DBusSerializableArguments<>,
                                         CommonAPI::DBus::DBusSerializableArguments<> >'''


    def private dbusClassName(FAttribute fAttribute, DeploymentInterfacePropertyAccessor deploymentAccessor, FInterface fInterface) {
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

    def private generateDBusVariableInit(FAttribute fAttribute, DeploymentInterfacePropertyAccessor deploymentAccessor, FInterface fInterface) {
        var ret = fAttribute.dbusClassVariableName + '(*this'

        if (deploymentAccessor.getPropertiesType(fInterface) == PropertiesType::freedesktop) {
            ret = ret + ', interfaceName.c_str(), "' + fAttribute.name + '")'
        } else {

            if (fAttribute.isObservable)
                ret = ret + ', "' + fAttribute.dbusSignalName + '"'

            if (!fAttribute.isReadonly)
                ret = ret + ', "' + fAttribute.dbusSetMethodName + '", "' + fAttribute.dbusSignature(deploymentAccessor) + '"'

            ret = ret + ', "' + fAttribute.dbusGetMethodName + '")'
        }
        return ret
    }

    def private dbusClassName(FBroadcast fBroadcast) {
        return 'CommonAPI::DBus::DBusEvent<' + fBroadcast.className + '>'
    }
}
