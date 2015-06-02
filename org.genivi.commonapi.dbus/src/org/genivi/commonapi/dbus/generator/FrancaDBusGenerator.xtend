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
import org.eclipse.core.runtime.preferences.DefaultScope
import org.eclipse.core.runtime.preferences.IEclipsePreferences
import org.eclipse.core.runtime.preferences.InstanceScope
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.dsl.FrancaPersistenceManager
import org.franca.core.franca.FModel
import org.franca.deploymodel.core.FDModelExtender
import org.franca.deploymodel.core.FDeployedInterface
import org.franca.deploymodel.dsl.FDeployPersistenceManager
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.dbus.deployment.PropertyAccessor
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus
import org.osgi.framework.FrameworkUtil

import static com.google.common.base.Preconditions.*

class FrancaDBusGenerator implements IGenerator
{
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployPersistenceManager fDeployPersistenceManager

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess)
    {
        var FModel fModel
        var List<FDInterface> deployedInterfaces
        var IResource res = null
        if(input.URI.fileExtension.equals(francaPersistenceManager.fileExtension))
        {
            fModel = francaPersistenceManager.loadModel(input.URI, input.URI)
            deployedInterfaces = new LinkedList<FDInterface>()

        }
        else if(input.URI.fileExtension.equals("fdepl"/* fDeployPersistenceManager.fileExtension */))
        {
            var fDeployedModel = fDeployPersistenceManager.loadModel(input.URI, input.URI);
            val fModelExtender = new FDModelExtender(fDeployedModel);

            checkArgument(fModelExtender.getFDInterfaces().size > 0, "No Interfaces were deployed, nothing to generate.")
            fModel = fModelExtender.getFDInterfaces().get(0).target.model
            deployedInterfaces = fModelExtender.getFDInterfaces()

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
        doGenerateDBusComponents(fModel, deployedInterfaces, fileSystemAccess, res)
    }

    def private doGenerateDBusComponents(FModel fModel, List<FDInterface> deployedInterfaces, IFileSystemAccess fileSystemAccess,
        IResource res)
    {
        val defaultDeploymentAccessor = new PropertyAccessor()
        
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
