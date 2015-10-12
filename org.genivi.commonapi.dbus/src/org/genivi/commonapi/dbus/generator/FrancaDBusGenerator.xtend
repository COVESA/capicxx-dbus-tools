/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import java.util.LinkedList
import java.util.List
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.dsl.FrancaPersistenceManager
import org.franca.core.franca.FInterface
import org.franca.core.franca.FModel
import org.franca.core.franca.FTypeCollection
import org.franca.deploymodel.core.FDeployedInterface
import org.franca.deploymodel.core.FDeployedTypeCollection
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.franca.deploymodel.dsl.fDeploy.FDTypes
import org.genivi.commonapi.core.generator.FDeployManager
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus

import static com.google.common.base.Preconditions.*

class FrancaDBusGenerator implements IGenerator
{
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator
    @Inject private extension FInterfaceDBusDeploymentGenerator
    @Inject private extension FTypeCollectionDBusDeploymentGenerator
    
    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployManager fDeployManager

	
    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        var FModel fModel
        var List<FDInterface> deployedDBusInterfaces = new LinkedList<FDInterface>()
        var List<FDInterface> deployedCoreInterfaces = new LinkedList<FDInterface>()
        var List<FDTypes> deployedTypeCollections = new LinkedList<FDTypes>()
        var List<FDProvider> deployedProviders = new LinkedList<FDProvider>()
        var IResource res = null
        val String DBUS_SPECIFICATION_TYPE = "dbus.deployment"
        val String CORE_SPECIFICATION_TYPE = "core.deployment"
                
