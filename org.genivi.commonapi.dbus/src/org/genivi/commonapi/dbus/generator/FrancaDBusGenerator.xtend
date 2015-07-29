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
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.dsl.FrancaPersistenceManager
import org.franca.core.franca.FModel
import org.franca.deploymodel.core.FDModelExtender
import org.franca.deploymodel.core.FDeployedInterface
import org.franca.deploymodel.core.FDeployedTypeCollection
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDModel
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
	
    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess)
    {
        var FModel fModel
        var List<FDInterface> deployedDBusInterfaces
        var List<FDInterface> deployedCoreInterfaces
		var List<FDTypes> deployedTypeCollections
	    var IResource res = null
        val String DBUS_SPECIFICATION_TYPE = "dbus.deployment"
        val String CORE_SPECIFICATION_TYPE = "core.deployment"
                
        if(input.URI.fileExtension.equals(francaPersistenceManager.fileExtension))
        {
            fModel = francaPersistenceManager.loadModel(input.URI, input.URI)
            deployedDBusInterfaces = new LinkedList<FDInterface>()
			deployedTypeCollections = new LinkedList<FDTypes>()
			
			createAndInsertAccessors(fModel, deployedDBusInterfaces, deployedTypeCollections)
        }
        // load the model from deployment file
        else if(input.URI.fileExtension.equals(FDeployManager.fileExtension))
        {
        	var model = fDeployManager.loadModel(input.URI, input.URI);
            if(model instanceof FDModel) {
                val fModelExtender = new FDModelExtender(model);
            	var fdinterfaces = fModelExtender.getFDInterfaces()
            	// we need at least one FDInterface to access the model !
            	if(fdinterfaces.size > 0) {
            		fModel = fdinterfaces.get(0).target.model     
            	} else {
            		// empty deployment !
            		// try to load the imported fidl from the fdepl
            		fModel = fDeployManager.getModelFromFdepl(model, input.URI)
            	}
            	checkArgument(fModel != null, "\nFailed to load the model from fdepl file,\ncannot generate code.")
            	// read deployment information                   
               	deployedTypeCollections = fModelExtender.getFDTypesList()
            	deployedDBusInterfaces = getFDInterfaces(model, DBUS_SPECIFICATION_TYPE)
            	deployedCoreInterfaces = getFDInterfaces(model, CORE_SPECIFICATION_TYPE)

				// If we have core deployments...	
				if(!deployedCoreInterfaces.isEmpty) {
					// ...and no dbus deployment 
					if(deployedDBusInterfaces.isEmpty) {
						// ...transfer the core into a dbus like deployment
						deployedCoreInterfaces.get(0).getSpec().setName("org.genivi.commonapi.dbus.deployment")
						deployedDBusInterfaces.add(deployedCoreInterfaces.get(0))
					}
				else { // if we have one dbus deployment...
           			for(source : deployedCoreInterfaces) {
            			// ...merge the core depolyments into the dbus deployment
            			mergeDeployments(source, deployedDBusInterfaces.get(0))
            			} 
           			}
            	}
            	createAndInsertAccessors(fModel, deployedDBusInterfaces, deployedTypeCollections)

            } else if(model instanceof FModel) {
            	fModel = model
            	deployedDBusInterfaces = new LinkedList<FDInterface>()
            }
        }
        else
        {
            checkArgument(false, "Unknown input: " + input)
        }
        try
        {
            var pathfile = input.URI.toPlatformString(false)
            if(pathfile == null)
            {
                pathfile = FPreferencesDBus::instance.getModelPath(fModel)
            }
            if(pathfile.startsWith("platform:/"))
            {
                pathfile = pathfile.substring(pathfile.indexOf("platform") + 10)
                pathfile = pathfile.substring(pathfile.indexOf(System.getProperty("file.separator")))
            }
            res = ResourcesPlugin.workspace.root.findMember(pathfile)
        }
        catch(IllegalStateException e)
        {
        } //will be thrown only when the cli calls the francagenerator
        doGenerateDBusComponents(fModel, deployedDBusInterfaces, fileSystemAccess, res)
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

    def private doGenerateDBusComponents(FModel fModel, List<FDInterface> deployedInterfaces, IFileSystemAccess fileSystemAccess,
        IResource res)
    {
        val defaultDeploymentAccessor = new PropertyAccessor()
        
        fModel.typeCollections.forEach [
        	it.generateTypeCollectionDeployment(fileSystemAccess, getAccessor(it), res)
        ] 
     
        
        fModel.interfaces.forEach [
            val currentInterface = it
            var PropertyAccessor deploymentAccessor
            if(deployedInterfaces.exists[it.target == currentInterface])
            {
                deploymentAccessor = new PropertyAccessor(
                    new FDeployedInterface(deployedInterfaces.filter[it.target == currentInterface].last))
            }
            else
            {
                deploymentAccessor = defaultDeploymentAccessor
            }
            val booleanTrue = Boolean.toString(true)
            var String finalValue = booleanTrue
            finalValue = FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATEPROXY_DBUS, finalValue)
            if(finalValue.equals(booleanTrue))
            {
                it.generateDBusProxy(fileSystemAccess, deploymentAccessor, res)
            }
            finalValue = booleanTrue
            finalValue = FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATESTUB_DBUS, finalValue)
            if(finalValue.equals(booleanTrue))
            {
                it.generateDBusStubAdapter(fileSystemAccess, deploymentAccessor, res)
            }
			it.generateDeployment(fileSystemAccess, deploymentAccessor, res)      
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if(deployedInterfaces.exists[it.target == currentManagedInterface])
                {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(deployedInterfaces.filter[it.target == currentManagedInterface].last))
                }
                else
                {
                    managedDeploymentAccessor = defaultDeploymentAccessor
                }
                it.generateDBusProxy(fileSystemAccess, managedDeploymentAccessor, res)
                
                it.generateDBusStubAdapter(fileSystemAccess, managedDeploymentAccessor, res)
            ]
        ]
    }

}
