/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.franca.core.franca.FAttribute
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FMapType
import org.franca.core.franca.FStructType
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FUnionType
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FMethod
import org.franca.core.franca.FBroadcast
import org.genivi.commonapi.core.deployment.DeploymentInterfacePropertyAccessor

import static com.google.common.base.Preconditions.*
import org.franca.core.franca.FTypedElement

class FrancaDBusGeneratorExtensions {
    @Inject private extension FrancaGeneratorExtensions

    def dbusInSignature(FMethod fMethod, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        fMethod.inArgs.map[getTypeDbusSignature(deploymentAccessor)].join;
    }

    def dbusOutSignature(FMethod fMethod, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        var signature = fMethod.outArgs.map[getTypeDbusSignature(deploymentAccessor)].join;

        if (fMethod.hasError)
            signature = fMethod.dbusErrorSignature(deploymentAccessor) + signature

        return signature
    }

    def dbusErrorSignature(FMethod fMethod, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        checkArgument(fMethod.hasError, 'FMethod has no error: ' + fMethod)

        if (fMethod.errorEnum != null)
            return fMethod.errorEnum.dbusFTypeSignature(deploymentAccessor)
        
        return fMethod.errors.dbusFTypeSignature(deploymentAccessor)
    }

    def dbusSetMethodName(FAttribute fAttribute) {
        'set' + fAttribute.className
    }

    def dbusGetMethodName(FAttribute fAttribute) {
        'get' + fAttribute.className
    }
    
    def dbusSignalName(FAttribute fAttribute) {
        'on' + fAttribute.className + 'Changed'
    }

    def String dbusSignature(FAttribute fAttribute, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        fAttribute.getTypeDbusSignature(deploymentAccessor)
    }

    def String dbusSignature(FBroadcast fBroadcast, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        fBroadcast.outArgs.map[getTypeDbusSignature(deploymentAccessor)].join
    }
    
    def getTypeDbusSignature(FTypedElement element, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        if ("[]".equals(element.array)) {
            return "a" + element.type.dbusSignature(deploymentAccessor)
        } else {
            return element.type.dbusSignature(deploymentAccessor)
        }
    }

    def String dbusSignature(FTypeRef fTypeRef, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        if (fTypeRef.derived != null)
            return fTypeRef.derived.dbusFTypeSignature(deploymentAccessor)
        return fTypeRef.predefined.dbusSignature
    }

    def private dispatch dbusFTypeSignature(FTypeDef fTypeDef, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return fTypeDef.actualType.dbusSignature(deploymentAccessor)
    }

    def private dispatch dbusFTypeSignature(FArrayType fArrayType, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return 'a' + fArrayType.elementType.dbusSignature(deploymentAccessor)
    }

    def private dispatch dbusFTypeSignature(FMapType fMap, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return 'a{' + fMap.keyType.dbusSignature(deploymentAccessor) + fMap.valueType.dbusSignature(deploymentAccessor) + '}'
    }

    def private dispatch dbusFTypeSignature(FStructType fStructType, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return '(' + fStructType.getElementsDBusSignature(deploymentAccessor) + ')'
    }

    def private dispatch dbusFTypeSignature(FEnumerationType fEnumerationType, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return fEnumerationType.getBackingType(deploymentAccessor).dbusSignature
    }

    def private dispatch dbusFTypeSignature(FUnionType fUnionType, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        return '(yv)'
    }

    def private getElementsDBusSignature(FStructType fStructType, DeploymentInterfacePropertyAccessor deploymentAccessor) {
        var signature = fStructType.elements.map[getTypeDbusSignature(deploymentAccessor)].join

        if (fStructType.base != null) {
            signature = fStructType.base.getElementsDBusSignature(deploymentAccessor) + signature
        }

        return signature
    }

    def private dbusSignature(FBasicTypeId fBasicTypeId) {
        switch fBasicTypeId {
            case FBasicTypeId::BOOLEAN: 'b'
            case FBasicTypeId::INT8: 'y'
            case FBasicTypeId::UINT8: 'y'
            case FBasicTypeId::INT16: 'n'
            case FBasicTypeId::UINT16: 'q'
            case FBasicTypeId::INT32: 'i'
            case FBasicTypeId::UINT32: 'u'
            case FBasicTypeId::INT64: 'x'
            case FBasicTypeId::UINT64: 't'
            case FBasicTypeId::FLOAT: 'd'
            case FBasicTypeId::DOUBLE: 'd'
            case FBasicTypeId::STRING: 's'
            case FBasicTypeId::BYTE_BUFFER: 'ay'
            default: throw new IllegalArgumentException("Unsupported basic type: " + fBasicTypeId.name)
        }
    }
}