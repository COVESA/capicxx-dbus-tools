/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.dsl.FrancaIDLHelpers
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions

import static com.google.common.base.Preconditions.*
import org.genivi.commonapi.core.generator.FrancaGenerator

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator

    @Inject private FrancaGenerator francaGenerator

	override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
	    val isFrancaIDLResource = input.URI.fileExtension.equals(FrancaIDLHelpers::instance.fileExtension)
        checkArgument(isFrancaIDLResource, "Unknown input: " + input)

        francaGenerator.doGenerate(input, fileSystemAccess);

        val fModel = FrancaIDLHelpers::instance.loadModel(input.filePath)
        fModel.interfaces.forEach[
            generateDBusProxy(fileSystemAccess)
            generateDBusStubAdapter(fileSystemAccess)
        ]
	}
}