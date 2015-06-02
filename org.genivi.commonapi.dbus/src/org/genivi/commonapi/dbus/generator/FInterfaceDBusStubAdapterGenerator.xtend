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

class FInterfaceDBusStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

    def generateDBusStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor, IResource modelid) {
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterHeaderPath, PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, fInterface.generateDBusStubAdapterHeader(deploymentAccessor, modelid))
        fileSystemAccess.generateFile(fInterface.dbusStubAdapterSourcePath,  PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, fInterface.generateDBusStubAdapterSource(deploymentAccessor, modelid))
    }

    def private generateDBusStubAdapterHeader(FInterface fInterface, PropertyAccessor deploymentAccessor, IResource modelid) '''
        «generateCommonApiLicenseHeader(fInterface, modelid)»
        «FTypeGenerator::generateComments(fInterface, false)»
        #ifndef «fInterface.defineName»_DBUS_STUB_ADAPTER_HPP_
        #define «fInterface.defineName»_DBUS_STUB_ADAPTER_HPP_

        #include <«fInterface.stubHeaderPath»>
        «IF fInterface.base != null»
        #include <«fInterface.base.dbusStubAdapterHeaderPath»>
        «ENDIF»

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        «IF !fInterface.managedInterfaces.empty»
        #include <CommonAPI/DBus/DBusAddressTranslator.hpp>
        «ENDIF»
        #include <CommonAPI/DBus/DBusFactory.hpp>
        «IF !fInterface.managedInterfaces.empty»
        #include <CommonAPI/DBus/DBusObjectManager.hpp>
        «ENDIF»
        #include <CommonAPI/DBus/DBusStubAdapterHelper.hpp>
        #include <CommonAPI/DBus/DBusStubAdapter.hpp>
        «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»
        #include <CommonAPI/DBus/DBusFreedesktopStubAdapterHelper.hpp>
        «ENDIF»
        «IF !fInterface.attributes.filter[isVariant].empty»
        #include <CommonAPI/DBus/DBusDeployment.hpp>
        «ENDIF»
        
        #undef COMMONAPI_INTERNAL_COMPILATION

        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        typedef CommonAPI::DBus::DBusStubAdapterHelper<«fInterface.stubClassName»> «fInterface.dbusStubAdapterHelperClassName»;

        class «fInterface.dbusStubAdapterClassNameInternal»
            : public virtual «fInterface.stubAdapterClassName»,
              public «fInterface.dbusStubAdapterHelperClassName»«IF fInterface.base != null»,
              public «fInterface.base.getTypeCollectionName(fInterface)»DBusStubAdapterInternal«ENDIF»
        {
        public:
            «fInterface.dbusStubAdapterClassNameInternal»(
                    const CommonAPI::DBus::DBusAddress &_address,
                    const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                    const std::shared_ptr<CommonAPI::StubBase> &_stub);

            ~«fInterface.dbusStubAdapterClassNameInternal»();

            virtual const bool hasFreedesktopProperties();

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
                    void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface, true) + '& ' + elementName].join(', ')»);
                «ENDIF»
            «ENDFOR»

            «FOR managed: fInterface.managedInterfaces»
                «managed.stubRegisterManagedMethod»;
                bool «managed.stubDeregisterManagedName»(const std::string&);
                std::set<std::string>& «managed.stubManagedSetGetterName»();
            «ENDFOR»

            const «fInterface.dbusStubAdapterHelperClassName»::StubDispatcherTable& getStubDispatcherTable();
            const CommonAPI::DBus::StubAttributeTable& getStubAttributeTable();

            void deactivateManagedInstances();
            
            «IF fInterface.base != null»
            virtual const CommonAPI::Address &getAddress() const {
                return DBusStubAdapter::getAddress();
            }

            virtual void init(std::shared_ptr<DBusStubAdapter> instance) {
                return «fInterface.dbusStubAdapterHelperClassName»::init(instance);
            }

            virtual void deinit() {
                return «fInterface.dbusStubAdapterHelperClassName»::deinit();
            }

            virtual bool onInterfaceDBusMessage(const CommonAPI::DBus::DBusMessage& dbusMessage) {
                return «fInterface.dbusStubAdapterHelperClassName»::onInterfaceDBusMessage(dbusMessage);
            }

            virtual bool onInterfaceDBusFreedesktopPropertiesMessage(const CommonAPI::DBus::DBusMessage& dbusMessage) {
                return «fInterface.dbusStubAdapterHelperClassName»::onInterfaceDBusFreedesktopPropertiesMessage(dbusMessage);
            }
            «ENDIF»

        static CommonAPI::DBus::DBusGetAttributeStubDispatcher<
                «fInterface.stubClassName»,
                CommonAPI::Version
                > get«fInterface.elementName»InterfaceVersionStubDispatcher;

        «FOR attribute : fInterface.attributes»
            «generateAttributeDispatcherDeclarations(attribute, deploymentAccessor, fInterface)»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR attribute : fInterface.inheritedAttributes»
                «generateAttributeDispatcherDeclarations(attribute, deploymentAccessor, fInterface)»
            «ENDFOR»
            #endif
        «ENDIF»

        «var counterMap = new HashMap<String, Integer>()»
        «var methodnumberMap = new HashMap<FMethod, Integer>()»
        «FOR method : fInterface.methods»
            «generateMethodDispatcherDeclarations(method, fInterface, counterMap, methodnumberMap)»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR method : fInterface.inheritedMethods»
                «generateMethodDispatcherDeclarations(method, fInterface, counterMap, methodnumberMap)»
            «ENDFOR»
            #endif
        «ENDIF»

        «FOR broadcast: fInterface.broadcasts»
            «generateBroadcastDispatcherDeclarations(broadcast, fInterface)»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR broadcast: fInterface.inheritedBroadcasts»
                «generateBroadcastDispatcherDeclarations(broadcast, fInterface)»
            «ENDFOR»
            #endif
        «ENDIF»

         protected:
            virtual const char* getMethodsDBusIntrospectionXmlData() const;

         private:
            «FOR managed: fInterface.managedInterfaces»
                std::set<std::string> «managed.stubManagedSetName»;
            «ENDFOR»
            «fInterface.dbusStubAdapterHelperClassName»::StubDispatcherTable stubDispatcherTable_;
            CommonAPI::DBus::StubAttributeTable stubAttributeTable_;
        };

        class «fInterface.dbusStubAdapterClassName»
            : public «fInterface.dbusStubAdapterClassNameInternal»,
              public std::enable_shared_from_this<«fInterface.dbusStubAdapterClassName»> {
        public:
            «fInterface.dbusStubAdapterClassName»(
            	const CommonAPI::DBus::DBusAddress &_address,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                const std::shared_ptr<CommonAPI::StubBase> &_stub)
            	: CommonAPI::DBus::DBusStubAdapter(
            		_address, 
            		_connection,
                    «IF !fInterface.managedInterfaces.nullOrEmpty»true«ELSE»false«ENDIF»),
                  «fInterface.dbusStubAdapterClassNameInternal»(
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
                «fInterface.stubClassName»,
                «fAttribute.getTypeName(fInterface, true)»«IF fAttribute.isVariant»,
                CommonAPI::DBus::VariantDeployment<>«ENDIF»
                > «fAttribute.dbusGetStubDispatcherVariable»;
        «IF !fAttribute.isReadonly»
            static CommonAPI::DBus::DBusSet«IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»«IF fAttribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                    «fInterface.stubClassName»,
                    «fAttribute.getTypeName(fInterface, true)»«IF fAttribute.isVariant»,
                    CommonAPI::DBus::VariantDeployment<>«ENDIF»
                    > «fAttribute.dbusSetStubDispatcherVariable»;
        «ENDIF»
    '''

    def private generateMethodDispatcherDeclarations(FMethod fMethod, FInterface fInterface, HashMap<String, Integer> counterMap, HashMap<FMethod, Integer> methodnumberMap) '''
            «FTypeGenerator::generateComments(fMethod, false)»
            «IF !fMethod.isFireAndForget»
                static CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«fMethod.allInTypes»>,
                    std::tuple<«fMethod.allOutTypes»>
                    «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0);  methodnumberMap.put(fMethod, 0);""}»
                        > «fMethod.dbusStubDispatcherVariable»;
                    «ELSE»
                        «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                        > «fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»;
                    «ENDIF»
            «ELSE»
                static CommonAPI::DBus::DBusMethodStubDispatcher<
                    «fInterface.stubClassName»,
                    std::tuple<«fMethod.allInTypes»>
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
                «fInterface.stubClassName»,
                «fInterface.stubAdapterClassName»,
                std::tuple<>,
                std::tuple<bool>
                > «fBroadcast.dbusStubDispatcherVariableSubscribe»;

            static CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
                «fInterface.stubClassName»,
                «fInterface.stubAdapterClassName»,
             std::tuple<>,
                std::tuple<>
                > «fBroadcast.dbusStubDispatcherVariableUnsubscribe»;
        «ENDIF»
    '''

    def private generateAttributeDispatcherDefinitions(FAttribute fAttribute, FInterface fInterface, PropertyAccessor deploymentAccessor) '''
            «FTypeGenerator::generateComments(fAttribute, false)»
            CommonAPI::DBus::DBusGet«IF deploymentAccessor.getPropertiesType(fInterface)==PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»AttributeStubDispatcher<
                    «fInterface.stubClassName»,
                    «fAttribute.getTypeName(fInterface, true)»«IF fAttribute.isVariant»,
                    CommonAPI::DBus::VariantDeployment<>«ENDIF»
                    > «fInterface.dbusStubAdapterClassNameInternal»::«fAttribute.dbusGetStubDispatcherVariable»(&«fInterface.stubClassName»::«fAttribute.stubClassGetMethodName»«IF deploymentAccessor.getPropertiesType(fInterface)!=PropertyAccessor.PropertiesType.freedesktop», "«fAttribute.dbusSignature(deploymentAccessor)»"«ENDIF»);
            «IF !fAttribute.isReadonly»
                CommonAPI::DBus::DBusSet«IF deploymentAccessor.getPropertiesType(fInterface)==PropertyAccessor.PropertiesType.freedesktop»Freedesktop«ENDIF»«IF fAttribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                        «fInterface.stubClassName»,
                        «fAttribute.getTypeName(fInterface, true)»«IF fAttribute.isVariant»,
                        CommonAPI::DBus::VariantDeployment<>«ENDIF»
                        > «fInterface.dbusStubAdapterClassNameInternal»::«fAttribute.dbusSetStubDispatcherVariable»(
                                &«fInterface.stubClassName»::«fAttribute.stubClassGetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«fAttribute.stubRemoteEventClassSetMethodName»,
                                &«fInterface.stubRemoteEventClassName»::«fAttribute.stubRemoteEventClassChangedMethodName»
                                «IF fAttribute.observable»,&«fInterface.stubAdapterClassName»::«fAttribute.stubAdapterClassFireChangedMethodName»«ENDIF»
                                «IF deploymentAccessor.getPropertiesType(fInterface)!=PropertyAccessor.PropertiesType.freedesktop»,"«fAttribute.dbusSignature(deploymentAccessor)»"«ENDIF»
                                );
            «ENDIF»
    '''

    def private generateMethodDispatcherDefinitions(FMethod fMethod, FInterface fInterface, HashMap<String, Integer> counterMap, HashMap<FMethod, Integer> methodnumberMap, PropertyAccessor deploymentAccessor) '''
        «FTypeGenerator::generateComments(fMethod, false)»
        «IF !fMethod.isFireAndForget»
            CommonAPI::DBus::DBusMethodWithReplyStubDispatcher<
                «fInterface.stubClassName»,
                std::tuple<«fMethod.allInTypes»>,
                std::tuple<«fMethod.allOutTypes»>
                «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0);  methodnumberMap.put(fMethod, 0);""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»::«fMethod.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + fMethod.elementName», "«fMethod.dbusOutSignature(deploymentAccessor)»", std::tuple<«fMethod.allTypes»>());
                «ELSE»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»::«fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + fMethod.elementName», "«fMethod.dbusOutSignature(deploymentAccessor)»", std::tuple<«fMethod.allTypes»>());
                «ENDIF»
        «ELSE»
            CommonAPI::DBus::DBusMethodStubDispatcher<
                «fInterface.stubClassName»,
                std::tuple<«fMethod.allInTypes»>
                «IF !(counterMap.containsKey(fMethod.dbusStubDispatcherVariable))»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, 0); methodnumberMap.put(fMethod, 0);""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»::«fMethod.dbusStubDispatcherVariable»(&«fInterface.stubClassName + "::" + fMethod.elementName»);
                «ELSE»
                    «{counterMap.put(fMethod.dbusStubDispatcherVariable, counterMap.get(fMethod.dbusStubDispatcherVariable) + 1);  methodnumberMap.put(fMethod, counterMap.get(fMethod.dbusStubDispatcherVariable));""}»
                    > «fInterface.dbusStubAdapterClassNameInternal»::«fMethod.dbusStubDispatcherVariable»«Integer::toString(counterMap.get(fMethod.dbusStubDispatcherVariable))»(&«fInterface.stubClassName + "::" + fMethod.elementName»);
                «ENDIF»
        «ENDIF»
    '''

    def private generateBroadcastDispatcherDefinitions(FBroadcast fBroadcast, FInterface fInterface) '''
        CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
            «fInterface.stubClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<bool>
            > «fInterface.dbusStubAdapterClassNameInternal»::«fBroadcast.dbusStubDispatcherVariableSubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.subscribeSelectiveMethodName», "b");

        CommonAPI::DBus::DBusMethodWithReplyAdapterDispatcher<
            «fInterface.stubClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<>
            > «fInterface.dbusStubAdapterClassNameInternal»::«fBroadcast.dbusStubDispatcherVariableUnsubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.unsubscribeSelectiveMethodName», "");
    '''

    def private generateDBusStubAdapterSource(FInterface fInterface, PropertyAccessor deploymentAccessor, IResource modelid) '''
        «generateCommonApiLicenseHeader(fInterface, modelid)»
        #include <«fInterface.headerPath»>
        #include <«fInterface.dbusStubAdapterHeaderPath»>
        
        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> create«fInterface.dbusStubAdapterClassName»(
                           const CommonAPI::DBus::DBusAddress &_address,
                           const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                           const std::shared_ptr<CommonAPI::StubBase> &_stub) {
            return std::make_shared<«fInterface.dbusStubAdapterClassName»>(_address, _connection, _stub);
        }

        INITIALIZER(register«fInterface.dbusStubAdapterClassName») {
            CommonAPI::DBus::Factory::get()->registerStubAdapterCreateMethod(
            	«fInterface.elementName»::getInterface(), &create«fInterface.dbusStubAdapterClassName»);
        }

        «fInterface.dbusStubAdapterClassNameInternal»::~«fInterface.dbusStubAdapterClassNameInternal»() {
            deactivateManagedInstances();
            «fInterface.dbusStubAdapterHelperClassName»::deinit();
        }

        void «fInterface.dbusStubAdapterClassNameInternal»::deactivateManagedInstances() {
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

        const char* «fInterface.dbusStubAdapterClassNameInternal»::getMethodsDBusIntrospectionXmlData() const {
            static const std::string introspectionData =
                «IF fInterface.base != null»
                    std::string(«fInterface.base.dbusStubAdapterClassNameInternal»::getMethodsDBusIntrospectionXmlData()) +
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
                    «FTypeGenerator::generateComments(broadcast, false)»
                    "<signal name=\"«broadcast.elementName»\">\n"
                        «FOR outArg : broadcast.outArgs»
                            "<arg name=\"«outArg.elementName»\" type=\"«outArg.getTypeDbusSignature(deploymentAccessor)»\" />\n"
                        «ENDFOR»
                    "</signal>\n"
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

        CommonAPI::DBus::DBusGetAttributeStubDispatcher<
                «fInterface.stubClassName»,
                CommonAPI::Version
                > «fInterface.dbusStubAdapterClassNameInternal»::get«fInterface.elementName»InterfaceVersionStubDispatcher(&«fInterface.stubClassName»::getInterfaceVersion, "uu");

        «FOR attribute : fInterface.attributes»
            «generateAttributeDispatcherDefinitions(attribute, fInterface, deploymentAccessor)»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR attribute : fInterface.inheritedAttributes»
                «generateAttributeDispatcherDefinitions(attribute, fInterface, deploymentAccessor)»
            «ENDFOR»
            #endif
        «ENDIF»

        «var counterMap = new HashMap<String, Integer>()»
        «var methodnumberMap = new HashMap<FMethod, Integer>()»
        «FOR method : fInterface.methods»
            «generateMethodDispatcherDefinitions(method, fInterface, counterMap, methodnumberMap, deploymentAccessor)»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR method : fInterface.inheritedMethods»
                «generateMethodDispatcherDefinitions(method, fInterface, counterMap, methodnumberMap, deploymentAccessor)»
            «ENDFOR»
            #endif
        «ENDIF»

        «FOR attribute : fInterface.attributes.filter[isObservable()]»
            «FTypeGenerator::generateComments(attribute, false)»
            void «fInterface.dbusStubAdapterClassNameInternal»::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(fInterface, true)»& value) {
                «attribute.generateFireChangedMethodBody(deploymentAccessor)»
            }
        «ENDFOR»

        «FOR broadcast: fInterface.broadcasts»
            «FTypeGenerator::generateComments(broadcast, false)»
            «IF broadcast.selective»
                «generateBroadcastDispatcherDefinitions(broadcast, fInterface)»

                void «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, fInterface)») {
                    std::shared_ptr<CommonAPI::DBus::DBusClientId> dbusClient = std::dynamic_pointer_cast<CommonAPI::DBus::DBusClientId, CommonAPI::ClientId>(_client);

                    if(dbusClient)
                    {
                        CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«broadcast.outArgs.map[getTypeName(fInterface, true)].join(', ')»>>
                            ::sendSignal(
                                dbusClient->getDBusId(),
                                *this,
                                "«broadcast.elementName»",
                                "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                                «broadcast.outArgs.map["_" + elementName].join(', ')»
                        );
                    }
                }

                void «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, fInterface, false)») {
                    std::shared_ptr<CommonAPI::ClientIdList> actualReceiverList = _receivers;

                    if (!_receivers)
                        actualReceiverList = «broadcast.stubAdapterClassSubscriberListPropertyName»;

                    for (auto clientIdIterator = actualReceiverList->cbegin(); clientIdIterator != actualReceiverList->cend(); clientIdIterator++) {
                        if (!_receivers || «broadcast.stubAdapterClassSubscriberListPropertyName»->find(*clientIdIterator) != «broadcast.stubAdapterClassSubscriberListPropertyName»->end()) {
                            «broadcast.stubAdapterClassFireSelectiveMethodName»(*clientIdIterator«IF(!broadcast.outArgs.empty)», «ENDIF»«broadcast.outArgs.map["_" + elementName].join(', ')»);
                        }
                    }
                }

                void «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
                    bool ok = stub_->«broadcast.subscriptionRequestedMethodName»(clientId);
                    if (ok) {
                        «broadcast.stubAdapterClassSubscriberListPropertyName»->insert(clientId);
                        stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        success = true;
                    } else {
                        success = false;
                    }
                }


                void «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
                    «broadcast.stubAdapterClassSubscriberListPropertyName»->erase(clientId);
                    stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                }

                std::shared_ptr<CommonAPI::ClientIdList> const «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    return «broadcast.stubAdapterClassSubscriberListPropertyName»;
                }

            «ELSE»
                void «fInterface.dbusStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(fInterface, true) + '& ' + elementName].join(', ')») {
                    CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«broadcast.outArgs.map[getTypeName(fInterface, true)].join(', ')»>>
                            ::sendSignal(
                                *this,
                                "«broadcast.elementName»",
                                "«broadcast.dbusSignature(deploymentAccessor)»"«IF broadcast.outArgs.size > 0»,«ENDIF»
                                «broadcast.outArgs.map[elementName].join(', ')»
                        );
                }
            «ENDIF»
        «ENDFOR»

        «IF fInterface.base != null»
            #ifdef WIN32
            «FOR broadcast: fInterface.inheritedBroadcasts.filter[selective]»
                «generateBroadcastDispatcherDefinitions(broadcast, fInterface)»
            «ENDFOR»
            #endif
        «ENDIF»

        const «fInterface.dbusStubAdapterHelperClassName»::StubDispatcherTable& «fInterface.dbusStubAdapterClassNameInternal»::getStubDispatcherTable() {
            return stubDispatcherTable_;
        }

        const CommonAPI::DBus::StubAttributeTable& «fInterface.dbusStubAdapterClassNameInternal»::getStubAttributeTable() {
            return stubAttributeTable_;
        }
        «FOR managed : fInterface.managedInterfaces»
            bool «fInterface.dbusStubAdapterClassNameInternal»::«managed.stubRegisterManagedMethodImpl» {
                if («managed.stubManagedSetName».find(_instance) == «managed.stubManagedSetName».end()) {
                	std::string itsAddress = "local:«managed.fullyQualifiedName»:" + _instance;
                    CommonAPI::DBus::DBusAddress itsDBusAddress;
                    CommonAPI::DBus::DBusAddressTranslator::get()->translate(itsAddress, itsDBusAddress);

                    std::string objectPath(itsDBusAddress.getObjectPath());
                    std::string adapterObjectPath(getDBusAddress().getObjectPath());

                    if (objectPath.compare(0, adapterObjectPath.length(), adapterObjectPath) == 0) {
                    	std::shared_ptr<CommonAPI::DBus::Factory> itsFactory = CommonAPI::DBus::Factory::get();

                        auto stubAdapter = itsFactory->createDBusStubAdapter(_stub, "«managed.fullyQualifiedName»", itsDBusAddress, connection_);
                        bool isRegistered = itsFactory->registerManagedService(stubAdapter);
                        if (isRegistered) {
                            bool isExported = connection_->getDBusObjectManager()->exportManagedDBusStubAdapter(adapterObjectPath, stubAdapter);
                            if (isExported) {
                                «managed.stubManagedSetName».insert(_instance);
                                return true;
                            } else {
                                itsFactory->unregisterManagedService(itsAddress);
                            }
                        }
                    }
                }
                return false;
            }

            bool «fInterface.dbusStubAdapterClassNameInternal»::«managed.stubDeregisterManagedName»(const std::string &_instance) {
                std::string itsAddress = "local:«managed.fullyQualifiedName»:" + _instance;
                if («managed.stubManagedSetName».find(_instance) != «managed.stubManagedSetName».end()) {
                    std::shared_ptr<CommonAPI::DBus::Factory> itsFactory = CommonAPI::DBus::Factory::get();
                    std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> stubAdapter
                        = itsFactory->getRegisteredService(itsAddress);
                    if (stubAdapter) {
                        connection_->getDBusObjectManager()->unexportManagedDBusStubAdapter(
                            getDBusAddress().getObjectPath(), stubAdapter);
                        itsFactory->unregisterManagedService(itsAddress);
                        «managed.stubManagedSetName».erase(_instance);
                        return true;
                    }
                }
                return false;
            }

            std::set<std::string>& «fInterface.dbusStubAdapterClassNameInternal»::«managed.stubManagedSetGetterName»() {
                return «managed.stubManagedSetName»;
            }
        «ENDFOR»

        «fInterface.dbusStubAdapterClassNameInternal»::«fInterface.dbusStubAdapterClassNameInternal»(
                const CommonAPI::DBus::DBusAddress &_address,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection,
                const std::shared_ptr<CommonAPI::StubBase> &_stub)
        	: CommonAPI::DBus::DBusStubAdapter(_address, _connection,«IF !fInterface.managedInterfaces.nullOrEmpty»true«ELSE»false«ENDIF»),
              «fInterface.dbusStubAdapterHelperClassName»(_address, _connection, std::dynamic_pointer_cast<«fInterface.stubClassName»>(_stub), «IF !fInterface.managedInterfaces.nullOrEmpty»true«ELSE»false«ENDIF»),
              «IF fInterface.base != null»
              «fInterface.base.dbusStubAdapterClassNameInternal»(_address, _connection, _stub),
              «ENDIF»
              «setNextSectionInDispatcherNeedsComma(false)»
              stubDispatcherTable_({
                    «IF deploymentAccessor.getPropertiesType(fInterface) != PropertyAccessor.PropertiesType.freedesktop»
                        «FOR attribute : fInterface.attributes SEPARATOR ','»
                            «FTypeGenerator::generateComments(attribute, false)»
                            «dbusDispatcherTableEntry(fInterface, attribute.dbusGetMethodName, "", attribute.dbusGetStubDispatcherVariable)»
                            «IF !attribute.isReadonly»
                                , «dbusDispatcherTableEntry(fInterface, attribute.dbusSetMethodName, attribute.dbusSignature(deploymentAccessor), attribute.dbusSetStubDispatcherVariable)»
                            «ENDIF»
                            «setNextSectionInDispatcherNeedsComma(true)»
                        «ENDFOR»
                    «ENDIF»
                    «IF nextSectionInDispatcherNeedsComma && !fInterface.methods.empty»,«ENDIF»
                    «FOR method : fInterface.methods SEPARATOR ','»
                        «FTypeGenerator::generateComments(method, false)»
                        «IF methodnumberMap.get(method)==0»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable)»
                        «ELSE»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable+methodnumberMap.get(method))»
                        «ENDIF»
                        «setNextSectionInDispatcherNeedsComma(true)»
                    «ENDFOR»
                    «IF nextSectionInDispatcherNeedsComma && fInterface.hasSelectiveBroadcasts»,«ENDIF»
                    «FOR broadcast : fInterface.broadcasts.filter[selective] SEPARATOR ','»
                        «dbusDispatcherTableEntry(fInterface, broadcast.subscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableSubscribe)»,
                        «dbusDispatcherTableEntry(fInterface, broadcast.unsubscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableUnsubscribe)»
                        «setNextSectionInDispatcherNeedsComma(true)»
                    «ENDFOR»
                    «IF fInterface.base != null»
                    #ifdef WIN32
                    «IF deploymentAccessor.getPropertiesType(fInterface) != PropertyAccessor.PropertiesType.freedesktop»
                        «IF nextSectionInDispatcherNeedsComma && !fInterface.inheritedAttributes.empty»,«ENDIF»
                        «FOR attribute : fInterface.inheritedAttributes SEPARATOR ','»
                            «FTypeGenerator::generateComments(attribute, false)»
                            «dbusDispatcherTableEntry(fInterface, attribute.dbusGetMethodName, "", attribute.dbusGetStubDispatcherVariable)»
                            «IF !attribute.isReadonly»
                                , «dbusDispatcherTableEntry(fInterface, attribute.dbusSetMethodName, attribute.dbusSignature(deploymentAccessor), attribute.dbusSetStubDispatcherVariable)»
                            «ENDIF»
                            «setNextSectionInDispatcherNeedsComma(true)»
                        «ENDFOR»
                    «ENDIF»
                    «IF nextSectionInDispatcherNeedsComma && !fInterface.inheritedMethods.empty»,«ENDIF»
                    «FOR method : fInterface.inheritedMethods SEPARATOR ','»
                        «FTypeGenerator::generateComments(method, false)»
                        «IF methodnumberMap.get(method)==0»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable)»
                        «ELSE»
                        «dbusDispatcherTableEntry(fInterface, method.elementName, method.dbusInSignature(deploymentAccessor), method.dbusStubDispatcherVariable+methodnumberMap.get(method))»
                        «ENDIF»
                        «setNextSectionInDispatcherNeedsComma(true)»
                    «ENDFOR»
                    «IF nextSectionInDispatcherNeedsComma && !fInterface.inheritedBroadcasts.filter[selective].empty»,«ENDIF»
                    «FOR broadcast : fInterface.inheritedBroadcasts.filter[selective] SEPARATOR ','»
                        «dbusDispatcherTableEntry(fInterface, broadcast.subscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableSubscribe)»,
                        «dbusDispatcherTableEntry(fInterface, broadcast.unsubscribeSelectiveMethodName, "", broadcast.dbusStubDispatcherVariableUnsubscribe)»
                    «ENDFOR»
                    #endif
                    «ENDIF»
                    }),
                stubAttributeTable_(«fInterface.generateStubAttributeTableInitializer(deploymentAccessor)») {
            «FOR broadcast : fInterface.broadcasts»
                «IF broadcast.selective»
                    «broadcast.getStubAdapterClassSubscriberListPropertyName» = std::make_shared<CommonAPI::ClientIdList>();
                «ENDIF»
            «ENDFOR»

            «IF fInterface.base != null»
                #ifdef WIN32
                stubDispatcherTable_.insert({ { "getInterfaceVersion", "" }, &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::get«fInterface.elementName»InterfaceVersionStubDispatcher });
                #else
                auto parentDispatcherTable = «fInterface.base.dbusStubAdapterClassNameInternal»::getStubDispatcherTable();
                stubDispatcherTable_.insert(parentDispatcherTable.begin(), parentDispatcherTable.end());

                auto interfaceVersionGetter = stubDispatcherTable_.find({ "getInterfaceVersion", "" });
                if(interfaceVersionGetter != stubDispatcherTable_.end()) {
                    interfaceVersionGetter->second = &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::get«fInterface.elementName»InterfaceVersionStubDispatcher;
                } else {
                    stubDispatcherTable_.insert({ { "getInterfaceVersion", "" }, &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::get«fInterface.elementName»InterfaceVersionStubDispatcher });
                }

                auto parentAttributeTable = «fInterface.base.dbusStubAdapterClassNameInternal»::getStubAttributeTable();
                stubAttributeTable_.insert(parentAttributeTable.begin(), parentAttributeTable.end());

                #endif
            «ELSE»
               stubDispatcherTable_.insert({ { "getInterfaceVersion", "" }, &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::get«fInterface.elementName»InterfaceVersionStubDispatcher });
            «ENDIF»
        }

        const bool «fInterface.dbusStubAdapterClassNameInternal»::hasFreedesktopProperties() {
            return «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»true«ELSE»false«ENDIF»;
        }

        «fInterface.model.generateNamespaceEndDeclaration»
        «fInterface.generateVersionNamespaceEnd»
    '''

    def dbusDispatcherTableEntry(FInterface fInterface, String methodName, String dbusSignature, String memberFunctionName) '''
        { { "«methodName»", "«dbusSignature»" }, &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::«memberFunctionName» }
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
    
    def private getAllTypes(FMethod fMethod) {
    	var allTypes = getAllInTypes(fMethod)
    	if (fMethod.hasError || !fMethod.outArgs.empty) {
    		if (!fMethod.inArgs.empty) 
    			allTypes = allTypes + ", "
    		allTypes = allTypes + getAllOutTypes(fMethod)
    	}
    	return allTypes
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

    def private generateFireChangedMethodBody(FAttribute attribute, PropertyAccessor deploymentAccessor) '''
        «val typeName = attribute.getTypeName(attribute.containingInterface, true)»
        «IF attribute.isVariant»CommonAPI::Deployable<«typeName», CommonAPI::DBus::VariantDeployment<>> deployedValue(value, nullptr);«ENDIF»
        «IF deploymentAccessor.getPropertiesType(attribute.containingInterface) == PropertyAccessor.PropertiesType.freedesktop»
            CommonAPI::DBus::DBusStubFreedesktopPropertiesSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«IF attribute.isVariant»CommonAPI::Deployable<«typeName», CommonAPI::DBus::VariantDeployment<>>«ELSE»«typeName»«ENDIF»>>
                ::sendPropertiesChangedSignal(
                    *this,
                    "«attribute.elementName»",
                    «IF attribute.isVariant»deployedValue«ELSE»value«ENDIF»
            );
        «ELSE»
            CommonAPI::DBus::DBusStubSignalHelper<CommonAPI::DBus::DBusSerializableArguments<«IF attribute.isVariant»CommonAPI::Deployable<«typeName», CommonAPI::DBus::VariantDeployment<>>«ELSE»«typeName»«ENDIF»>>
                ::sendSignal(
                    *this,
                    "«attribute.dbusSignalName»",
                    "«attribute.dbusSignature(deploymentAccessor)»",
                    «IF attribute.isVariant»deployedValue«ELSE»value«ENDIF»
            );
        «ENDIF»
    '''

    def private generateStubAttributeTableInitializer(FInterface fInterface, PropertyAccessor deploymentAccessor) '''
        «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop && !fInterface.attributes.empty»
            {
            «FOR attribute : fInterface.attributes SEPARATOR ","»
                «fInterface.generateStubAttributeTableInitializerEntry(attribute)»
            «ENDFOR»
            «IF !fInterface.inheritedAttributes.empty»
                #ifdef WIN32
                «IF !fInterface.attributes.empty»,«ENDIF»
                «FOR attribute : fInterface.inheritedAttributes SEPARATOR ","»
                    «fInterface.generateStubAttributeTableInitializerEntry(attribute)»
                «ENDFOR»
                #endif
            «ENDIF»
            }
        «ENDIF»
    '''

    def private generateStubAttributeTableInitializerEntry(FInterface fInterface, FAttribute fAttribute) '''
        {
            "«fAttribute.elementName»",
            {
                &«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::«fAttribute.dbusGetStubDispatcherVariable»,
                «IF fAttribute.readonly»NULL«ELSE»&«fInterface.absoluteNamespace»::«fInterface.dbusStubAdapterClassNameInternal»::«fAttribute.dbusSetStubDispatcherVariable»«ENDIF»
            }
        }
    '''    
}
