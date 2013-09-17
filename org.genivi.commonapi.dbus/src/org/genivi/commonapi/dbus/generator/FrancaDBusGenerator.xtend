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
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessorWrapper
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessor

import static com.google.common.base.Preconditions.*
import org.franca.core.franca.FModel
import java.util.List
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import java.util.LinkedList
import org.franca.deploymodel.dsl.FDeployPersistenceManager
import org.franca.deploymodel.core.FDModelExtender
import org.franca.deploymodel.core.FDeployedInterface
import org.genivi.commonapi.dbus.deployment.DeploymentInterfacePropertyAccessor$PropertiesType
import org.eclipse.core.runtime.preferences.DefaultScope
import org.genivi.commonapi.core.preferences.PreferenceConstants
import org.eclipse.core.runtime.preferences.InstanceScope
import org.eclipse.core.resources.ResourcesPlugin
import org.genivi.commonapi.core.preferences.FPreferences
import org.eclipse.core.runtime.QualifiedName
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.core.resources.IResource
import org.eclipse.core.runtime.preferences.IEclipsePreferences
import org.osgi.framework.FrameworkUtil

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployPersistenceManager fDeployPersistenceManager
    @Inject private FrancaGenerator francaGenerator

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        var FModel fModel
        var List<FDInterface> deployedInterfaces
        var IResource res = null
        var EclipseResourceFileSystemAccess2 accessspez

        if (input.URI.fileExtension.equals(francaPersistenceManager.fileExtension)) {
            francaGenerator.doGenerate(input, fileSystemAccess);
            fModel = francaPersistenceManager.loadModel(input.filePath)
            deployedInterfaces = new LinkedList<FDInterface>()

        } else if (input.URI.fileExtension.equals("fdepl"/* fDeployPersistenceManager.fileExtension */)) {
            francaGenerator.doGenerate(input, fileSystemAccess);

            var fDeployedModel = fDeployPersistenceManager.loadModel(input.URI, input.URI);
            val fModelExtender = new FDModelExtender(fDeployedModel);

            checkArgument(fModelExtender.getFDInterfaces().size > 0, "No Interfaces were deployed, nothing to generate.")
            fModel = fModelExtender.getFDInterfaces().get(0).target.model
            deployedInterfaces = fModelExtender.getFDInterfaces()

        } else {
            checkArgument(false, "Unknown input: " + input)
        }
        try {
            var pathfile = input.URI.toPlatformString(false)
            if (pathfile == null) {
                pathfile = FPreferences::instance.getModelPath(fModel)
            }
            if (pathfile.startsWith("platform:/")) {
                pathfile = pathfile.substring(pathfile.indexOf("platform") + 10)
                pathfile = pathfile.substring(pathfile.indexOf(System.getProperty("file.separator")))
            }
            res = ResourcesPlugin.workspace.root.findMember(pathfile)
            accessspez = fileSystemAccess as EclipseResourceFileSystemAccess2
            FPreferences.instance.addPreferences(res);
            if (FPreferences.instance.useModelSpecific(res)) {
                var output = res.getPersistentProperty(
                    new QualifiedName(PreferenceConstants.PROJECT_PAGEID, PreferenceConstants.P_OUTPUT))
                if (output != null && output.length != 0) {
                    accessspez.setOutputPath(output)
                }
            }
        } catch (IllegalStateException e) {} //will be thrown only when the cli calls the francagenerator
        doGenerateDBusComponents(fModel, deployedInterfaces, fileSystemAccess, res)
        if(res != null) {
            var deflt = DefaultScope::INSTANCE.getNode(PreferenceConstants::SCOPE).get(PreferenceConstants::P_OUTPUT,
                PreferenceConstants::DEFAULT_OUTPUT);
            deflt = InstanceScope::INSTANCE.getNode(PreferenceConstants::SCOPE).get(PreferenceConstants::P_LICENSE,
                        deflt)
            deflt = FPreferences.instance.getPreference(res, PreferenceConstants.P_OUTPUT, deflt)
            accessspez.setOutputPath(deflt)
        }
    }

    def private doGenerateDBusComponents(FModel fModel, List<FDInterface> deployedInterfaces,
        IFileSystemAccess fileSystemAccess, IResource res) {
        val defaultDeploymentAccessor = new DeploymentInterfacePropertyAccessorWrapper(null) as DeploymentInterfacePropertyAccessor

        fModel.interfaces.forEach [
            val currentInterface = it
            var DeploymentInterfacePropertyAccessor deploymentAccessor
            if (deployedInterfaces.exists[it.target == currentInterface]) {
                deploymentAccessor = new DeploymentInterfacePropertyAccessor(
                    new FDeployedInterface(deployedInterfaces.filter[it.target == currentInterface].last))
            } else {
                deploymentAccessor = defaultDeploymentAccessor
            }

            val booleanTrue = Boolean.toString(true)
            var IEclipsePreferences node

            var String finalValue = booleanTrue
            if (FrameworkUtil::getBundle(this.getClass()) != null) {
                node = DefaultScope::INSTANCE.getNode(PreferenceConstants::SCOPE)
                finalValue = node.get(PreferenceConstants::P_GENERATEPROXY, booleanTrue)

                node = InstanceScope::INSTANCE.getNode(PreferenceConstants::SCOPE)
                finalValue = node.get(PreferenceConstants::P_GENERATEPROXY, finalValue)
            }
            finalValue = FPreferences::instance.getPreference(res, PreferenceConstants::P_GENERATEPROXY, finalValue)
            if (finalValue.equals(booleanTrue)) {
                it.generateDBusProxy(fileSystemAccess, deploymentAccessor, res)
            }

            finalValue = booleanTrue
            if (FrameworkUtil::getBundle(this.getClass()) != null) {
                node = DefaultScope::INSTANCE.getNode(PreferenceConstants::SCOPE)
                finalValue = node.get(PreferenceConstants::P_GENERATESTUB, booleanTrue)
                node = InstanceScope::INSTANCE.getNode(PreferenceConstants::SCOPE)
                finalValue = node.get(PreferenceConstants::P_GENERATESTUB, finalValue)
            }

            finalValue = FPreferences::instance.getPreference(res, PreferenceConstants::P_GENERATESTUB, finalValue)
            if (finalValue.equals(booleanTrue)) {
                if (deploymentAccessor.getPropertiesType(currentInterface) == null ||
                    deploymentAccessor.getPropertiesType(currentInterface) == PropertiesType::CommonAPI) {
                    it.generateDBusStubAdapter(fileSystemAccess, deploymentAccessor, res)
                } else {
                    // Report no Stub here!
                }
            }

            it.managedInterfaces.forEach[
                val currentManagedInterface = it
                var DeploymentInterfacePropertyAccessor managedDeploymentAccessor
                if(deployedInterfaces.exists[it.target == currentManagedInterface]) {
                    managedDeploymentAccessor = new DeploymentInterfacePropertyAccessor(new FDeployedInterface(deployedInterfaces.filter[it.target == currentManagedInterface].last))
                } else {
                    managedDeploymentAccessor = defaultDeploymentAccessor
                }
                it.generateDBusProxy(fileSystemAccess, managedDeploymentAccessor, res)
                if (managedDeploymentAccessor.getPropertiesType(currentManagedInterface) == null || 
                    managedDeploymentAccessor.getPropertiesType(currentManagedInterface) == PropertiesType::CommonAPI) {
                    it.generateDBusStubAdapter(fileSystemAccess, managedDeploymentAccessor, res)
                } else {
                    // Report no Stub here!
                }
            ]
        ]
    }
}
