/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.dbus.generator

import com.google.inject.Inject
import java.util.HashSet
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArgument
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import org.franca.core.franca.FAttribute
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus

class FInterfaceDBusDeploymentGenerator extends FTypeCollectionDBusDeploymentGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions
    @Inject private extension FrancaDBusDeploymentAccessorHelper
    

    def generateDeployment(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, IResource modelid) {

        if(FPreferencesDBus::getInstance.getPreference(PreferenceConstantsDBus::P_GENERATE_CODE_DBUS, "true").equals("true")) {
            fileSystemAccess.generateFile(fInterface.dbusDeploymentHeaderPath,  IFileSystemAccess.DEFAULT_OUTPUT,
                fInterface.generateDeploymentHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(fInterface.dbusDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT,
                fInterface.generateDeploymentSource(deploymentAccessor, modelid))
        } 
        else {
            // feature: suppress code generation
            fileSystemAccess.generateFile(fInterface.dbusDeploymentHeaderPath,  IFileSystemAccess.DEFAULT_OUTPUT, PreferenceConstantsDBus::NO_CODE)
            fileSystemAccess.generateFile(fInterface.dbusDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT, PreferenceConstantsDBus::NO_CODE)
        }
    }

    def private generateDeploymentHeader(FInterface _interface, 
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiDBusLicenseHeader()»
        
        #ifndef COMMONAPI_DBUS_«_interface.name.toUpperCase»_DEPLOYMENT_HPP_
        #define COMMONAPI_DBUS_«_interface.name.toUpperCase»_DEPLOYMENT_HPP_
        
        «val DeploymentHeaders = _interface.getDeploymentInputIncludes(_accessor)»
        «DeploymentHeaders.map["#include <" + it + ">"].join("\n")»        
        «val generatedHeaders = new HashSet<String>»
        «_interface.attributes.forEach[
        	if(type.derived != null) {
        		type.derived.addRequiredHeaders(generatedHeaders)
        	} ]»
        
        «FOR requiredHeaderFile : generatedHeaders.sort»
            #include <«requiredHeaderFile»>
        «ENDFOR»

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif
        #include <CommonAPI/DBus/DBusDeployment.hpp>
        #undef COMMONAPI_INTERNAL_COMPILATION

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»
        «_interface.generateDeploymentNamespaceBegin»

        // Interface-specific deployment types
        «FOR t: _interface.types»
            «IF !(t instanceof FEnumerationType)»
                «val deploymentType = t.generateDeploymentType(0)»
                typedef «deploymentType» «t.name»Deployment_t;

            «ENDIF»
        «ENDFOR»
        
        // Type-specific deployments
        «FOR t: _interface.types»
            «t.generateDeploymentDeclaration(_interface, _accessor)»
        «ENDFOR»

        // Attribute-specific deployments
        «FOR a: _interface.attributes»
            «a.generateDeploymentDeclaration(_interface, _accessor)»
        «ENDFOR»
        
        // Argument-specific deployments
        «FOR m : _interface.methods»
            «FOR a : m.inArgs»
                «a.generateDeploymentDeclaration(m, _interface, _accessor)»
            «ENDFOR»
            «FOR a : m.outArgs»
                «a.generateDeploymentDeclaration(m, _interface, _accessor)»
            «ENDFOR»
        «ENDFOR»
        
        // Broadcast-specific deployments
        «FOR broadcast : _interface.broadcasts»
            «FOR a : broadcast.outArgs»
                «a.generateDeploymentDeclaration(broadcast, _interface, _accessor)»
            «ENDFOR»
        «ENDFOR»
        
        
        «_interface.generateDeploymentNamespaceEnd»
        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»
        
        #endif // COMMONAPI_DBUS_«_interface.name.toUpperCase»_DEPLOYMENT_HPP_
    '''

    def private generateDeploymentSource(FInterface _interface, 
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiDBusLicenseHeader()»
        #include "«_interface.dbusDeploymentHeaderFile»"

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»
        «_interface.generateDeploymentNamespaceBegin»
        
        // Type-specific deployments
        «FOR t: _interface.types»
            «t.generateDeploymentDefinition(_interface,_accessor)»
        «ENDFOR»
        
        // Attribute-specific deployments
        «FOR a: _interface.attributes»
            «a.generateDeploymentDefinition(_interface,_accessor)»
        «ENDFOR»
        
        // Argument-specific deployments
        «FOR m : _interface.methods»
            «FOR a : m.inArgs»
                «a.generateDeploymentDefinition(m, _interface, _accessor)»
            «ENDFOR»
            «FOR a : m.outArgs»
                «a.generateDeploymentDefinition(m, _interface, _accessor)»
            «ENDFOR»
        «ENDFOR»

        // Broadcast-specific deployments
        «FOR broadcast : _interface.broadcasts»
            «FOR a : broadcast.outArgs»
                «a.generateDeploymentDefinition(broadcast, _interface, _accessor)»
            «ENDFOR»
        «ENDFOR»
         
        «_interface.generateDeploymentNamespaceEnd»
        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»
    '''
        
    def protected dispatch String generateDeploymentDeclaration(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute)) {
            return "extern " + _attribute.getDeploymentType(null, true) + " " + _attribute.name + "Deployment;"
        }
        return ""
    }
    
    def protected String generateDeploymentDeclaration(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            return "extern " + _argument.getDeploymentType(null, true) + " " + _method.name + "_" + _argument.name + "Deployment;"
        }
    }
    
    def protected String generateDeploymentDeclaration(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            return "extern " + _argument.getDeploymentType(null, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment;"
        }
    }

    def protected dispatch String generateDeploymentDefinition(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute)) {
            var String definition = _attribute.getDeploymentType(null, true) + " " + _attribute.name + "Deployment("
            definition += _attribute.getDeploymentParameter(_attribute, _accessor) 
            definition += ");"
            return definition
        }
        return ""
    }
    
    def protected String generateDeploymentDefinition(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            var String definition = _argument.getDeploymentType(null, true) + " " + _method.name + "_" + _argument.name + "Deployment("
            definition += _argument.getDeploymentParameter(_argument, _accessor) 
            definition += ");"
            return definition
        }
    } 

    def protected String generateDeploymentDefinition(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            var String definition = _argument.getDeploymentType(null, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment("
            definition += _argument.getDeploymentParameter(_argument, _accessor) 
            definition += ");"
            return definition
        }
    }     
}