        // generate code from the fidl or fdepl file 
        if (input.URI.fileExtension.equals(francaPersistenceManager.fileExtension) ||
            input.URI.fileExtension.equals(FDeployManager.fileExtension)) {

            // load root model and imports
            var model = fDeployManager.loadModel(input.URI, input.URI);
            if (model instanceof FDModel) {

                // fdModels is the map of all deployment models from imported fdepl files
                var fdModels = fDeployManager.deploymentModels

                // get deployment parameter from this fdepl file (input.URI) 
                deployedDBusInterfaces = getFDInterfaces(model, DBUS_SPECIFICATION_TYPE)
                deployedCoreInterfaces = getFDInterfaces(model, CORE_SPECIFICATION_TYPE)
                deployedTypeCollections = getFDTypesList(model, DBUS_SPECIFICATION_TYPE)
                deployedProviders = getFDProviders(model, DBUS_SPECIFICATION_TYPE)

                // get deployment parameter from imported fdepls
                for (fdModelEntry : fdModels.entrySet) {

                    //System.out.println("Generation code for import: " + fdModelEntry.key)
                    var fdmodel = fdModelEntry.value
                    deployedDBusInterfaces.addAll(getFDInterfaces(fdmodel, DBUS_SPECIFICATION_TYPE))
                    deployedCoreInterfaces.addAll(getFDInterfaces(fdmodel, CORE_SPECIFICATION_TYPE))
                    deployedTypeCollections.addAll(getFDTypesList(fdmodel, DBUS_SPECIFICATION_TYPE))
                }
                var boolean hasInterfaces = (deployedDBusInterfaces.size > 0);
                var boolean hasTypeCollections = (deployedTypeCollections.size() > 0);
                val boolean hasProviders = (deployedProviders.size() > 0);

                if (hasInterfaces)
                    fModel = deployedDBusInterfaces.get(0).target.model
                else if (hasTypeCollections)
                    fModel = deployedTypeCollections.get(0).target.model

                if (fModel != null) {

                    // We have to merge core deployments into the dbus deployment
                    for (source : deployedCoreInterfaces) {
                        mergeDeployments(source, deployedDBusInterfaces.get(0))
                    }

                    // actually generate code
                    createAndInsertAccessors(fModel, deployedDBusInterfaces, deployedTypeCollections)
                    doGenerateDBusComponents(fModel, deployedDBusInterfaces, deployedProviders,
                        deployedTypeCollections, fileSystemAccess, res)
                }

                // Generate code for each instance interface for each provider
                if (hasProviders) {
                    for (provider : deployedProviders) {

                        //System.out.println("Processing provider " + provider.name)
                        for (import_ : model.imports) {
                            val importUri = import_.getImportURI
                            if (!importUri.contains("deployment_spec") && importUri.endsWith(".fdepl")) {

                                val fdeplUri = URI.createURI(importUri)

                                //System.out.println("loading and generating model from " + fdeplUri.lastSegment)
                                // try to find the deployment model for this fdepl in the map 
                                model = fdModels.get(fdeplUri.lastSegment)
                                checkArgument(model != null,
                                    "Could not find deployment model for " + fdeplUri.lastSegment)

                                //model = fDeployManager.loadModel(fdeplUri, input.URI)
                                if (model instanceof FDModel) {
                                    deployedDBusInterfaces.addAll(getFDInterfaces(model, DBUS_SPECIFICATION_TYPE))
                                    deployedCoreInterfaces.addAll(getFDInterfaces(model, CORE_SPECIFICATION_TYPE))
                                    deployedTypeCollections.addAll(getFDTypesList(model, DBUS_SPECIFICATION_TYPE))
                                    hasInterfaces = (deployedDBusInterfaces.size > 0)
                                    hasTypeCollections = (deployedTypeCollections.size() > 0)

                                    // We have to merge core deployments into the dbus deployment
                                    for (source : deployedCoreInterfaces) {
                                        mergeDeployments(source, deployedDBusInterfaces.get(0))
                                    }
                                    if (hasInterfaces)
                                        fModel = deployedDBusInterfaces.get(0).target.model
                                    else if (hasTypeCollections)
                                        fModel = deployedTypeCollections.get(0).target.model

                                    if (fModel != null) {

                                        // actually generate code
                                        createAndInsertAccessors(fModel, deployedDBusInterfaces, deployedTypeCollections)
                                        doGenerateDBusComponents(fModel, deployedDBusInterfaces, deployedProviders,
                                            deployedTypeCollections, fileSystemAccess, res)
                                    }
                                }
                            }
                        }
                    }
                }
                fDeployManager.clearDeploymentModels
                deployedDBusInterfaces.clear()
                deployedCoreInterfaces.clear()
                deployedTypeCollections.clear()
                deployedProviders.clear()
            }
            // generate code from a given fidl file
            else if (model instanceof FModel) {
                // fModels is the map of all models from imported fidl files
                var fModels = fDeployManager.fidlModels
                fModels.put(input.URI.lastSegment, model);

                for (fModelEntry : fModels.entrySet) {

                    //System.out.println("Generation code for: " + fModelEntry.key)
                    fModel = fModelEntry.value

                    if (fModel != null) {
                        // actually generate code
                        createAndInsertAccessors(fModel, deployedDBusInterfaces, deployedTypeCollections)
                        doGenerateDBusComponents(fModel, deployedDBusInterfaces, deployedProviders,
                            deployedTypeCollections, fileSystemAccess, res)
                    }
                }                            
                fDeployManager.clearFidlModels
            } else {
                checkArgument(false, "Unknown input: " + input)
            }
        }
    }

    def private createAndInsertAccessors(FModel _model, List<FDInterface> _interfaces, List<FDTypes> _typeCollections) {
    	val defaultDeploymentAccessor = new PropertyAccessor()
		_model.typeCollections.forEach [
    		var PropertyAccessor typeCollectionDeploymentAccessor
    		val currentTypeCollection = it
    		if (_typeCollections.exists[it.target == currentTypeCollection]) {
    			typeCollectionDeploymentAccessor = new PropertyAccessor(
                	new FDeployedTypeCollection(_typeCollections.filter[it.target == currentTypeCollection].last))
        	} else {
        		typeCollectionDeploymentAccessor = defaultDeploymentAccessor
        	}
        	insertAccessor(currentTypeCollection, typeCollectionDeploymentAccessor)
        ]
        
        _model.interfaces.forEach [
    		var PropertyAccessor interfaceDeploymentAccessor
    		val currentInterface = it
    		if (_interfaces.exists[it.target == currentInterface]) {
    			interfaceDeploymentAccessor = new PropertyAccessor(
                	new FDeployedInterface(_interfaces.filter[it.target == currentInterface].last))
        	} else {
        		interfaceDeploymentAccessor = defaultDeploymentAccessor
        	}
        	insertAccessor(currentInterface, interfaceDeploymentAccessor)
        ]
    }

    def private doGenerateDBusComponents(FModel fModel, List<FDInterface> deployedInterfaces,
        List<FDProvider> deployedProviders, List<FDTypes> deployedTypeCollections, IFileSystemAccess fileSystemAccess,
        IResource res) {
        val defaultDeploymentAccessor = new PropertyAccessor()

        var typeCollectionsToGenerate = fModel.typeCollections.toSet
        var interfacesToGenerate = fModel.interfaces.toSet

        // referenced type collections and interfaces
        val allReferencedFTypes = fModel.allReferencedFTypes
        val allTypeCollections = allReferencedFTypes.filter[eContainer instanceof FTypeCollection].map[
            eContainer as FTypeCollection]
        val allInterfaces = allReferencedFTypes.filter[eContainer instanceof FInterface].map[
            eContainer as FInterface]
        interfacesToGenerate = fModel.allReferencedFInterfaces.toSet
        typeCollectionsToGenerate.addAll(allTypeCollections)
        interfacesToGenerate.addAll(allInterfaces)

        typeCollectionsToGenerate.forEach [
        	it.generateTypeCollectionDeployment(fileSystemAccess, getAccessor(it), res)
        ] 
     
        
        interfacesToGenerate.forEach [
            val currentInterface = it
            var PropertyAccessor deploymentAccessor
            if (deployedInterfaces.exists[it.target == currentInterface]) {
                deploymentAccessor = new PropertyAccessor(
                    new FDeployedInterface(deployedInterfaces.filter[it.target == currentInterface].last))
            } else {
                deploymentAccessor = defaultDeploymentAccessor
            }
            if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATEPROXY_DBUS, "true").
                equals("true")) {
                it.generateDBusProxy(fileSystemAccess, deploymentAccessor, deployedProviders, res)
            }
            if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATESTUB_DBUS, "true").
                equals("true")) {
                it.generateDBusStubAdapter(fileSystemAccess, deploymentAccessor, deployedProviders, res)
            }
            it.generateDeployment(fileSystemAccess, deploymentAccessor, res)
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if (deployedInterfaces.exists[it.target == currentManagedInterface]) {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(deployedInterfaces.filter[it.target == currentManagedInterface].last))
                } else {
                    managedDeploymentAccessor = defaultDeploymentAccessor
                }
                it.generateDBusProxy(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
                it.generateDBusStubAdapter(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
            ]
        ]
    }
}
