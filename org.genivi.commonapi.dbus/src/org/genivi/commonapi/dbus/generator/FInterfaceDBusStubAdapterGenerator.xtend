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
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessor
import java.util.HashMap
import org.franca.core.franca.FBroadcast

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

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/DBus/DBusStubAdapterHelper.h>
        #include <CommonAPI/DBus/DBusFactory.h>

        #undef COMMONAPI_INTERNAL_COMPILATION

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
                «IF !broadcast.selective.nullOrEmpty»
                    void «broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, fInterface)»);
                    void «broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, fInterface, true)»);
                    void «broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success);
                    void «broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId);
                    CommonAPI::ClientIdList* const «broadcast.stubAdapterClassSubscribersMethodName»();
                «ELSE»
                    void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface.model) + '& ' + name].join(', ')»);
                «ENDIF»
            «ENDFOR»

            const StubDispatcherTable& getStubDispatcherTable();

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
            static const char* introspectionData =
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
            return introspectionData;
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

        «var counterMap = new HashMap<String, Integer>()»
        «FOR method : fInterface.methods»
            «IF !method.isFireAndForget»
                static CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>,
                    std::tuple<«method.allOutTypes»>
                    «IF !(counterMap.containsKey(method.dbusStubDispatcherVariable))»
                        «{counterMap.put(method.dbusStubDispatcherVariable, 0);""}»
                        > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
                    «ELSE»
                        «{counterMap.put(method.dbusStubDispatcherVariable, counterMap.get(method.dbusStubDispatcherVariable) + 1);""}»
                        > «method.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(method.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
                    «ENDIF»
            «ELSE»
                static CommonAPI::DBus::DBusMethodStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«method.allInTypes»>
                    «IF !(counterMap.containsKey(method.dbusStubDispatcherVariable))»
                        «{counterMap.put(method.dbusStubDispatcherVariable, 0);""}»
                        > «method.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
                    «ELSE»
                        «{counterMap.put(method.dbusStubDispatcherVariable, counterMap.get(method.dbusStubDispatcherVariable) + 1);""}»
                        > «method.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(method.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + method.name», "«method.dbusOutSignature(deploymentAccessor)»");
                    «ENDIF»
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
            «IF !broadcast.selective.nullOrEmpty»
                static CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
                    «fInterface.stubClassName»,
                    «fInterface.stubAdapterClassName»,
                    std::tuple<>,
                    std::tuple<bool>
                    > «broadcast.dbusStubDispatcherVariableSubscribe»(&«fInterface.stubAdapterClassName + "::" + broadcast.subscribeSelectiveMethodName», "b");

                static CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
                    «fInterface.stubClassName»,
                    «fInterface.stubAdapterClassName»,
                    std::tuple<>,
                    std::tuple<>
                    > «broadcast.dbusStubDispatcherVariableUnsubscribe»(&«fInterface.stubAdapterClassName + "::" + broadcast.unsubscribeSelectiveMethodName», "");


                void «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, fInterface)») {
                    std::shared_ptr<CommonAPI::DBus::DBusClientId> dbusClientId = std::dynamic_pointer_cast<CommonAPI::DBus::DBusClientId, CommonAPI::ClientId>(clientId);

                    if(dbusClientId != NULL)
                    {
                        CommonAPI::DBus::DBusMessage dbusMethodCall = dbusClientId->createMessage(getObjectPath(), getInterfaceName(), "«broadcast.name»");
                        getDBusConnection()->sendDBusMessage(dbusMethodCall);
                    }
                }

                void «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, fInterface, false)») {
                    const CommonAPI::ClientIdList* actualReceiverList;
                    actualReceiverList = receivers;

                    if(receivers == NULL)
                        actualReceiverList = &«broadcast.stubAdapterClassSubscriberListPropertyName»;

                    for (auto clientIdIterator = actualReceiverList->cbegin();
                               clientIdIterator != actualReceiverList->cend();
                               clientIdIterator++) {
                        if(receivers == NULL || «broadcast.stubAdapterClassSubscriberListPropertyName».find(*clientIdIterator) != «broadcast.stubAdapterClassSubscriberListPropertyName».end()) {
                            «broadcast.stubAdapterClassFireSelectiveMethodName»(*clientIdIterator«IF(!broadcast.outArgs.empty)», «ENDIF»«broadcast.outArgs.map[name].join(', ')»);
                        }
                    }
                }

                void «fInterface.dbusStubAdapterClassName»::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
                    bool ok = stub_->«broadcast.subscriptionRequestedMethodName»(clientId);
                    if (ok) {
                        «broadcast.stubAdapterClassSubscriberListPropertyName».insert(clientId);
                        stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        success = true;
                    } else {
                        success = false;
                    }
                }


                void «fInterface.dbusStubAdapterClassName»::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
                    «broadcast.stubAdapterClassSubscriberListPropertyName».erase(clientId);
                    stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                }

                CommonAPI::ClientIdList* const «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    return &«broadcast.stubAdapterClassSubscriberListPropertyName»;
                }

            «ELSE»
                void «fInterface.dbusStubAdapterClassName»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface.model) + '& ' + name].join(', ')») {
                    CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«broadcast.outArgs.map[getTypeName(fInterface.model)].join(', ')»>>
                            ::sendSignal(
                                *this,
                                "«broadcast.name»",
                                "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                                «broadcast.outArgs.map[name].join(', ')»
                        );
                }
            «ENDIF»
        «ENDFOR»

        const «fInterface.dbusStubAdapterClassName»::StubDispatcherTable& «fInterface.dbusStubAdapterClassName»::getStubDispatcherTable() {
            static const «fInterface.dbusStubAdapterClassName»::StubDispatcherTable stubDispatcherTable = {
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
                    «IF fInterface.hasSelectiveBroadcasts»,«ENDIF»
                    «FOR broadcast : fInterface.broadcasts.filter[!selective.nullOrEmpty] SEPARATOR ','»
                        { { "«broadcast.subscribeSelectiveMethodName»", "" }, &«fInterface.absoluteNamespace»::«broadcast.dbusStubDispatcherVariableSubscribe» },
                        { { "«broadcast.unsubscribeSelectiveMethodName»", "" }, &«fInterface.absoluteNamespace»::«broadcast.dbusStubDispatcherVariableUnsubscribe» }
                    «ENDFOR»
                    };
            return stubDispatcherTable;
        }

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

    def private dbusStubDispatcherVariable(FBroadcast fBroadcast) {
        fBroadcast.name.toFirstLower + if(!fBroadcast.selective.isNullOrEmpty){'Selective'} + 'StubDispatcher'
    }

    def private dbusStubDispatcherVariableSubscribe(FBroadcast fBroadcast) {
        "subscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }

    def private dbusStubDispatcherVariableUnsubscribe(FBroadcast fBroadcast) {
        "unsubscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }
}
