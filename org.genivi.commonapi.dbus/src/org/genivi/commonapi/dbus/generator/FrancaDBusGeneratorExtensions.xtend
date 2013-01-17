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

import static com.google.common.base.Preconditions.*
import org.franca.core.franca.FBroadcast

class FrancaDBusGeneratorExtensions {
    @Inject private extension FrancaGeneratorExtensions

    def dbusInSignature(FMethod fMethod) {
        fMethod.inArgs.map[type.dbusSignature].join;
    }

    def dbusOutSignature(FMethod fMethod) {
        var signature = fMethod.outArgs.map[type.dbusSignature].join;

        if (fMethod.hasError)
            signature = fMethod.dbusErrorSignature + signature

        return signature
    }

    def dbusErrorSignature(FMethod fMethod) {
        checkArgument(fMethod.hasError, 'FMethod has no error: ' + fMethod)

        if (fMethod.errorEnum != null)
            return fMethod.errorEnum.dbusFTypeSignature
        
        return fMethod.errors.dbusFTypeSignature
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

    def String dbusSignature(FAttribute fAttribute) {
        fAttribute.type.dbusSignature
    }

    def String dbusSignature(FBroadcast fBroadcast) {
        fBroadcast.outArgs.map[type.dbusSignature].join
    }

    def String dbusSignature(FTypeRef fTypeRef) {
        if (fTypeRef.derived != null)
            return fTypeRef.derived.dbusFTypeSignature
        return fTypeRef.predefined.dbusSignature
    }

    def private dispatch dbusFTypeSignature(FTypeDef fTypeDef) {
        return fTypeDef.actualType.dbusSignature
    }

    def private dispatch dbusFTypeSignature(FArrayType fArrayType) {
        return 'a' + fArrayType.elementType.dbusSignature
    }

    def private dispatch dbusFTypeSignature(FMapType fMap) {
        return 'a{' + fMap.keyType.dbusSignature + fMap.valueType.dbusSignature + '}'
    }

    def private dispatch dbusFTypeSignature(FStructType fStructType) {
        return '(' + fStructType.elementsDBusSignature + ')'
    }

    def private dispatch dbusFTypeSignature(FEnumerationType fEnumerationType) {
        return fEnumerationType.backingType.dbusSignature
    }

    def private dispatch dbusFTypeSignature(FUnionType fUnionType) {
        return '(yv)'
    }

    def private getElementsDBusSignature(FStructType fStructType) {
        var signature = fStructType.elements.map[type.dbusSignature].join

        if (fStructType.base != null)
            signature = fStructType.base.elementsDBusSignature + signature

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