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
import org.genivi.commonapi.core.deployment.DeploymentInterfacePropertyAccessorWrapper
import org.genivi.commonapi.core.deployment.DeploymentInterfacePropertyAccessor
import org.franca.deploymodel.core.FDeployedInterface

import static com.google.common.base.Preconditions.*
import org.franca.core.franca.FModel
import java.util.List
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import java.util.LinkedList
import org.franca.deploymodel.dsl.FDeployPersistenceManager
import org.franca.deploymodel.core.FDModelExtender

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator
    @Inject private extension FrancaGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployPersistenceManager fDeployPersistenceManager
    @Inject private FrancaGenerator francaGenerator

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        var FModel fModel
        var List<FDInterface> deployedInterfaces

        if(input.URI.fileExtension.equals(francaPersistenceManager.fileExtension)) {
            francaGenerator.doGenerate(input, fileSystemAccess);
            fModel = francaPersistenceManager.loadModel(input.filePath)
            deployedInterfaces = new LinkedList<FDInterface>()

        } else if (input.URI.fileExtension.equals("fdepl" /* fDeployPersistenceManager.fileExtension */)) {
            francaGenerator.doGenerate(input, fileSystemAccess);

            var fDeployedModel = fDeployPersistenceManager.loadModel(input.filePathUrl);
            val fModelExtender = new FDModelExtender(fDeployedModel);

            checkArgument(fModelExtender.getFDInterfaces().size > 0, "No Interfaces were deployed, nothing to generate.")
            fModel = fModelExtender.getFDInterfaces().get(0).target.model
            deployedInterfaces = fModelExtender.getFDInterfaces()

        } else {
            checkArgument(false, "Unknown input: " + input)
        }

        doGenerateDBusComponents(fModel, deployedInterfaces, fileSystemAccess)
    }


    def private doGenerateDBusComponents(FModel fModel, List<FDInterface> deployedInterfaces, IFileSystemAccess fileSystemAccess) {
        val defaultDeploymentAccessor = new DeploymentInterfacePropertyAccessorWrapper(null) as DeploymentInterfacePropertyAccessor

        fModel.interfaces.forEach[
            val currentInterface = it
            var DeploymentInterfacePropertyAccessor deploymentAccessor
            if(deployedInterfaces.exists[it.target == currentInterface]) {
                deploymentAccessor = new DeploymentInterfacePropertyAccessor(new FDeployedInterface(deployedInterfaces.filter[it.target == currentInterface].last))
            } else {
                deploymentAccessor = defaultDeploymentAccessor
            }
            generateDBusProxy(fileSystemAccess, deploymentAccessor)
            generateDBusStubAdapter(fileSystemAccess, deploymentAccessor)
        ]
    }
}