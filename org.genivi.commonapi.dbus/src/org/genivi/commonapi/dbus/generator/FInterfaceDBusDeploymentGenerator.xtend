/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.dbus.generator

import com.google.inject.Inject
import java.util.HashSet
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArgument
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FField
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMapType
import org.franca.core.franca.FMethod
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import java.util.List

class FInterfaceDBusDeploymentGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions
    @Inject private extension FrancaDBusDeploymentAccessorHelper
    

    def generateDeployment(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, IResource modelid) {
        fileSystemAccess.generateFile(fInterface.dbusDeploymentHeaderPath,  IFileSystemAccess.DEFAULT_OUTPUT,
            fInterface.generateDeploymentHeader(deploymentAccessor, modelid))
        fileSystemAccess.generateFile(fInterface.dbusDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT,
            fInterface.generateDeploymentSource(deploymentAccessor, modelid))
    }

    def private generateDeploymentHeader(FInterface _interface, 
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiLicenseHeader(_interface, _modelid)»
        
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
        «generateCommonApiLicenseHeader(_interface, _modelid)»
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
        
    // Generate deployment types
    def private dispatch String generateDeploymentType(FArrayType _array, int _indent) {
        return generateArrayDeploymentType(_array.elementType, _indent)
    }
    
    def private String generateArrayDeploymentType(FTypeRef _elementType, int _indent) {    
        var String deployment = generateIndent(_indent) + "CommonAPI::DBus::ArrayDeployment<\n"
        if (_elementType.derived != null) {
            deployment += generateDeploymentType(_elementType.derived, _indent + 1)
        } else if (_elementType.predefined != null) {
            deployment += generateDeploymentType(_elementType.predefined, _indent + 1)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }
    
    def private dispatch String generateDeploymentType(FEnumerationType _enum, int _indent) {
		return generateIndent(_indent) + "CommonAPI::EmptyDeployment"    	
    }
    
    def private dispatch String generateDeploymentType(FMapType _map, int _indent) {
        var String deployment = generateIndent(_indent) + "CommonAPI::MapDeployment<\n"
        if (_map.keyType.derived != null) {
            deployment += generateDeploymentType(_map.keyType.derived, _indent + 1)
        } else if (_map.keyType.predefined != null) {
            deployment += generateDeploymentType(_map.keyType.predefined, _indent + 1)
        }
        deployment += ",\n"
        if (_map.valueType.derived != null) {
            deployment += generateDeploymentType(_map.valueType.derived, _indent + 1)
        } else if (_map.valueType.predefined != null) {
            deployment += generateDeploymentType(_map.valueType.predefined, _indent + 1)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }
    
    def private dispatch String generateDeploymentType(FStructType _struct, int _indent) {
    	if (_struct.isPolymorphic)
    		return generateIndent(_indent) + "CommonAPI::EmptyDeployment"
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _struct.allElements
        if (elements.length == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::DBus::StructDeployment<\n"
            for (e : elements) {
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1)
                } else if (e.type.derived != null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1)
                } else if (e.type.predefined != null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1)
                }  else {
                    deployment += "Warning struct with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }
     
    def private dispatch String generateDeploymentType(FUnionType _union, int _indent) {
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _union.allElements
        if (elements.length == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::DBus::VariantDeployment<\n"    
            for (e : elements) {
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1)
                } else if (e.type.derived != null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1)
                } else if (e.type.predefined != null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1)
                } else {
                    deployment += "Warning union with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }
    
    def private dispatch String generateDeploymentType(FTypeDef _typeDef, int _indent) {
        val FTypeRef actualType = _typeDef.actualType
        if (actualType.derived != null)
            return actualType.derived.generateDeploymentType(_indent)
            
        if (actualType.predefined != null)
            return actualType.predefined.generateDeploymentType(_indent)
            
        return "CommonAPI::EmptyDeployment"
    }
    
    def private dispatch String generateDeploymentType(FBasicTypeId _type, int _indent) {
        var String deployment = generateIndent(_indent)
        if (_type == FBasicTypeId.STRING)
            deployment = deployment + "CommonAPI::DBus::StringDeployment"
        else
            deployment = deployment + "CommonAPI::EmptyDeployment"

        return deployment
    }
    
    def private dispatch String generateDeploymentType(FType _type, int _indent) {
        return generateIndent(_indent) + "CommonAPI::EmptyDeployment"   
    }
    
    /////////////////////////////////////
    // Generate deployment declarations //
    /////////////////////////////////////
    def private dispatch String generateDeploymentDeclaration(FArrayType _array, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            return _array.elementType.generateDeploymentDeclaration(_interface, _accessor) + 
                   "extern " + _array.getDeploymentType(null, true) + " " + _array.name + "Deployment;"
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FEnumerationType _enum, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_enum)) {
            return "extern CommonAPI::EmptyDeployment " + _enum.name + "Deployment;"
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FMapType _map, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            return _map.keyType.generateDeploymentDeclaration(_interface, _accessor) +
                   _map.valueType.generateDeploymentDeclaration(_interface, _accessor) +
                   "extern " + _map.getDeploymentType(null, true) + " " + _map.name + "Deployment;"
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FStructType _struct, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_struct)) {
            var String declaration = ""
            for (structElement : _struct.elements) {
                declaration += structElement.generateDeploymentDeclaration(_interface, _accessor)
            }
            declaration += "extern " + _struct.getDeploymentType(null, true) + " " + _struct.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FUnionType _union, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_union)) {
            var String declaration = ""
            for (structElement : _union.elements) {
                declaration += structElement.generateDeploymentDeclaration(_interface, _accessor)
            }
            declaration += "extern " + _union.getDeploymentType(null, true) + " " + _union.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FField _field, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_field)) {
            return "extern " + _field.getDeploymentType(null, true) + " " + _field.getRelativeName() + "Deployment;\n" 
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FTypeDef _typeDef, FInterface _interface, PropertyAccessor _accessor) {
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FTypeRef _typeRef, FInterface _interface, PropertyAccessor _accessor) {
        return ""
    }
    
    def private dispatch String generateDeploymentDeclaration(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute)) {
            return "extern " + _attribute.getDeploymentType(null, true) + " " + _attribute.name + "Deployment;"
        }
        return ""
    }
    
    def private String generateDeploymentDeclaration(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            return "extern " + _argument.getDeploymentType(null, true) + " " + _method.name + "_" + _argument.name + "Deployment;"
        }
    }
    
    def private String generateDeploymentDeclaration(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            return "extern " + _argument.getDeploymentType(null, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment;"
        }
    }
    
    /////////////////////////////////////
    // Generate deployment definitions //
    /////////////////////////////////////
    def private dispatch String generateDeploymentDefinition(FArrayType _array, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            var String definition = _array.elementType.generateDeploymentDefinition(_interface, _accessor)
            definition += _array.getDeploymentType(null, true) + " " + _array.name + "Deployment("
            definition += _array.getDeploymentParameter(_array, _accessor)
            definition += ");"
            return definition
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FEnumerationType _enum, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_enum)) {
            var String definition = _enum.getDeploymentType(null, true) + " " + _enum.name + "Deployment("
            definition += _enum.getDeploymentParameter(_enum, _accessor)
            definition += ");"
            return definition
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FMapType _map, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            var String definition = _map.keyType.generateDeploymentDefinition(_interface, _accessor) +
                                    _map.valueType.generateDeploymentDefinition(_interface, _accessor)
            definition += _map.getDeploymentType(null, true) + " " + _map.name + "Deployment("
            definition += _map.getDeploymentParameter(_map, _accessor)
            definition += ");"
            return definition
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FStructType _struct, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_struct)) {
            var String definition = _struct.elements.map[generateDeploymentDefinition(_interface, _accessor)].filter[!equals("")].join(";\n")
            definition += _struct.getDeploymentType(null, true) + " " + _struct.name + "Deployment("
            definition += _struct.getDeploymentParameter(_struct, _accessor)
            definition += ");\n"        
            return definition
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FUnionType _union, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_union)) {
            var String definition = _union.elements.map[generateDeploymentDefinition(_interface, _accessor)].filter[!equals("")].join(";\n") 
            definition += _union.getDeploymentType(null, true) + " " + _union.name + "Deployment("
            definition += _union.getDeploymentParameter(_union, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FField _field, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_field)) {
            var String definition = _field.getDeploymentType(null, true) + " " + _field.getRelativeName() + "Deployment("
            definition += getDeploymentParameter(_field.type, _field, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }

    def private dispatch String generateDeploymentDefinition(FTypeDef _typeDef, FInterface _interface, PropertyAccessor _accessor) {
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FTypeRef _typeRef, FInterface _interface, PropertyAccessor _accessor) {
        return ""
    }
    
    def private dispatch String generateDeploymentDefinition(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute)) {
            var String definition = _attribute.getDeploymentType(null, true) + " " + _attribute.name + "Deployment("
            definition += _attribute.getDeploymentParameter(_attribute, _accessor) 
            definition += ");"
            return definition
        }
        return ""
    }
    
    def private String generateDeploymentDefinition(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            var String definition = _argument.getDeploymentType(null, true) + " " + _method.name + "_" + _argument.name + "Deployment("
            definition += _argument.getDeploymentParameter(_argument, _accessor) 
            definition += ");"
            return definition
        }
    } 

    def private String generateDeploymentDefinition(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument)) {
            var String definition = _argument.getDeploymentType(null, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment("
            definition += _argument.getDeploymentParameter(_argument, _accessor) 
            definition += ");"
            return definition
        }
    }     
    
    def private dispatch String getDeploymentParameter(FArrayType _array, EObject _source, PropertyAccessor _accessor) {
        var String parameter = getArrayElementTypeDeploymentParameter(_array.elementType, _array, _accessor) 
        val arrayDeploymentParameter = getArrayDeploymentParameter(_array, _source, _accessor) 
        if ("" != arrayDeploymentParameter) {
        	parameter += ", " +  arrayDeploymentParameter
       	}
        return parameter
    }
    
    def private dispatch String getDeploymentParameter(FEnumerationType _enum, EObject _source, PropertyAccessor _accessor) {
        // nothing specific for DBus.
        return ""
    }
    
    def private dispatch String getDeploymentParameter(FMapType _map, EObject _source, PropertyAccessor _accessor) {
        return _map.keyType.getDeploymentRef(null, _accessor) + ", " + _map.valueType.getDeploymentRef(null, _accessor) 
    }
    
    def private dispatch String getDeploymentParameter(FStructType _struct, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""

        for (s : _struct.elements) {
            parameter += s.getDeploymentRef(s.array, _struct, null, _accessor)
            if (s != _struct.elements.last) parameter += ", "    
        }            
        
        return parameter
    }
    
	def private dispatch String getDeploymentParameter(FUnionType _union, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        
        var PropertyAccessor.DBusVariantType variantType = _accessor.getDBusVariantTypeHelper(_source)
        if (variantType == null && _union != _source)
            variantType = _accessor.getDBusVariantTypeHelper(_union)

        if (variantType != null)
            parameter += "true, "
        else
            parameter += "false, "

        for (s : _union.elements) {
            parameter += s.getDeploymentRef(s.array, _union, null, _accessor)
            if (s != _union.elements.last) parameter += ", "    
        }         

        return parameter
    }
    
    def private dispatch String getDeploymentParameter(FBasicTypeId _typeId, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        if (_typeId == FBasicTypeId.STRING) {
        	if (_accessor.getDBusIsObjectPathHelper(_source)) parameter = "true" else parameter = "false"
        }
        return parameter
    }
    
    def private dispatch String getDeploymentParameter(FTypeRef _typeRef, EObject _source, PropertyAccessor _accessor) {
        if (_typeRef.derived != null) {
            return _typeRef.derived.getDeploymentParameter(_source, _accessor)
        }
        
        if (_typeRef.predefined != null) {
            return _typeRef.predefined.getDeploymentParameter(_source, _accessor)
        }
        
        return ""
    }
    
    def private dispatch String getDeploymentParameter(FAttribute _attribute, EObject _object, PropertyAccessor _accessor) {
        if (_attribute.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_attribute.type, _object, _accessor)
	        val arrayDeploymentParameter = getArrayDeploymentParameter(_attribute, _attribute, _accessor) 
	        if ("" != arrayDeploymentParameter) {
	        	parameter += ", " +  arrayDeploymentParameter
	       	}
            return parameter
        }
        return _attribute.type.getDeploymentParameter(_attribute, _accessor)
    }

    def private dispatch String getDeploymentParameter(FArgument _argument, EObject _object, PropertyAccessor _accessor) {
        if (_argument.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_argument.type, _object, _accessor)
	        val arrayDeploymentParameter = getArrayDeploymentParameter(_argument, _argument, _accessor) 
	        if ("" != arrayDeploymentParameter) {
	        	parameter += ", " +  arrayDeploymentParameter
	       	}

            return parameter
        }
        return _argument.type.getDeploymentParameter(_argument, _accessor)
    }
    
    // Arrays may be either defined types or inline
    def private String getArrayElementTypeDeploymentParameter(FTypeRef _elementType, EObject _source, PropertyAccessor _accessor) {
        return _elementType.getDeploymentRef(null, _accessor)
    } 

    def private String getArrayDeploymentParameter(EObject _array, EObject _source, PropertyAccessor _accessor) { 
        var String parameter = ""
      
        return parameter
    }
}
