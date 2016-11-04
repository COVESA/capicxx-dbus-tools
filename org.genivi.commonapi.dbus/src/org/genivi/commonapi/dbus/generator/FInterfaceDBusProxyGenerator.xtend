/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FVersion
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor

import static com.google.common.base.Preconditions.*
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus
import java.util.List
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.franca.deploymodel.core.FDeployedProvider
import java.util.LinkedList

class FInterfaceDBusProxyGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions

    var boolean generateSyncCalls = true

    def generateDBusProxy(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, List<FDProvider> providers, IResource modelid) {

        if(FPreferencesDBus::getInstance.getPreference(PreferenceConstantsDBus::P_GENERATE_CODE_DBUS, "true").equals("true")) {
            generateSyncCalls = FPreferencesDBus::getInstance.getPreference(PreferenceConstantsDBus::P_GENERATE_SYNC_CALLS_DBUS, "true").equals("true")
            fileSystemAccess.generateFile(fInterface.dbusProxyHeaderPath, PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS,
                fInterface.generateDBusProxyHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(fInterface.dbusProxySourcePath, PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS,
                fInterface.generateDBusProxySource(deploymentAccessor, providers, modelid))
        }
        else {
            // feature: suppress code generation
            fileSystemAccess.generateFile(fInterface.dbusProxyHeaderPath, PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, PreferenceConstantsDBus::NO_CODE)
            fileSystemAccess.generateFile(fInterface.dbusProxySourcePath, PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, PreferenceConstantsDBus::NO_CODE)
        }
    }

    def private generateDBusProxyHeader(FInterface fInterface, PropertyAccessor deploymentAccessor,
        IResource modelid) '''
        «generateCommonApiDBusLicenseHeader()»
        «FTypeGenerator::generateComments(fInterface, false)»
        #ifndef «fInterface.defineName»_DBUS_PROXY_HPP_
        #define «fInterface.defineName»_DBUS_PROXY_HPP_

        #include <«fInterface.proxyBaseHeaderPath»>
        «IF fInterface.base != null»
            #include <«fInterface.base.dbusProxyHeaderPath»>
        «ENDIF»
        #include "«fInterface.dbusDeploymentHeaderPath»"

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/DBus/DBusAddress.hpp>
        #include <CommonAPI/DBus/DBusFactory.hpp>
        #include <CommonAPI/DBus/DBusProxy.hpp>
        #include <CommonAPI/DBus/DBusAddressTranslator.hpp>
        «IF fInterface.hasAttributes»
            #include <CommonAPI/DBus/DBusAttribute.hpp>
            «IF deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop»
                #include <CommonAPI/DBus/DBusFreedesktopAttribute.hpp>
            «ENDIF»
        «ENDIF»
        «IF fInterface.hasBroadcasts»
            #include <CommonAPI/DBus/DBusEvent.hpp>
            «IF fInterface.hasSelectiveBroadcasts»
                #include <CommonAPI/Types.hpp>
                #include <CommonAPI/DBus/DBusSelectiveEvent.hpp>
            «ENDIF»
        «ENDIF»
        «IF !fInterface.managedInterfaces.empty»
            #include <CommonAPI/DBus/DBusProxyManager.hpp>
        «ENDIF»
        «IF !fInterface.attributes.filter[isVariant].empty»
            #include <CommonAPI/DBus/DBusDeployment.hpp>
        «ENDIF»

        #undef COMMONAPI_INTERNAL_COMPILATION

        #include <string>

        #  if _MSC_VER >= 1300
        /*
         * Diamond inheritance is used for the CommonAPI::Proxy base class.
         * The Microsoft compiler put warning (C4250) using a desired c++ feature: "Delegating to a sister class"
         * A powerful technique that arises from using virtual inheritance is to delegate a method from a class in another class
         * by using a common abstract base class. This is also called cross delegation.
         */
        #    pragma warning( disable : 4250 )
        #  endif

        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        class «fInterface.dbusProxyClassName»
            : virtual public «fInterface.proxyBaseClassName»,
              virtual public «IF fInterface.base != null»«fInterface.base.getTypeCollectionName(fInterface)»DBusProxy«ELSE»CommonAPI::DBus::DBusProxy«ENDIF» {
        public:
            «fInterface.dbusProxyClassName»(
                const CommonAPI::DBus::DBusAddress &_address,
                const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection);

            virtual ~«fInterface.dbusProxyClassName»() { }

            «FOR attribute : fInterface.attributes»
            virtual «attribute.generateGetMethodDefinition»;
            «ENDFOR»

            «FOR broadcast : fInterface.broadcasts»
                virtual «broadcast.generateGetMethodDefinition»;
            «ENDFOR»

            «FOR method : fInterface.methods»
            «FTypeGenerator::generateComments(method, false)»
            «IF generateSyncCalls || method.isFireAndForget»
            virtual «method.generateDefinition(false)»;
            «ENDIF»
            «IF !method.isFireAndForget»
                virtual «method.generateAsyncDefinition(false)»;
            «ENDIF»
            «ENDFOR»

            «FOR managed : fInterface.managedInterfaces»
            virtual CommonAPI::ProxyManager& «managed.proxyManagerGetterName»();
            «ENDFOR»

            virtual void getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const;

        private:

            «FOR attribute : fInterface.attributes»
                «IF attribute.supportsTypeValidation»
                class DBus«attribute.dbusClassVariableName»Attribute : public «attribute.dbusClassName(deploymentAccessor, fInterface)» {
                public:
                template <typename... _A>
                    DBus«attribute.dbusClassVariableName»Attribute(DBusProxy &_proxy,
                        _A ... arguments)
                        : «attribute.dbusClassName(deploymentAccessor, fInterface)»(
                            _proxy, arguments...) {}
                «IF !attribute.isReadonly »
                void setValue(const «attribute.getTypeName(fInterface, true)»& requestValue,
                    CommonAPI::CallStatus& callStatus,
                    «attribute.getTypeName(fInterface, true)»& responseValue,
                    const CommonAPI::CallInfo *_info = nullptr) {
                        // validate input parameters
                        if (!requestValue.validate()) {
                            callStatus = CommonAPI::CallStatus::INVALID_VALUE;
                            return;
                        }
                        // call parent function if ok
                        «attribute.dbusClassName(deploymentAccessor, fInterface)»::setValue(requestValue, callStatus, responseValue, _info);
                    }
                std::future<CommonAPI::CallStatus> setValueAsync(const «attribute.getTypeName(fInterface, true)»& requestValue,
                    std::function<void(const CommonAPI::CallStatus &, «attribute.getTypeName(fInterface, true)»)> _callback,
                    const CommonAPI::CallInfo *_info) {
                        // validate input parameters
                        if (!requestValue.validate()) {
                            «attribute.getTypeName(fInterface, true)» _returnvalue;
                            _callback(CommonAPI::CallStatus::INVALID_VALUE, _returnvalue);
                            std::promise<CommonAPI::CallStatus> promise;
                            promise.set_value(CommonAPI::CallStatus::INVALID_VALUE);
                            return promise.get_future();
                        }
                        // call parent function if ok
                        return «attribute.dbusClassName(deploymentAccessor, fInterface)»::setValueAsync(requestValue, _callback, _info);
                    }
                «ENDIF»
                };
                DBus«attribute.dbusClassVariableName»Attribute «attribute.dbusClassVariableName»;
                «ELSE»
                «attribute.dbusClassName(deploymentAccessor, fInterface)» «attribute.dbusClassVariableName»;
                «ENDIF»
            «ENDFOR»

            «FOR broadcast : fInterface.broadcasts»
                «IF !broadcast.isErrorType(deploymentAccessor)»
                    «broadcast.dbusClassName(deploymentAccessor, fInterface)» «broadcast.dbusClassVariableName»;
                «ELSE»
                
                typedef «broadcast.dbusErrorEventClassName(deploymentAccessor, fInterface)» «broadcast.dbusErrorEventTypedefName(deploymentAccessor)»;
                «broadcast.dbusErrorEventTypedefName(deploymentAccessor)» «broadcast.dbusClassVariableName»;
                «ENDIF»
            «ENDFOR»

            «FOR managed : fInterface.managedInterfaces»
            CommonAPI::DBus::DBusProxyManager «managed.proxyManagerMemberName»;
            «ENDFOR»
        };

        «fInterface.model.generateNamespaceEndDeclaration»
        «fInterface.generateVersionNamespaceEnd»

        #endif // «fInterface.defineName»_DBUS_PROXY_HPP_

    '''

    def private generateDBusProxySource(FInterface fInterface, PropertyAccessor deploymentAccessor, List<FDProvider> providers,
        IResource modelid) '''
        «generateCommonApiDBusLicenseHeader()»
        «FTypeGenerator::generateComments(fInterface, false)»
        #include <«fInterface.dbusProxyHeaderPath»>

        «fInterface.generateVersionNamespaceBegin»
        «fInterface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::DBus::DBusProxy> create«fInterface.dbusProxyClassName»(
            const CommonAPI::DBus::DBusAddress &_address,
            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection) {
            return std::make_shared< «fInterface.dbusProxyClassName»>(_address, _connection);
        }

        void initialize«fInterface.dbusProxyClassName»() {
             «FOR p : providers»
                 «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
                 «FOR i : p.instances.filter[target == fInterface]»
                     CommonAPI::DBus::DBusAddressTranslator::get()->insert(
                         "local:«fInterface.fullyQualifiedNameWithVersion»:«providerAccessor.getInstanceId(i)»",
                         "«providerAccessor.getDBusServiceName(i)»",
                         "«providerAccessor.getDBusObjectPath(i)»",
                         "«providerAccessor.getDBusInterfaceName(i)»");
                 «ENDFOR»
             «ENDFOR»
             CommonAPI::DBus::Factory::get()->registerProxyCreateMethod(
                «fInterface.elementName»::getInterface(),
                &create«fInterface.dbusProxyClassName»);
        }

        INITIALIZER(register«fInterface.dbusProxyClassName») {
            CommonAPI::DBus::Factory::get()->registerInterface(initialize«fInterface.dbusProxyClassName»);
        }

        «fInterface.dbusProxyClassName»::«fInterface.dbusProxyClassName»(
            const CommonAPI::DBus::DBusAddress &_address,
            const std::shared_ptr<CommonAPI::DBus::DBusProxyConnection> &_connection)
            :   CommonAPI::DBus::DBusProxy(_address, _connection)«IF fInterface.base != null»,«ENDIF»
                «fInterface.generateDBusBaseInstantiations»
                «FOR attribute : fInterface.attributes BEFORE ',' SEPARATOR ','»
                    «attribute.generateDBusVariableInit(deploymentAccessor, fInterface)»
                «ENDFOR»
                «FOR broadcast : fInterface.broadcasts BEFORE ',' SEPARATOR ','»
                    «IF !broadcast.isErrorType(deploymentAccessor)»
                        «broadcast.dbusClassVariableName»(*this, "«broadcast.elementName»", "«broadcast.dbusSignature(deploymentAccessor)»", «broadcast.
                getDeployments(fInterface, deploymentAccessor)»)
                    «ELSE»
                        «broadcast.dbusClassVariableName»(«broadcast.dbusErrorEventTypedefName(deploymentAccessor)»("«deploymentAccessor.getErrorName(broadcast)»"«IF !broadcast.errorArgs(deploymentAccessor).empty», std::make_tuple(«broadcast.errorArgs(deploymentAccessor).map[getDeploymentRef(it.array, broadcast, fInterface, deploymentAccessor)].join(', ')»)«ENDIF»))
                    «ENDIF»
                «ENDFOR»
                «FOR managed : fInterface.managedInterfaces BEFORE ',' SEPARATOR ','»
                    «managed.proxyManagerMemberName»(*this, "«managed.fullyQualifiedName».«managed.interfaceVersion»","«managed.fullyQualifiedNameWithVersion»")
                «ENDFOR»
        {
            «FOR p : providers»
                «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
                «FOR i : p.instances.filter[target == fInterface]»
                    «IF providerAccessor.getDBusPredefined(i)»
                        CommonAPI::DBus::DBusServiceRegistry::get(_connection)->setDBusServicePredefined(_address.getService());
                    «ENDIF»
                «ENDFOR»
            «ENDFOR»
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
                «var errorClasses = new LinkedList()»
                «FOR broadcast : fInterface.broadcasts»
                    «IF broadcast.isErrorType(method, deploymentAccessor)»
                        «{errorClasses.add('&' + broadcast.dbusClassVariableName);""}»
                    «ENDIF»
                «ENDFOR»
                «val timeout = method.getTimeout(deploymentAccessor)»
                «val inParams = method.generateInParams(deploymentAccessor)»
                «IF generateSyncCalls || method.isFireAndForget»
                «val outParams = method.generateOutParams(deploymentAccessor, false)»
                «FTypeGenerator::generateComments(method, false)»
                «method.generateDefinitionWithin(fInterface.dbusProxyClassName, false)» {
                    «method.generateProxyHelperDeployments(fInterface, false, deploymentAccessor)»
                    «IF method.isFireAndForget»
                        «method.generateDBusProxyHelperClass(fInterface, deploymentAccessor)»::callMethod(
                    «ELSE»
                        «IF timeout != 0»
                            static CommonAPI::CallInfo info(«timeout»);
                        «ENDIF»
                        «method.generateDBusProxyHelperClass(fInterface, deploymentAccessor)»::callMethodWithReply(
                    «ENDIF»
                    *this,
                    "«method.elementName»",
                    "«method.dbusInSignature(deploymentAccessor)»",
            «IF !method.isFireAndForget»(_info ? _info : «IF timeout != 0»&info«ELSE»&CommonAPI::DBus::defaultCallInfo«ENDIF»),«ENDIF»
            «IF inParams != ""»«inParams»,«ENDIF»
            _internalCallStatus«IF method.hasError»,
            deploy_error«ENDIF»«IF outParams != ""»,
            «outParams»«ENDIF»«IF !method.isFireAndForget && !errorClasses.empty»,
            «'std::make_tuple(' + errorClasses.map[it].join(', ') + ')'»«ENDIF»);
            «method.generateOutParamsValue(deploymentAccessor)»
            }
            «ENDIF»
            «IF !method.isFireAndForget»
                «method.generateAsyncDefinitionWithin(fInterface.dbusProxyClassName, false)» {
                    «method.generateProxyHelperDeployments(fInterface, true, deploymentAccessor)»
                    «IF timeout != 0»
                        static CommonAPI::CallInfo info(«timeout»);
                    «ENDIF»
                    return «method.generateDBusProxyHelperClass(fInterface, deploymentAccessor)»::callMethodAsync(
                    *this,
                    "«method.elementName»",
                    "«method.dbusInSignature(deploymentAccessor)»",
                    (_info ? _info : «IF timeout != 0»&info«ELSE»&CommonAPI::DBus::defaultCallInfo«ENDIF»),
                    «IF inParams != ""»«inParams»,«ENDIF»
                    «method.generateCallback(fInterface, deploymentAccessor)»«IF !errorClasses.empty»,
                    «'std::make_tuple(' + errorClasses.map[it].join(', ') + ')'»«ENDIF»);
                }
            «ENDIF»
              «ENDFOR»

        «FOR managed : fInterface.managedInterfaces»
            CommonAPI::ProxyManager& «fInterface.dbusProxyClassName»::«managed.proxyManagerGetterName»() {
            return «managed.proxyManagerMemberName»;
                  }
        «ENDFOR»

        void «fInterface.dbusProxyClassName»::getOwnVersion(uint16_t& ownVersionMajor, uint16_t& ownVersionMinor) const {
                  «val FVersion itsVersion = fInterface.version»
                  «IF itsVersion != null»
                      ownVersionMajor = «fInterface.version.major»;
                      ownVersionMinor = «fInterface.version.minor»;
                  «ELSE»
                      ownVersionMajor = 0;
                      ownVersionMinor = 0;
                  «ENDIF»
              }

              «fInterface.model.generateNamespaceEndDeclaration»
              «fInterface.generateVersionNamespaceEnd»
     '''

    def private dbusClassVariableName(FModelElement fModelElement) {
        checkArgument(!fModelElement.elementName.nullOrEmpty, 'FModelElement has no name: ' + fModelElement)
        fModelElement.elementName.toFirstLower + '_'
    }

    def private dbusClassVariableName(FBroadcast fBroadcast) {
        checkArgument(!fBroadcast.elementName.nullOrEmpty, 'FModelElement has no name: ' + fBroadcast)
        var classVariableName = fBroadcast.elementName.toFirstLower

        if (fBroadcast.selective)
            classVariableName = classVariableName + 'Selective'

        classVariableName = classVariableName + '_'

        return classVariableName
    }
    
    def private dbusErrorEventTypedefName(FBroadcast fBroadcast, PropertyAccessor deploymentAccessor) {
        checkArgument(fBroadcast.isErrorType(deploymentAccessor), 'FBroadcast is no error type: ' + fBroadcast)
        
        return 'DBus' + fBroadcast.className
    }

    def private dbusProxyHeaderFile(FInterface fInterface) {
        fInterface.elementName + "DBusProxy.hpp"
    }

    def private dbusProxyHeaderPath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.dbusProxyHeaderFile
    }

    def private dbusProxySourceFile(FInterface fInterface) {
        fInterface.elementName + "DBusProxy.cpp"
    }

    def private dbusProxySourcePath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.dbusProxySourceFile
    }

    def private dbusProxyClassName(FInterface fInterface) {
        fInterface.elementName + 'DBusProxy'
    }

    def private generateDBusProxyHelperClass(FMethod fMethod,
        FInterface _interface, PropertyAccessor _accessor) '''
        «var errorEventTypedefs = new LinkedList()»
        «FOR broadcast : _interface.broadcasts»
            «IF broadcast.isErrorType(fMethod, _accessor)»
                «{errorEventTypedefs.add(broadcast.dbusErrorEventTypedefName(_accessor));""}»
            «ENDIF»
        «ENDFOR»
    CommonAPI::DBus::DBusProxyHelper<
        CommonAPI::DBus::DBusSerializableArguments<
        «FOR a : fMethod.inArgs»
            CommonAPI::Deployable< «a.getTypeName(fMethod, true)», «a.getDeploymentType(_interface, true)» >«IF a != fMethod.inArgs.last»,«ENDIF»
        «ENDFOR»
        >,
        CommonAPI::DBus::DBusSerializableArguments<
        «IF fMethod.hasError»
            CommonAPI::Deployable< «fMethod.errorType», «fMethod.getErrorDeploymentType(false)»>«IF !fMethod.outArgs.empty»,«ENDIF»
        «ENDIF»
        «FOR a : fMethod.outArgs»
            CommonAPI::Deployable< «a.getTypeName(fMethod, true)»,«a.getDeploymentType(_interface, true)»>«IF a != fMethod.outArgs.last»,«ENDIF»
        «ENDFOR»
        >«IF !errorEventTypedefs.empty»,«ENDIF»
        «errorEventTypedefs.map[it].join(',\n')»
        >'''

    def private dbusClassName(FAttribute fAttribute, PropertyAccessor deploymentAccessor, FInterface fInterface) {
        var type = 'CommonAPI::DBus::DBus'
        if (deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop) {
            type = type + 'Freedesktop'
        }

        if (fAttribute.isReadonly)
            type = type + 'Readonly'

        type = type + "Attribute<" + fAttribute.className
        val deployment = fAttribute.getDeploymentType(fInterface, true)
        if(!deployment.equals("CommonAPI::EmptyDeployment")) type += ", " + deployment
        type += ">"

        if (fAttribute.isObservable)
            if (deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop) {
                type = 'CommonAPI::DBus::DBusFreedesktopObservableAttribute<' + type + '>'
            } else {
                type = 'CommonAPI::DBus::DBusObservableAttribute<' + type + '>'
            }

        return type
    }

    def private generateDBusVariableInit(FAttribute fAttribute, PropertyAccessor deploymentAccessor,
        FInterface fInterface) {
        var ret = fAttribute.dbusClassVariableName + '(*this'

        if (deploymentAccessor.getPropertiesType(fInterface) == PropertyAccessor.PropertiesType.freedesktop) {
            ret = ret + ', getDBusAddress().getInterface(), "' + fAttribute.elementName + '"'
        } else {

            if (fAttribute.isObservable)
                ret = ret + ', "' + fAttribute.dbusSignalName + '"'

            if (!fAttribute.isReadonly)
                ret = ret + ', "' + fAttribute.dbusSetMethodName + '", "' + fAttribute.dbusSignature(deploymentAccessor) +
                    '", "' + fAttribute.dbusGetMethodName + '"'
            else
                ret = ret + ', "' + fAttribute.dbusSignature(deploymentAccessor) + '", "' + fAttribute.dbusGetMethodName +
                    '"'
        }
        val String deployment = fAttribute.getDeploymentRef(fAttribute.array, null, fInterface, deploymentAccessor)
        if (deployment != "")
            ret += ", " + deployment

        ret += ")"
        return ret
    }

    def private dbusClassName(FBroadcast fBroadcast, PropertyAccessor deploymentAccessor, FInterface fInterface) {
        var ret = 'CommonAPI::DBus::'

        if (fBroadcast.isSelective)
            ret = ret + 'DBusSelectiveEvent'
        else
            ret = ret + 'DBusEvent'

        ret = ret + '<' + fBroadcast.className

        for (a : fBroadcast.outArgs) {
            ret += ", "
            ret += a.getDeployable(fInterface, deploymentAccessor)
        }

        ret = ret + '>'

        return ret
    }
    
    def private dbusErrorEventClassName(FBroadcast fBroadcast, PropertyAccessor deploymentAccessor, FInterface fInterface) {
        checkArgument(fBroadcast.isErrorType(deploymentAccessor), 'FBroadcast is no error type: ' + fBroadcast)

        var ret = 'CommonAPI::DBus::DBusErrorEvent<\n'
        if (fBroadcast.outArgs.size > 1) {
            ret = ret + '    std::tuple< ' + fBroadcast.errorArgs(deploymentAccessor).map[it.getTypeName(fInterface, true)].join(', ') + '>,\n'
            ret = ret + '    std::tuple< ' + fBroadcast.errorArgs(deploymentAccessor).map[it.getDeploymentType(fInterface, true)].join(', ') + '>\n'
        }
        return ret + '>'
    }

    def private generateProxyHelperDeployments(FMethod _method,
        FInterface _interface, boolean _isAsync,
        PropertyAccessor _accessor) '''
        «IF _method.hasError»
            CommonAPI::Deployable< «_method.errorType», «_method.getErrorDeploymentType(false)»> deploy_error(«_method.
            getErrorDeploymentRef(_interface, _accessor)»);
        «ENDIF»
        «FOR a : _method.inArgs»
            CommonAPI::Deployable< «a.getTypeName(_method, true)», «a.getDeploymentType(_interface, true)»> deploy_«a.name»(_«a.
            name», «a.getDeploymentRef(a.array, _method, _interface, _accessor)»);
        «ENDFOR»
        «FOR a : _method.outArgs»
            CommonAPI::Deployable< «a.getTypeName(_method, true)», «a.getDeploymentType(_interface, true)»> deploy_«a.name»(«a.
            getDeploymentRef(a.array, _method, _interface, _accessor)»);
        «ENDFOR»
    '''

    def private generateInParams(FMethod _method, PropertyAccessor _accessor) {
        var String inParams = ""
        for (a : _method.inArgs) {
            if(inParams != "") inParams += ", "
            inParams += "deploy_" + a.name
        }
        return inParams
    }

    def private generateOutParams(FMethod _method, PropertyAccessor _accessor,
        boolean _instantiate) {
        var String outParams = ""
        for (a : _method.outArgs) {
            if(outParams != "") outParams += ", "
            outParams += "deploy_" + a.name
        }
        return outParams
    }

    def private generateOutParamsValue(FMethod _method,
        PropertyAccessor _accessor) {
        var String outParamsValue = ""
        if (_method.hasError) {
            outParamsValue += "_error = deploy_error.getValue();\n"
        }
        for (a : _method.outArgs) {
            outParamsValue += "_" + a.name + " = deploy_" + a.name + ".getValue();\n"
        }
        return outParamsValue
    }

    def private generateCallback(FMethod _method, FInterface _interface,
        PropertyAccessor _accessor) {

        var String error = ""
        if (_method.hasError) {
            error = "deploy_error"
        }

        var String callback = "[_callback] (" + generateCallbackParameter(_method, _interface, _accessor) + ") {\n"
        callback += "    if (_callback)\n"
        callback += "        _callback(_internalCallStatus"
        if(_method.hasError) callback += ", _deploy_error.getValue()"
        for (a : _method.outArgs) {
            callback += ", _" + a.name
            callback += ".getValue()"
        }
        callback += ");\n"
        callback += "},\n"

        var String out = generateOutParams(_method, _accessor, true)
        if(error != "" && out != "") error += ", "
        callback += "std::make_tuple(" + error + out + ")"
        return callback
    }

    def private generateCallbackParameter(FMethod _method,
        FInterface _interface, PropertyAccessor _accessor) {
        var String declaration = "CommonAPI::CallStatus _internalCallStatus"
        if (_method.hasError)
            declaration +=
                ", CommonAPI::Deployable< " + _method.errorType + ", " + _method.getErrorDeploymentType(false) +
                    " > _deploy_error"
        for (a : _method.outArgs) {
            declaration += ", "
            declaration += "CommonAPI::Deployable< " + a.getTypeName(_method, true) + ", " +
                a.getDeploymentType(_interface, true) + " > _" + a.name
        }
        return declaration
    }

}
