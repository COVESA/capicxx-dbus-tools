/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import java.util.HashMap
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus
import java.util.List
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.franca.deploymodel.core.FDeployedProvider
import java.util.LinkedList

class FInterfaceDBusStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions
    @Inject private extension FrancaDBusDeploymentAccessorHelper

    def generateDBusStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor,  List<FDProvider> providers, IResource modelid) {

        if(FPreferencesDBus::getInstance.getPreference(PreferenceConstantsDBus::P_GENERATE_CODE_DBUS, "true").equals("true")) {
            fileSystemAccess.generateFile(fInterface.dbusStubAdapterHeaderPath, PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS,
                    fInterface.generateDBusStubAdapterHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(fInterface.dbusStubAdapterSourcePath,  PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS,
                    fInterface.generateDBusStubAdapterSource(deploymentAccessor, providers, modelid))
        }
        else {
            // feature: suppress code generation
            fileSystemAccess.generateFile(fInterface.dbusStubAdapterHeaderPath, PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, PreferenceConstantsDBus::NO_CODE)
            fileSystemAccess.generateFile(fInterface.dbusStubAdapterSourcePath,  PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, PreferenceConstantsDBus::NO_CODE)
        }
    }


    def private generateDBusStubAdapterHeader(FInterface fInterface,
                                              PropertyAccessor deploymentAccessor,
                                              IResource modelid ) '''
        «generateCommonApiDBusLicenseHeader()»
        «FTypeGenerator::generateComments(fInterface, false)»
        #ifndef «fInterface.defineName»_DBUS_STUB_ADAPTER_HPP_
        #define «fInterface.defineName»_DBUS_STUB_ADAPTER_HPP_

        #include <«fInterface.stubHeaderPath»>
        «IF fInterface.base != null»
            #include <«fInterface.base.dbusStubAdapterHeaderPath»>
        «ENDIF»
        #include "«fInterface.dbusDeploymentHeaderPath»"
        «val DeploymentHeaders = fInterface.getDeploymentInputIncludes(deploymentAccessor)»
        «DeploymentHeaders.map["#include <" + it + ">"].join("\n")»

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/DBus/DBusAddressTranslator.hpp>
        #include <CommonAPI/DBus/DBusFactory.hpp>
        «IF !fInterface.managedInterfaces.empty»
            #include <CommonAPI/DBus/DBusObjectManager.hpp>
        «ENDIF»
        #include <CommonAPI/DBus/DBusStubAdapterHelper.hpp>
        #include <CommonAPI/DBus/DBusStubAdapter.hpp>
        «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»
            #include <CommonAPI/DBus/DBusFreedesktopStubAdapterHelper.hpp>
        «ENDIF»
        #include <CommonAPI/DBus/DBusDeployment.hpp>

        #undef COMMONAPI_INTERNAL_COMPILATION

        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        template <typename _Stub = «fInterface.stubFullClassName», typename... _Stubs>
        class «fInterface.dbusStubAdapterClassNameInternal»
            : public virtual «fInterface.stubAdapterClassName»,
            «IF fInterface.base == null»  public CommonAPI::DBus::DBusStubAdapterHelper< _Stub, _Stubs...>«ENDIF»
            «IF fInterface.base != null»  public «fInterface.base.getTypeCollectionName(fInterface)»DBusStubAdapterInternal<_Stub, _Stubs...>«ENDIF» {
        public:
            typedef CommonAPI::DBus::DBusStubAdapterHelper< _Stub, _Stubs...> «fInterface.dbusStubAdapterHelperClassName»;

            ~«fInterface.dbusStubAdapterClassNameInternal»() {
                deactivateManagedInstances();
                «fInterface.dbusStubAdapterHelperClassName»::deinit();
            }

            virtual bool hasFreedesktopProperties() {
                return «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»true«ELSE»false«ENDIF»;
            }

            inline static const char* getInterface() {
                return «fInterface.elementName»::getInterface();
            }

            «FOR attribute : fInterface.attributes»
                «IF attribute.isObservable»
                    «FTypeGenerator::generateComments(attribute, false)»
                    void «attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(fInterface, true)»& value);
                «ENDIF»

            «ENDFOR»
            «FOR broadcast: fInterface.broadcasts»
                «FTypeGenerator::generateComments(broadcast, false)»
                «IF broadcast.selective»
                    void «broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, fInterface)»);
                    void «broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, fInterface, true)»);
                    void «broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success);
                    void «broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId);
                    std::shared_ptr<CommonAPI::ClientIdList> const «broadcast.stubAdapterClassSubscribersMethodName»();
                «ELSE»
                    «IF !broadcast.isErrorType(deploymentAccessor)»
                        void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface, true) + '& ' + elementName].join(', ')»);
                    «ENDIF»
                «ENDIF»

            «ENDFOR»
            «FOR managed: fInterface.managedInterfaces»
                «managed.stubRegisterManagedMethod»;
                bool «managed.stubDeregisterManagedName»(const std::string&);
                std::set<std::string>& «managed.stubManagedSetGetterName»();

            «ENDFOR»
            void deactivateManagedInstances() {
            «IF !fInterface.managedInterfaces.empty»
                std::set<std::string>::iterator iter;
                std::set<std::string>::iterator iterNext;

            «ENDIF»
            «FOR managed : fInterface.managedInterfaces»
                iter = «managed.stubManagedSetName».begin();
                while (iter != «managed.stubManagedSetName».end()) {
                    iterNext = std::next(iter);

                    if («managed.stubDeregisterManagedName»(*iter)) {
                        iter = iterNext;
                    }
                    else {
                        iter++;
                    }
                }
            «ENDFOR»
            }

            «IF fInterface.base != null»
                virtual const CommonAPI::Address &getAddress() const {
                    return CommonAPI::DBus::DBusStubAdapter::getAddress();
                }

                virtual void init(std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> instance) {
                    return CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::init(instance);
                }

                virtual void deinit() {
                    return CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::deinit();
                }

                virtual bool onInterfaceDBusMessage(const CommonAPI::DBus::DBusMessage& dbusMessage) {
                    return CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::onInterfaceDBusMessage(dbusMessage);
                }

                virtual bool onInterfaceDBusFreedesktopPropertiesMessage(const CommonAPI::DBus::DBusMessage& dbusMessage) {
                    return CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::onInterfaceDBusFreedesktopPropertiesMessage(dbusMessage);
                }

            «ENDIF»
            static CommonAPI::DBus::DBusGetAttributeStubDispatcher<
                «fInterface.stubFullClassName»,
                CommonAPI::Version
                > get«fInterface.elementName»InterfaceVersionStubDispatcher;

            «FOR attribute : fInterface.attributes»
                «generateAttributeDispatcherDeclarations(attribute, deploymentAccessor, fInterface)»

            «ENDFOR»
            «var counterMap = new HashMap<String, Integer>()»
            «var methodnumberMap = new HashMap<FMethod, Integer>()»
            «FOR method : fInterface.methods»
                «generateMethodDispatcherDeclarations(method, fInterface, counterMap, methodnumberMap, deploymentAccessor)»

            «ENDFOR»
            «FOR broadcast: fInterface.broadcasts»
                «generateBroadcastDispatcherDeclarations(broadcast, fInterface)»

            «ENDFOR»
            «fInterface.dbusStubAdapterClassNameInternal»(
                const CommonAPI::DBus::DBusAddress &_address,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                const std::shared_ptr<_Stub> &_stub)
            : CommonAPI::DBus::DBusStubAdapter(_address, _connection,«IF !fInterface.managedInterfaces.nullOrEmpty»true«ELSE»false«ENDIF»),
              «IF fInterface.base == null»«fInterface.dbusStubAdapterHelperClassName»(_address, _connection, «IF !fInterface.managedInterfaces.nullOrEmpty»true,«ELSE»false,«ENDIF» _stub) {«ENDIF»
              «IF fInterface.base != null»
                  «fInterface.base.getTypeCollectionName(fInterface)»DBusStubAdapterInternal<_Stub, _Stubs...>(_address, _connection, _stub) {
              «ENDIF»
                «IF deploymentAccessor.getPropertiesType(fInterface) != PropertyAccessor.PropertiesType.freedesktop»
                    «FOR attribute : fInterface.attributes»
                        «FTypeGenerator::generateComments(attribute, false)»
                        «dbusDispatcherTableEntry(fInterface, attribute.dbusGetMethodName, "", attribute.dbusGetStubDispatcherVariable)»
                        «IF !attribute.isReadonly»
                            «dbusDispatcherTableEntry(fInterface, attribute.dbusSetMethodName, attribute.dbusSignature(deploymentAccessor), attribute.dbusSetStubDispatcherVariable)»
                        «ENDIF»
                    «ENDFOR»
                «ENDIF»
                «FOR method : fInterface.methods»
                    «FTypeGenerator::generateComments(method, false)»
                    «IF methodnumberMap.get(method)==0»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable)»
                    «ELSE»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable+methodnumberMap.get(method))»
                    «ENDIF»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts.filter[selective]»
                    «dbusDispatcherTableEntry(fInterface, broadcast.subscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableSubscribe)»
                    «dbusDispatcherTableEntry(fInterface, broadcast.unsubscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableUnsubscribe)»
                «ENDFOR»
                «fInterface.generateStubAttributeTableInitializer(deploymentAccessor)»
                «FOR broadcast : fInterface.broadcasts»
                    «IF broadcast.selective»
                        «broadcast.getStubAdapterClassSubscriberListPropertyName» = std::make_shared<CommonAPI::ClientIdList>();
                    «ENDIF»
                «ENDFOR»
                «fInterface.dbusStubAdapterHelperClassName»::addStubDispatcher({ "getInterfaceVersion", "" }, &get«fInterface.elementName»InterfaceVersionStubDispatcher);
            }

        protected:
            virtual const char* getMethodsDBusIntrospectionXmlData() const {
                static const std::string introspectionData =
                    «IF fInterface.base != null»
                        std::string(«fInterface.base.getTypeCollectionName(fInterface)»DBusStubAdapterInternal<_Stub, _Stubs...>::getMethodsDBusIntrospectionXmlData()) +
                    «ELSE»
                        "<method name=\"getInterfaceVersion\">\n"
                            "<arg name=\"value\" type=\"uu\" direction=\"out\" />"
                        "</method>\n"
                    «ENDIF»
                    «FOR attribute : fInterface.attributes»
                        «IF deploymentAccessor.getPropertiesType(attribute.containingInterface) == PropertyAccessor.PropertiesType.freedesktop»
                            "<property name=\"«attribute.elementName»\" type=\"«attribute.dbusSignature(deploymentAccessor)»\" access=\"read«IF !attribute.readonly»write«ENDIF»\" />\n"
                        «ELSE»
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
                        «ENDIF»
                    «ENDFOR»
                    «FOR broadcast : fInterface.broadcasts»
                        «IF !broadcast.isErrorType(deploymentAccessor)»
                            «FTypeGenerator::generateComments(broadcast, false)»
                            "<signal name=\"«broadcast.elementName»\">\n"
                            «FOR outArg : broadcast.outArgs»
                                "<arg name=\"«outArg.elementName»\" type=\"«outArg.getTypeDbusSignature(deploymentAccessor)»\" />\n"
                            «ENDFOR»
                            "</signal>\n"
                        «ENDIF»
                    «ENDFOR»
                    «FOR method : fInterface.methods»
                        «FTypeGenerator::generateComments(method, false)»
                        "<method name=\"«method.elementName»\">\n"
                        «FOR inArg : method.inArgs»
                            "<arg name=\"_«inArg.elementName»\" type=\"«inArg.getTypeDbusSignature(deploymentAccessor)»\" direction=\"in\" />\n"
                        «ENDFOR»
                        «IF method.hasError»
                            "<arg name=\"_error\" type=\"«method.dbusErrorSignature(deploymentAccessor)»\" direction=\"out\" />\n"
                        «ENDIF»
                        «FOR outArg : method.outArgs»
                            "<arg name=\"_«outArg.elementName»\" type=\"«outArg.getTypeDbusSignature(deploymentAccessor)»\" direction=\"out\" />\n"
                        «ENDFOR»
                        "</method>\n"
                    «ENDFOR»
                    «IF fInterface.attributes.empty && fInterface.broadcasts.empty && fInterface.methods.empty»
                        ""
                    «ENDIF»
                    ;
                return introspectionData.c_str();
            }

        private:
            «FOR broadcast: fInterface.broadcasts»
                «IF broadcast.selective»
                    std::mutex «broadcast.className»Mutex_;
                «ENDIF»
            «ENDFOR»
            «FOR managed: fInterface.managedInterfaces»
                std::set<std::string> «managed.stubManagedSetName»;
            «ENDFOR»
        };


        template <typename _Stub, typename... _Stubs>
        CommonAPI::DBus::DBusGetAttributeStubDispatcher<
            «fInterface.stubFullClassName»,
            CommonAPI::Version
            > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::get«fInterface.elementName»InterfaceVersionStubDispatcher(&«fInterface.stubClassName»::getInterfaceVersion, "uu");

        «FOR attribute : fInterface.attributes»
            «generateAttributeDispatcherDefinitions(attribute, fInterface, deploymentAccessor)»

        «ENDFOR»
        «{counterMap = new HashMap<String, Integer>(); ""}»
        «{methodnumberMap = new HashMap<FMethod, Integer>(); ""}»
        «FOR method : fInterface.methods»
            «generateMethodDispatcherDefinitions(method, fInterface, counterMap, methodnumberMap, deploymentAccessor)»

        «ENDFOR»
        «FOR attribute : fInterface.attributes.filter[isObservable()]»
            «FTypeGenerator::generateComments(attribute, false)»
            template <typename _Stub, typename... _Stubs>
            void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(fInterface, true)»& value) {
                «attribute.generateFireChangedMethodBody(fInterface, deploymentAccessor)»
            }

        «ENDFOR»
        «FOR broadcast: fInterface.broadcasts»
            «FTypeGenerator::generateComments(broadcast, false)»
            «IF broadcast.selective»
                «generateBroadcastDispatcherDefinitions(broadcast, fInterface)»
                template <typename _Stub, typename... _Stubs>
                void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, fInterface)») {
                    std::shared_ptr<CommonAPI::DBus::DBusClientId> dbusClient = std::dynamic_pointer_cast<CommonAPI::DBus::DBusClientId, CommonAPI::ClientId>(_client);

                    if(dbusClient)
                    {
                        CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<
                        «FOR outArg : broadcast.outArgs SEPARATOR ","»
                            «val String deploymentType = outArg.getDeploymentType(fInterface, true)»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                 CommonAPI::Deployable< «outArg.getTypeName(fInterface, true)», «deploymentType»>
                            «ELSE»
                                «outArg.getTypeName(fInterface, true)»
                            «ENDIF»
                        «ENDFOR»
                        >>::sendSignal(
                                dbusClient->getDBusId(),
                                *this,
                                "«broadcast.elementName»",
                                "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                        «FOR outArg : broadcast.outArgs SEPARATOR ","»
                            «val String deploymentType = outArg.getDeploymentType(fInterface, true)»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                «val String deployment = outArg.getDeploymentRef(outArg.array, broadcast, fInterface, deploymentAccessor)»
                                CommonAPI::Deployable< «outArg.getTypeName(fInterface, true)», «deploymentType»>(_«outArg.name», «deployment»)
                            «ELSE»
                                _«outArg.name»
                            «ENDIF»
                        «ENDFOR»
                        );
                    }
                }
                template <typename _Stub, typename... _Stubs>
                void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, fInterface, false)») {
                    std::shared_ptr<CommonAPI::ClientIdList> actualReceiverList = _receivers;

                    if (!_receivers) {
                        std::lock_guard < std::mutex > itsLock(«broadcast.className»Mutex_);
                        actualReceiverList = «broadcast.stubAdapterClassSubscriberListPropertyName»;
                    }

                    for (auto clientIdIterator = actualReceiverList->cbegin(); clientIdIterator != actualReceiverList->cend(); clientIdIterator++) {
                        bool found(false);
                        {
                            std::lock_guard < std::mutex > itsLock(«broadcast.className»Mutex_);
                            found = («broadcast.stubAdapterClassSubscriberListPropertyName»->find(*clientIdIterator) != «broadcast.stubAdapterClassSubscriberListPropertyName»->end());
                        }
                        if (!_receivers || found) {
                            «broadcast.stubAdapterClassFireSelectiveMethodName»(*clientIdIterator«IF(!broadcast.outArgs.empty)», «ENDIF»«broadcast.outArgs.map["_" + elementName].join(', ')»);
                        }
                    }
                }
                template <typename _Stub, typename... _Stubs>
                void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
                    bool ok = «fInterface.dbusStubAdapterHelperClassName»::stub_->«broadcast.subscriptionRequestedMethodName»(clientId);
                    if (ok) {
                        {
                            std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                            «broadcast.stubAdapterClassSubscriberListPropertyName»->insert(clientId);
                        }
                        «fInterface.dbusStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        success = true;
                    } else {
                        success = false;
                    }
                }
                template <typename _Stub, typename... _Stubs>
                void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
                    «fInterface.dbusStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                    {
                        std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                        «broadcast.stubAdapterClassSubscriberListPropertyName»->erase(clientId);
                    }
                }
                template <typename _Stub, typename... _Stubs>
                std::shared_ptr<CommonAPI::ClientIdList> const «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                    return std::make_shared<CommonAPI::ClientIdList>(*«broadcast.stubAdapterClassSubscriberListPropertyName»);
                }
            «ELSE»
                «IF !broadcast.isErrorType(deploymentAccessor)»
                    template <typename _Stub, typename... _Stubs>
                    void «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface, true) + '& ' + elementName].join(', ')») {
                        CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<
                        «FOR outArg : broadcast.outArgs SEPARATOR ","»
                            «val String deploymentType = outArg.getDeploymentType(fInterface, true)»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                 CommonAPI::Deployable< «outArg.getTypeName(fInterface, true)», «deploymentType»>
                            «ELSE»
                                «outArg.getTypeName(fInterface, true)»
                            «ENDIF»
                        «ENDFOR»
                        >>::sendSignal(
                                *this,
                                "«broadcast.elementName»",
                                "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                        «FOR outArg : broadcast.outArgs SEPARATOR ","»
                            «val String deploymentType = outArg.getDeploymentType(fInterface, true)»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                «val String deployment = outArg.getDeploymentRef(outArg.array, broadcast, fInterface, deploymentAccessor)»
                                CommonAPI::Deployable< «outArg.getTypeName(fInterface, true)», «deploymentType»>(«outArg.name», «deployment»)
                            «ELSE»
                                «outArg.name»
                            «ENDIF»
                        «ENDFOR»
                        );
                    }
                «ENDIF»
            «ENDIF»

        «ENDFOR»
        «FOR managed : fInterface.managedInterfaces»
            template <typename _Stub, typename... _Stubs>
            bool «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubRegisterManagedMethodImpl» {
                if («managed.stubManagedSetName».find(_instance) == «managed.stubManagedSetName».end()) {
                    std::string itsAddress = "local:«managed.fullyQualifiedNameWithVersion»:" + _instance;
                    CommonAPI::DBus::DBusAddress itsDBusAddress;
                    CommonAPI::DBus::DBusAddressTranslator::get()->translate(itsAddress, itsDBusAddress);

                    std::string adapterObjectPath(CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::getDBusAddress().getObjectPath());

                    std::shared_ptr<CommonAPI::DBus::Factory> itsFactory = CommonAPI::DBus::Factory::get();

                    auto stubAdapter = itsFactory->createDBusStubAdapter(_stub, "«managed.fullyQualifiedNameWithVersion»", itsDBusAddress, CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::connection_);
                    bool isRegistered = itsFactory->registerManagedService(stubAdapter);
                    if (isRegistered) {
                        bool isExported = CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::connection_->getDBusObjectManager()->exportManagedDBusStubAdapter(adapterObjectPath, stubAdapter);
                        if (isExported) {
                            «managed.stubManagedSetName».insert(_instance);
                            return true;
                        } else {
                            itsFactory->unregisterManagedService(itsAddress);
                        }
                    }
                }
                return false;
            }
            template <typename _Stub, typename... _Stubs>
            bool «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubDeregisterManagedName»(const std::string &_instance) {
                std::string itsAddress = "local:«managed.fullyQualifiedNameWithVersion»:" + _instance;
                if («managed.stubManagedSetName».find(_instance) != «managed.stubManagedSetName».end()) {
                    std::shared_ptr<CommonAPI::DBus::Factory> itsFactory = CommonAPI::DBus::Factory::get();
                    std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> stubAdapter
                        = itsFactory->getRegisteredService(itsAddress);
                    if (stubAdapter) {
                        CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::connection_->getDBusObjectManager()->unexportManagedDBusStubAdapter(
                            CommonAPI::DBus::DBusStubAdapterHelper<_Stub, _Stubs...>::getDBusAddress().getObjectPath(), stubAdapter);
                        itsFactory->unregisterManagedService(itsAddress);
                        «managed.stubManagedSetName».erase(_instance);
                        return true;
                    }
                }
                return false;
            }

            template <typename _Stub, typename... _Stubs>
            std::set<std::string>& «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubManagedSetGetterName»() {
                return «managed.stubManagedSetName»;
            }

        «ENDFOR»

        template <typename _Stub = «fInterface.stubFullClassName», typename... _Stubs>
        class «fInterface.dbusStubAdapterClassName»
            : public «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>,
              public std::enable_shared_from_this< «fInterface.dbusStubAdapterClassName»<_Stub, _Stubs...>> {
        public:
            «fInterface.dbusStubAdapterClassName»(
                const CommonAPI::DBus::DBusAddress &_address,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                const std::shared_ptr<_Stub> &_stub)
                : CommonAPI::DBus::DBusStubAdapter(
                    _address,
                    _connection,
                    «IF !fInterface.managedInterfaces.nullOrEmpty»true«ELSE»false«ENDIF»),
                  «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>(
                    _address,
                    _connection,
                    _stub) {
            }
        };

        «fInterface.model.generateNamespaceEndDeclaration»
        «fInterface.generateVersionNamespaceEnd»

        #endif // «fInterface.defineName»_DBUS_STUB_ADAPTER_HPP_
    '''

    def private generateAttributeDispatcherDeclarations(FAttribute fAttribute, PropertyAccessor deploymentAccessor, FInterface fInterface) '''
        «FTypeGenerator::generateComments(fAttribute, false)»
        static CommonAPI::DBus::DBusGet«IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»AttributeStubDispatcher<
                «fInterface.stubFullClassName»,
                «val typeName = fAttribute.getTypeName(fInterface, true)»
                «val String deploymentType = fAttribute.getDeploymentType(fInterface, true)»
                «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                «deploymentType»«ENDIF»
                > «fAttribute.dbusGetStubDispatcherVariable»;
        «IF !fAttribute.isReadonly»
            static CommonAPI::DBus::DBusSet«IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»«IF fAttribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                    «fInterface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                    > «fAttribute.dbusSetStubDispatcherVariable»;
        «ENDIF»
    '''

    def private generateMethodDispatcherDeclarations(FMethod fMethod, FInterface fInterface, HashMap<String, Integer> counterMap, HashMap<FMethod, Integer> methodnumberMap, PropertyAccessor deploymentAccessor) '''
            «FTypeGenerator::generateComments(fMethod, false)»
            «val accessor = getAccessor(fInterface)»
            «IF !fMethod.isFireAndForget»
                «var errorReplyTypes = new LinkedList()»
                «FOR broadcast : fInterface.broadcasts»
                    «IF broadcast.isErrorType(fMethod, deploymentAccessor)»
                        «{errorReplyTypes.add(broadcast.errorReplyTypes(fMethod, deploymentAccessor));""}»
                        «broadcast.generateErrorReplyCallback(fInterface, fMethod, deploymentAccessor)»
                    «ENDIF»
                «ENDFOR»
                
                static CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                    «fInterface.stubFullClassName»,
                    std::tuple< «fMethod.allInTypes»>,
                    std::tuple< «fMethod.allOutTypes»>,
                    std::tuple< «fMethod.inArgs.getDeploymentTypes(fInterface, accessor)»>,
                    std::tuple< «IF fMethod.hasError»«fMethod.getErrorDeploymentType(true)»«ENDIF»«fMethod.outArgs.getDeploymentTypes(fInterface, accessor)»>«IF errorReplyTypes.size > 0»,«ENDIF»
                    «errorReplyTypes.map['std::function< void (' + it + ')>'].join(',\n')»

                    «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0);  methodnumberMap.put(fMethod, 0);""}»
                        > «fMethod.dbusStubDispatcherVariable»;
                    «ELSE»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                        > «fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»;
                    «ENDIF»
            «ELSE»
                static CommonAPI::DBus::DBusMethodStubDispatcher<
                    «fInterface.stubFullClassName»,
                    std::tuple< «fMethod.allInTypes»>,
                    std::tuple< «fMethod.inArgs.getDeploymentTypes(fInterface, accessor)»>
                    «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0); methodnumberMap.put(fMethod, 0);""}»
                        > «fMethod.dbusStubDispatcherVariable»;
                    «ELSE»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                        > «fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»;
                    «ENDIF»
            «ENDIF»
    '''

    def private generateBroadcastDispatcherDeclarations(FBroadcast fBroadcast, FInterface fInterface) '''
        «IF fBroadcast.selective»
            static CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
                «fInterface.stubFullClassName»,
                «fInterface.stubAdapterClassName»,
                std::tuple<>,
                std::tuple<bool>
                > «fBroadcast.dbusStubDispatcherVariableSubscribe»;

            static CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
                «fInterface.stubFullClassName»,
                «fInterface.stubAdapterClassName»,
             std::tuple<>,
                std::tuple<>
                > «fBroadcast.dbusStubDispatcherVariableUnsubscribe»;
        «ENDIF»
    '''

    def private generateAttributeDispatcherDefinitions(FAttribute fAttribute, FInterface fInterface, PropertyAccessor deploymentAccessor) '''
            «FTypeGenerator::generateComments(fAttribute, false)»
            template <typename _Stub, typename... _Stubs>
            «val typeName = fAttribute.getTypeName(fInterface, true)»
            «val String deploymentType = fAttribute.getDeploymentType(fInterface, true)»
            CommonAPI::DBus::DBusGet«IF deploymentAccessor.getPropertiesType(fInterface)==PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»AttributeStubDispatcher<
                    «fInterface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                    > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.dbusGetStubDispatcherVariable»(
                        &«fInterface.stubFullClassName»::«fAttribute.stubClassGetMethodName»
                        «IF deploymentAccessor.getPropertiesType(fInterface)!=PropertyAccessor.PropertiesType.freedesktop», "«fAttribute.dbusSignature(deploymentAccessor)»"«ENDIF»
                        «IF deploymentAccessor.hasDeployment(fAttribute)», «fAttribute.getDeploymentRef(fAttribute.array, null, fInterface, deploymentAccessor)»«ENDIF»
                        );
            «IF !fAttribute.isReadonly»
                template <typename _Stub, typename... _Stubs>
                CommonAPI::DBus::DBusSet«IF deploymentAccessor.getPropertiesType(fInterface)==PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»«IF fAttribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                        «fInterface.stubFullClassName»,
                        «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                        «deploymentType»«ENDIF»
                        > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.dbusSetStubDispatcherVariable»(
                                &«fInterface.stubFullClassName»::«fAttribute.stubClassGetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«fAttribute.stubRemoteEventClassSetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«fAttribute.stubRemoteEventClassChangedMethodName»
                                «IF fAttribute.observable»,&«fInterface.stubAdapterClassName»::«fAttribute.stubAdapterClassFireChangedMethodName»«ENDIF»
                                «IF deploymentAccessor.getPropertiesType(fInterface)!=PropertyAccessor.PropertiesType.freedesktop»,"«fAttribute.dbusSignature(deploymentAccessor)»"«ENDIF»«IF deploymentAccessor.hasDeployment(fAttribute)»,
                                «fAttribute.getDeploymentRef(fAttribute.array, null, fInterface, deploymentAccessor)»«ENDIF»
                                );
            «ENDIF»
    '''

    def private generateMethodDispatcherDefinitions(FMethod fMethod, FInterface fInterface, HashMap<String, Integer> counterMap, HashMap<FMethod, Integer> methodnumberMap, PropertyAccessor deploymentAccessor) '''

        «val accessor = getAccessor(fInterface)»
        «FTypeGenerator::generateComments(fMethod, false)»
        «IF !fMethod.isFireAndForget»
            «var errorReplyTypes = new LinkedList()»
            «var errorReplyCallbacks = new LinkedList()»
            «FOR broadcast : fInterface.broadcasts»
                «IF broadcast.isErrorType(fMethod, deploymentAccessor)»
                    «{errorReplyTypes.add(broadcast.errorReplyTypes(fMethod, deploymentAccessor));""}»
                    «{errorReplyCallbacks.add('std::bind(&' + fInterface.dbusStubAdapterClassNameInternal + '<_Stub, _Stubs...>::' +
                        broadcast.errorReplyCallbackName(deploymentAccessor) + ', ' + broadcast.errorReplyCallbackBindArgs(deploymentAccessor) + ')'
                    );""}»
                «ENDIF»
            «ENDFOR»
            template <typename _Stub, typename... _Stubs>
            CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                «fInterface.stubFullClassName»,
                std::tuple< «fMethod.allInTypes»>,
                std::tuple< «fMethod.allOutTypes»>,
                std::tuple< «fMethod.inArgs.getDeploymentTypes(fInterface, accessor)»>,
                std::tuple< «IF fMethod.hasError»«fMethod.getErrorDeploymentType(true)»«ENDIF»«fMethod.outArgs.getDeploymentTypes(fInterface, accessor)»>«IF errorReplyTypes.size > 0»,«ENDIF»
                «errorReplyTypes.map['std::function< void (' + it + ')>'].join(',\n')»

                «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0);  methodnumberMap.put(fMethod, 0);""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fMethod.dbusStubDispatcherVariable»(
                    &«fInterface.stubClassName + "::" + fMethod.elementName», "«fMethod.dbusOutSignature(deploymentAccessor)»",
                    «fMethod.getDeployments(fInterface, accessor, true, false)»,
                    «fMethod.getDeployments(fInterface, accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»);
                «ELSE»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + fMethod.elementName», "«fMethod.dbusOutSignature(deploymentAccessor)»",
                    «fMethod.getDeployments(fInterface, accessor, true, false)»,
                    «fMethod.getDeployments(fInterface, accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»);
                «ENDIF»
        «ELSE»
            template <typename _Stub, typename... _Stubs>
            CommonAPI::DBus::DBusMethodStubDispatcher<
                «fInterface.stubClassName»,
                std::tuple< «fMethod.allInTypes»>,
                std::tuple< «fMethod.inArgs.getDeploymentTypes(fInterface, accessor)»>

                «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0); methodnumberMap.put(fMethod, 0);""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fMethod.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + fMethod.elementName»,
                    «fMethod.getDeployments(fInterface, accessor, true, false)»);
                «ELSE»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + fMethod.elementName»,
                    «fMethod.getDeployments(fInterface, accessor, true, false)»);
                «ENDIF»
        «ENDIF»
    '''

    def private generateBroadcastDispatcherDefinitions(FBroadcast fBroadcast, FInterface fInterface) '''
        template <typename _Stub, typename... _Stubs>
        CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
            «fInterface.stubFullClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<bool>
            > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fBroadcast.dbusStubDispatcherVariableSubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.subscribeSelectiveMethodName», "b");

        template <typename _Stub, typename... _Stubs>
        CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
            «fInterface.stubFullClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<>
            > «fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fBroadcast.dbusStubDispatcherVariableUnsubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.unsubscribeSelectiveMethodName», "");
    '''

    def private getInterfaceHierarchy(FInterface fInterface) {
        if (fInterface.base == null) {
            fInterface.stubFullClassName
        } else {
            fInterface.stubFullClassName + ", " + fInterface.base.interfaceHierarchy
        }
    }

    def private generateDBusStubAdapterSource(FInterface fInterface, PropertyAccessor deploymentAccessor,  List<FDProvider> providers, IResource modelid) '''
        «generateCommonApiDBusLicenseHeader()»
        #include <«fInterface.headerPath»>
        #include <«fInterface.dbusStubAdapterHeaderPath»>

        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> create«fInterface.dbusStubAdapterClassName»(
                           const CommonAPI::DBus::DBusAddress &_address,
                           const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                           const std::shared_ptr<CommonAPI::StubBase> &_stub) {
            return std::make_shared< «fInterface.dbusStubAdapterClassName»<«fInterface.interfaceHierarchy»>>(_address, _connection, std::dynamic_pointer_cast<«fInterface.stubFullClassName»>(_stub));
        }

        void initialize«fInterface.dbusStubAdapterClassName»() {
             «FOR p : providers»
                 «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
                 «FOR i : p.instances.filter[target == fInterface]»
                     CommonAPI::DBus::DBusAddressTranslator::get()->insert(
                         "local:«fInterface.fullyQualifiedNameWithVersion»»:«providerAccessor.getInstanceId(i)»",
                         "«providerAccessor.getDBusServiceName(i)»",
                         "«providerAccessor.getDBusObjectPath(i)»",
                         "«providerAccessor.getDBusInterfaceName(i)»");
                 «ENDFOR»
             «ENDFOR»
            CommonAPI::DBus::Factory::get()->registerStubAdapterCreateMethod(
                «fInterface.elementName»::getInterface(), &create«fInterface.dbusStubAdapterClassName»);
        }

        INITIALIZER(register«fInterface.dbusStubAdapterClassName») {
            CommonAPI::DBus::Factory::get()->registerInterface(initialize«fInterface.dbusStubAdapterClassName»);
        }

        «fInterface.model.generateNamespaceEndDeclaration»
        «fInterface.generateVersionNamespaceEnd»
    '''

    def dbusDispatcherTableEntry(FInterface fInterface, String methodName, String dbusSignature, String memberFunctionName) '''
        «fInterface.dbusStubAdapterHelperClassName»::addStubDispatcher({ "«methodName»", "«dbusSignature»" }, &«memberFunctionName»);
    '''

    def private getAbsoluteNamespace(FModelElement fModelElement) {
        fModelElement.model.name.replace('.', '::')
    }

    def private dbusStubAdapterHeaderFile(FInterface fInterface) {
        fInterface.elementName + "DBusStubAdapter.hpp"
    }

    def private dbusStubAdapterHeaderPath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.dbusStubAdapterHeaderFile
    }

    def private dbusStubAdapterSourceFile(FInterface fInterface) {
        fInterface.elementName + "DBusStubAdapter.cpp"
    }

    def private dbusStubAdapterSourcePath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.dbusStubAdapterSourceFile
    }

    def private dbusStubAdapterClassName(FInterface fInterface) {
        fInterface.elementName + 'DBusStubAdapter'
    }

    def private dbusStubAdapterClassNameInternal(FInterface fInterface) {
        fInterface.dbusStubAdapterClassName + 'Internal'
    }

    def private dbusStubAdapterHelperClassName(FInterface fInterface) {
        fInterface.elementName + 'DBusStubAdapterHelper'
    }

    def private getAllInTypes(FMethod fMethod) {
        fMethod.inArgs.map[getTypeName(fMethod, true)].join(', ')
    }

    def private getAllOutTypes(FMethod fMethod) {
        var types = fMethod.outArgs.map[getTypeName(fMethod, true)].join(', ')

        if (fMethod.hasError) {
            if (!fMethod.outArgs.empty)
                types = ', ' + types
            types = fMethod.getErrorNameReference(fMethod.eContainer) + types
        }

        return types
    }

    def private dbusStubDispatcherVariable(FMethod fMethod) {
        fMethod.elementName.toFirstLower + 'StubDispatcher'
    }

    def private dbusGetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.dbusGetMethodName + 'StubDispatcher'
    }

    def private dbusSetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.dbusSetMethodName + 'StubDispatcher'
    }

    def private dbusStubDispatcherVariable(FBroadcast fBroadcast) {
        var returnVal = fBroadcast.elementName.toFirstLower

        if(fBroadcast.selective)
            returnVal = returnVal + 'Selective'

        returnVal = returnVal + 'StubDispatcher'

        return returnVal
    }

    def private dbusStubDispatcherVariableSubscribe(FBroadcast fBroadcast) {
        "subscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }

    def private dbusStubDispatcherVariableUnsubscribe(FBroadcast fBroadcast) {
        "unsubscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }

    var nextSectionInDispatcherNeedsComma = false;

    def void setNextSectionInDispatcherNeedsComma(boolean newValue) {
        nextSectionInDispatcherNeedsComma = newValue
    }

    def private generateFireChangedMethodBody(FAttribute attribute, FInterface fInterface, PropertyAccessor deploymentAccessor) '''
        «val String deploymentType = attribute.getDeploymentType(fInterface, true)»
        «val String deployment = attribute.getDeploymentRef(attribute.array, null, fInterface, deploymentAccessor)»
        «IF deploymentAccessor.getPropertiesType(attribute.containingInterface) == PropertyAccessor.PropertiesType.freedesktop»
            CommonAPI::DBus::DBusStubFreedesktopPropertiesSignalHelper<
                «attribute.getTypeName(fInterface, true)»,
                «deploymentType»
            > ::sendPropertiesChangedSignal(
                    *this,
                    "«attribute.elementName»",
                    value,
                    «deployment»
            );
        «ELSE»
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
            CommonAPI::Deployable< «attribute.getTypeName(attribute, true)», «deploymentType»> deployedValue(value, «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
            «ENDIF»
            CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                CommonAPI::Deployable<
                    «attribute.getTypeName(fInterface, true)»,
                    «deploymentType»
                >
            «ELSE»
                «attribute.getTypeName(fInterface, true)»
            «ENDIF»
            >>
                ::sendSignal(
                    *this,
                    "«attribute.dbusSignalName»",
                    "«attribute.dbusSignature(deploymentAccessor)»",
                    «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»deployedValue«ELSE»value«ENDIF»

            );
        «ENDIF»
    '''

    def private generateStubAttributeTableInitializer(FInterface fInterface, PropertyAccessor deploymentAccessor) '''
        «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop && !fInterface.attributes.empty»
            «FOR attribute : fInterface.attributes»
                «fInterface.generateStubAttributeTableInitializerEntry(attribute)»
            «ENDFOR»
        «ENDIF»
    '''

    def private generateStubAttributeTableInitializerEntry(FInterface fInterface, FAttribute fAttribute) '''
        «fInterface.dbusStubAdapterHelperClassName»::addAttributeDispatcher("«fAttribute.elementName»",
                &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.dbusGetStubDispatcherVariable»,
                «IF fAttribute.readonly»(CommonAPI::DBus::DBusSetFreedesktopAttributeStubDispatcher<«fInterface.stubFullClassName», int>*)NULL«ELSE»&«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.dbusSetStubDispatcherVariable»«ENDIF»
            );
    '''
    
    def private generateErrorReplyCallback(FBroadcast fBroadcast, FInterface fInterface, FMethod fMethod, PropertyAccessor deploymentAccessor) '''
            
        static void «fBroadcast.errorReplyCallbackName(deploymentAccessor)»(«fBroadcast.generateErrorReplyCallbackSignature(fMethod, deploymentAccessor)») {
            «IF fBroadcast.errorArgs(deploymentAccessor).size > 1»
                auto args = std::make_tuple(
                    «fBroadcast.errorArgs(deploymentAccessor).map[it.getDeployable(fInterface, deploymentAccessor) + '(' + '_' + it.elementName + ', ' + getDeploymentRef(it.array, fBroadcast, fInterface, deploymentAccessor) + ')'].join(",\n")  + ");"»
            «ELSE»
                auto args = std::make_tuple();
            «ENDIF»
            «fMethod.dbusStubDispatcherVariable».sendErrorReply(_callId, "«fBroadcast.dbusErrorReplyOutSignature(fMethod, deploymentAccessor)»", _«fBroadcast.errorName(deploymentAccessor)», args);
        }
    '''
    
}
