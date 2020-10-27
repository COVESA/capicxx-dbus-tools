/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
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
import org.franca.core.franca.FInterface
import org.franca.core.franca.FIntegerInterval

class FrancaDBusDeploymentAccessorHelper {
	@Inject extension FrancaDBusGeneratorExtensions

    static PropertyAccessor.DBusVariantType DBUS_DEFAULT_VARIANT_TYPE
        = PropertyAccessor.DBusVariantType.CommonAPI;

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypedElement _element) {
        if (_accessor === null)
            return false
        if (_accessor.getDBusIsObjectPathHelper(_element)) {
            return true
        }
        if (_accessor.getDBusIsUnixFDHelper(_element)) {
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
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(element);
            if (overwriteAccessor.hasDeployment(element)) {
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

            if (variantType !== null && variantType != DBUS_DEFAULT_VARIANT_TYPE &&
                (type === null || variantType != _accessor.getDBusVariantTypeHelper(type))) {
                return true
            }
        } catch (NullPointerException e) {}

        for (element : _union.elements) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(element);
            if (overwriteAccessor.hasDeployment(element)) {
                return true
            }
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeDef _typeDef) {
        return _accessor.hasDeployment(_typeDef.actualType)
    }
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FIntegerInterval _type) {
        return false
    }
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FBasicTypeId _type) {
        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FType _type) {
        return false;
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeRef _type) {
        if (_type.derived !== null)
            return _accessor.hasDeployment(_type.derived)
        if (_type.interval !== null)
            return _accessor.hasDeployment(_type.interval)
        if (_type.predefined !== null)
            return _accessor.hasDeployment(_type.predefined)

        return false
    }
    def PropertyAccessor getSpecificAccessor(EObject _object) {
        var container = _object.eContainer
        while (container !== null) {
            if(container instanceof FInterface) {
                return getDBusAccessor(container)
            }
            if(container instanceof FTypeCollection) {
                return getDBusAccessor(container)
            }
            container = container.eContainer
        }
        return null
    }
    def boolean hasSpecificDeployment(PropertyAccessor _accessor,
                                      FTypedElement _attribute) {
        var FType type = null
        if (_attribute.type.derived !== null) {
            type = _attribute.type.derived
        }
		val specificAccessor = getSpecificAccessor(_attribute)
        try {
            val PropertyAccessor.DBusVariantType variantType
                = _accessor.getDBusVariantTypeHelper(_attribute)
			val PropertyAccessor.DBusVariantType defaultVariantType =
			if (type !== null && specificAccessor !== null) {
				specificAccessor.getDBusVariantTypeHelper(type)
			}
			else {
				DBUS_DEFAULT_VARIANT_TYPE
			}

            if (variantType !== null && variantType != DBUS_DEFAULT_VARIANT_TYPE &&
                (type === null || variantType != defaultVariantType)) {
                return true
            }

        } catch (NullPointerException e) {}

        try {
            val Boolean isPath = _accessor.getDBusIsObjectPathHelper(_attribute)
            if (isPath !== null && isPath) {
                return true
            }
        } catch (NullPointerException e) {}
        try {
            val Boolean isUnixFD = _accessor.getDBusIsUnixFDHelper(_attribute)
            if (isUnixFD !== null && isUnixFD) {
                return true
            }
        } catch (NullPointerException e) {}

        // also check for overwrites
        if (_accessor.isProperOverwrite()) {
            return true
        }
        return false
    }

    def Boolean getDBusIsObjectPathHelper(PropertyAccessor _accessor, EObject _obj) {
        return _accessor.getIsObjectPath(_obj);
    }
    def Boolean getDBusIsUnixFDHelper(PropertyAccessor _accessor, EObject _obj) {
        return _accessor.getIsUnixFD(_obj);
    }
    def PropertyAccessor.DBusVariantType getDBusVariantTypeHelper(PropertyAccessor _accessor, EObject _obj) {

        if (_obj instanceof FAttribute) {
            return _accessor.getDBusVariantTypeHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getDBusVariantTypeHelper(_obj.type.derived)
        }

        if (_obj instanceof FField) {
            return _accessor.getDBusVariantTypeHelper(_obj.type.derived)
        }

        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FUnionType) {
                    return _accessor.getDBusVariantType(_obj.actualType.derived as FUnionType)
                }
            } else {
                return DBUS_DEFAULT_VARIANT_TYPE
            }
        }
        if (_obj instanceof FUnionType)
            return _accessor.getDBusVariantType(_obj)

        return DBUS_DEFAULT_VARIANT_TYPE
    }

}
