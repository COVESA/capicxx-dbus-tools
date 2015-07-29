// Copyright (C) 2014, 2015 BMW Group
// Author: Lutz Bichler (lutz.bichler@bmw.de)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.franca.core.franca.FArgument
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FField
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypedElement
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import org.franca.core.franca.FMapType

class FrancaDBusDeploymentAccessorHelper {
	@Inject private extension FrancaDBusGeneratorExtensions
	
    static PropertyAccessor.DBusVariantType DBUS_DEFAULT_VARIANT_TYPE 
        = PropertyAccessor.DBusVariantType.CommonAPI;	
	
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypedElement _element) {
    	if (_accessor == null)
    		return false
        if (_accessor.getDBusIsObjectPathHelper(_element)) {
            return true
        }    		
        return _accessor.hasDeployment(_element.type)
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FArrayType _array) {
        if (_accessor.hasDeployment(_array.elementType)) {
            return true
        }
        
        return false
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FEnumerationType _enum) {
    	return false
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FStructType _struct) {
        for (element : _struct.elements) {
            if (_accessor.hasDeployment(element)) {
                return true
            }
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FMapType _map) {
        return _accessor.hasDeployment(_map.valueType);
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FUnionType _union) {
        try {
            var FType type = null
            val PropertyAccessor.DBusVariantType variantType
                = _accessor.getDBusVariantTypeHelper(_union)

            if (variantType != null && variantType != DBUS_DEFAULT_VARIANT_TYPE &&
                (type == null || variantType != _accessor.getDBusVariantTypeHelper(type))) {
                return true
            }
        } catch (NullPointerException e) {}

        for (element : _union.elements) {
            if (_accessor.hasDeployment(element)) {
                return true
            }
        }

        return false
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeDef _typeDef) {
        return _accessor.hasDeployment(_typeDef.actualType)
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FBasicTypeId _type) {
        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FType _type) {
        return false;
    }
    
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeRef _type) {
        if (_type.derived != null)
            return _accessor.hasDeployment(_type.derived)
 
        if (_type.predefined != null)
            return _accessor.hasDeployment(_type.predefined)
 
        return false 
    }
    
    def boolean hasSpecificDeployment(PropertyAccessor _accessor, 
                                      FTypedElement _attribute) {
        var FType type = null
        if (_attribute.type.derived != null) {
            type = _attribute.type.derived
        }                                       	
                                      	
        try {
            val PropertyAccessor.DBusVariantType variantType
                = _accessor.getDBusVariantTypeHelper(_attribute)
                
            if (variantType != null && variantType != DBUS_DEFAULT_VARIANT_TYPE &&
                (type == null || variantType != _accessor.getDBusVariantTypeHelper(type))) {
                return true
            }
        } catch (NullPointerException e) {}     
                                          	
        try {
            val Boolean isPath = _accessor.getDBusIsObjectPathHelper(_attribute)
            if (isPath != null && isPath) {
                return true
            }  
        } catch (NullPointerException e) {}                                      	
        return false
    }
    
    def Boolean getDBusIsObjectPathHelper(PropertyAccessor _accessor, EObject _obj) {
    	var PropertyAccessor parentAccessor = _accessor;
		var FTypeCollection tc = _obj.findTypeCollection 	
	    if (tc != null)
	    	parentAccessor = tc.accessor
	    if (parentAccessor != null)
    		return parentAccessor.getIsObjectPath(_obj);
    	return new Boolean(false);
    }
    
    def PropertyAccessor.DBusVariantType getDBusVariantTypeHelper(PropertyAccessor _accessor, EObject _obj) {
    	
    	var PropertyAccessor parentAccessor = _accessor;
		var FTypeCollection tc = _obj.findTypeCollection
	    if (tc != null && tc.accessor != null) {
	    	parentAccessor = tc.accessor
	    }	

        if (_obj instanceof FAttribute) {
            return parentAccessor.getDBusAttrVariantType(_obj)
        }
        
        if (_obj instanceof FArgument) {
            return parentAccessor.getDBusArgVariantType(_obj)
        }
        
        if (_obj instanceof FField) {
            var PropertyAccessor.DBusVariantType variantType = parentAccessor.getDBusStructVariantType(_obj)
            if (variantType == null)
                variantType = parentAccessor.getDBusUnionVariantType(_obj)
            return variantType
        }

        if (_obj.eContainer() instanceof FUnionType) {
            return parentAccessor.getDBusUnionVariantType(_obj)
        }
        
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived != null) {
                return parentAccessor.getDBusVariantType(_obj.actualType.derived)
            } else {
                return DBUS_DEFAULT_VARIANT_TYPE
            }
        }
        
        return parentAccessor.getDBusVariantType(_obj)
    }
   
}
