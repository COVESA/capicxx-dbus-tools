/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.dsl.FrancaPersistenceManager
import org.genivi.commonapi.core.generator.FrancaGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions

import static com.google.common.base.Preconditions.*

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FrancaGenerator francaGenerator

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        val isFrancaIDLResource = input.URI.fileExtension.equals(francaPersistenceManager.fileExtension)
        checkArgument(isFrancaIDLResource, "Unknown input: " + input)

        francaGenerator.doGenerate(input, fileSystemAccess);

        val fModel = francaPersistenceManager.loadModel(input.filePath)
        fModel.interfaces.forEach[
            generateDBusProxy(fileSystemAccess)
            generateDBusStubAdapter(fileSystemAccess)
        ]
    }
}