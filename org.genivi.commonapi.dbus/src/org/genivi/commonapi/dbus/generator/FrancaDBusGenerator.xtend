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
import org.franca.deploymodel.dsl.FDeployPersistenceManager
import org.genivi.commonapi.core.generator.FrancaGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.eclipse.emf.common.util.URI;

import static com.google.common.base.Preconditions.*
import org.franca.deploymodel.dsl.FDModelHelper
import org.franca.deploymodel.core.FDModelExtender
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.core.FDeployedInterface
import org.genivi.commonapi.dbus.DeploymentInterfacePropertyAccessor
import org.franca.core.utils.ModelPersistenceHandler
import org.franca.deploymodel.dsl.fDeploy.FDModel

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployPersistenceManager fDeployPersistenceManager
    @Inject private FrancaGenerator francaGenerator


    def private doGenerateStandardFrancaComponents(Resource input, IFileSystemAccess fileSystemAccess) {
        francaGenerator.doGenerate(input, fileSystemAccess);

        val fModel = francaPersistenceManager.loadModel(input.URI, input.URI)
        fModel.interfaces.forEach[
            generateDBusProxy(fileSystemAccess)
            generateDBusStubAdapter(fileSystemAccess)
        ]
    }


    def doGenerateDeployedFrancaComponents(Resource input, IFileSystemAccess access) {
//        if (fileURI.segmentCount() > 1) {
//            loadedModel = fDeployPersistenceManager.loadModel(fileURI.lastSegment(), fileURI.trimSegments(1).toString() + "/");
//        } else {
            var fDeployedModel = fDeployPersistenceManager.loadModel(input.URI, input.URI);
            
//        }

//        val deployedModel = new FDModelExtender(loadedModel)
        
//        val fdmodelExt = new FDModelExtender(fdModel);
//        for(FDInterface fdi : fdmodelExt.getFDInterfaces()) {
//            val deployed = new FDeployedInterface(fdi);
//            val accessor = new DeploymentInterfacePropertyAccessor(deployed);
//        }

//            if(deployedModel.FDProviders.size > 0) {
//                generateProviders(deployedModel, fileSystemAccess)
//            } else {
//                generateDeployedInterfaces(deployedModel, fileSystemAccess)
//            }

//        if (input.URI.fileExtension.equals(FrancaIDLHelpers::instance.fileExtension)) {
//
//            val basicModel = FrancaIDLHelpers::instance.loadModel(input.filePath)
//            if(basicModel.interfaces.size == 0) {
//                println("No interfaces are defined, nothing to generate.")
//                return
//            }
//
//            val deploymentAccessor = new DBusInterfacePropertyAccessorWrapper(null)
//
//            mainStubGenerator.generate(basicModel.interfaces, null, fileSystemAccess, outputLocation, skeletonFolderPath)
//            automakeGenerator.generate(basicModel.interfaces, null, fileSystemAccess, outputLocation, skeletonFolderPath)
//            initTypeGeneration
//            for (fInterface: basicModel.interfaces) {
//                generateInterface(fInterface, deploymentAccessor, fileSystemAccess)
//            }               
//            finalizeTypeGeneration(fileSystemAccess, outputLocation)
//
//        } else {
//            println("Provided File (" + input.URI + ") does not have a known file extension (.fidl or .fdepl)")
//        }
//
//        println("Generation successful");
//        return;
    }


    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        if(input.URI.fileExtension.equals(francaPersistenceManager.fileExtension)) {
            doGenerateStandardFrancaComponents(input, fileSystemAccess)
        } else if (input.URI.fileExtension.equals("fdepl" /* fDeployPersistenceManager.fileExtension */)) {
            doGenerateDeployedFrancaComponents(input, fileSystemAccess)
        } else {
            checkArgument(false, "Unknown input: " + input)
        }
    }

}