/* Copyright (C) 2013-2015 BMW Group
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.generator

import java.io.File
import java.util.HashSet
import java.util.LinkedList
import java.util.List
import java.util.Map
import java.util.Set
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

import org.franca.core.dsl.FrancaPersistenceManager
import org.franca.core.franca.FModel
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

class FrancaDBusGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaDBusGeneratorExtensions
    @Inject private extension FInterfaceDBusProxyGenerator
    @Inject private extension FInterfaceDBusStubAdapterGenerator
    @Inject private extension FInterfaceDBusDeploymentGenerator

    @Inject private FrancaPersistenceManager francaPersistenceManager
    @Inject private FDeployManager fDeployManager

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        if (!input.URI.fileExtension.equals(francaPersistenceManager.fileExtension) &&
            !input.URI.fileExtension.equals(FDeployManager.fileExtension)) {
                return
        }
        
        var List<FDInterface> deployedInterfaces = new LinkedList<FDInterface>()
        var List<FDTypes> deployedTypeCollections = new LinkedList<FDTypes>()
        var List<FDProvider> deployedProviders = new LinkedList<FDProvider>()

        var IResource res = null
        
        val String CORE_SPECIFICATION_TYPE = "core.deployment"
        val String DBUS_SPECIFICATION_TYPE = "dbus.deployment"

        var rootModel = fDeployManager.loadModel(input.URI, input.URI)

        generatedFiles_ = new HashSet<String>()

        withDependencies_ = FPreferencesDBus::instance.getPreference(
            PreferenceConstantsDBus::P_GENERATE_DEPENDENCIES_DBUS, "true"
        ).equals("true")

        var models = fDeployManager.fidlModels
        var deployments = fDeployManager.deploymentModels
        
        if (rootModel instanceof FDModel) {
            deployments.put(input.URI.toString, rootModel)
        } else if (rootModel instanceof FModel) {
            models.put(input.URI.toString, rootModel)
        }
        
        for (itsEntry : deployments.entrySet) {
            val itsDeployment = itsEntry.value
            
            // Get Core deployments
            val itsCoreInterfaces = getFDInterfaces(itsDeployment, CORE_SPECIFICATION_TYPE)
            val itsCoreTypeCollections = getFDTypesList(itsDeployment, CORE_SPECIFICATION_TYPE)

            // Get DBus deployments
            val itsDBusInterfaces = getFDInterfaces(itsDeployment, DBUS_SPECIFICATION_TYPE)
            val itsDBusTypeCollections = getFDTypesList(itsDeployment, DBUS_SPECIFICATION_TYPE)
            val itsDBusProviders = getFDProviders(itsDeployment, DBUS_SPECIFICATION_TYPE)

            // Merge Core deployments for interfaces to their DBus deployments
            for (itsDBusDeployment : itsDBusInterfaces)
                for (itsCoreDeployment : itsCoreInterfaces)
                    mergeDeployments(itsCoreDeployment, itsDBusDeployment)

            // Merge Core deployments for type collections to their DBus deployments
            for (itsDBusDeployment : itsDBusTypeCollections)
                for (itsCoreDeployment : itsCoreTypeCollections)
                    mergeDeployments(itsCoreDeployment, itsDBusDeployment)

            deployedInterfaces.addAll(itsDBusInterfaces)
            deployedTypeCollections.addAll(itsDBusTypeCollections)
            deployedProviders.addAll(itsDBusProviders)
        }
        
        if (rootModel instanceof FDModel) {
            doGenerateDeployment(rootModel, deployments, models,
                deployedInterfaces, deployedTypeCollections, deployedProviders,
                fileSystemAccess, res)
        } else if (rootModel instanceof FModel) {
            doGenerateModel(rootModel, models,
                deployedInterfaces, deployedTypeCollections, deployedProviders,
                fileSystemAccess, res)
        }
        
        fDeployManager.clearFidlModels
        fDeployManager.clearDeploymentModels
    }
    
    def private void doGenerateDeployment(FDModel _deployment,
                                          Map<String, FDModel> _deployments,
                                          Map<String, FModel> _models,
                                          List<FDInterface> _interfaces,
                                          List<FDTypes> _typeCollections,
                                          List<FDProvider> _providers,
                                          IFileSystemAccess _access,
                                          IResource _res) {
        val String deploymentName
            = _deployments.entrySet.filter[it.value == _deployment].head.key
        
        var int lastIndex = deploymentName.lastIndexOf(File.separatorChar)
        if (lastIndex == -1) {
            lastIndex = deploymentName.lastIndexOf('/')
        }

        var String basePath = deploymentName.substring(
            0, lastIndex)
                        
        var Set<String> itsImports = new HashSet<String>()
        for (anImport : _deployment.imports) {
            val String cannonical = basePath.getCanonical(anImport.importURI)
            itsImports.add(cannonical)
        }                                                
                
        if (withDependencies_) {
            for (itsEntry : _deployments.entrySet) {
                if (itsImports.contains(itsEntry.key)) {
                    doGenerateDeployment(itsEntry.value, _deployments, _models,
                        _interfaces, _typeCollections, _providers,
                        _access, _res)
                }                                
            }
        }
        
        for (itsEntry : _models.entrySet) {
            if (itsImports.contains(itsEntry.key)) {
                doGenerateModel(itsEntry.value, _models,
                    _interfaces, _typeCollections, _providers,
                    _access, _res)
            }    
        }                        
    }

    def private void doGenerateModel(FModel _model,
                                     Map<String, FModel> _models,
                                     List<FDInterface> _interfaces,
                                     List<FDTypes> _typeCollections,
                                     List<FDProvider> _providers,
                                     IFileSystemAccess _access,
                                     IResource _res) {
        val String modelName
            = _models.entrySet.filter[it.value == _model].head.key
            
        if (generatedFiles_.contains(modelName)) {
            return
        }       
        
        generatedFiles_.add(modelName)
                
        doGenerateComponents(_model,
            _interfaces, _typeCollections, _providers,
            _access, _res)
            
        if (withDependencies_) {
            for (itsEntry : _models.entrySet) {
                var FModel itsModel = itsEntry.value
                if (itsModel != null) {
                    doGenerateComponents(itsModel,
                        _interfaces, _typeCollections, _providers,
                        _access, _res)
                }
            }            
        }                       
    }
    
    def private void doGenerateComponents(FModel _model,
                                          List<FDInterface> _interfaces,
                                          List<FDTypes> _typeCollections,
                                          List<FDProvider> _providers,
                                          IFileSystemAccess _access,
                                          IResource _res) {
                                             
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

        var interfacesToGenerate = _model.interfaces.toSet
        var typeCollectionsToGenerate = _model.typeCollections.toSet

        typeCollectionsToGenerate.forEach [
            it.generateTypeCollectionDeployment(_access, getAccessor(it), _res)
        ]

        interfacesToGenerate.forEach [
            val currentInterface = it
            var PropertyAccessor deploymentAccessor
            if (_interfaces.exists[it.target == currentInterface]) {
                deploymentAccessor = new PropertyAccessor(
                    new FDeployedInterface(_interfaces.filter[it.target == currentInterface].last))
            } else {
                deploymentAccessor = defaultDeploymentAccessor
            }
            if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATE_PROXY_DBUS, "true").
                equals("true")) {
                it.generateDBusProxy(_access, deploymentAccessor, _providers, _res)
            }
            if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATE_STUB_DBUS, "true").
                equals("true")) {
                it.generateDBusStubAdapter(_access, deploymentAccessor, _providers, _res)
            }
            
            if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATE_COMMON_DBUS, "true").
                equals("true")) {
                it.generateDeployment(_access, deploymentAccessor, _res)
            }
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if (_interfaces.exists[it.target == currentManagedInterface]) {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(_interfaces.filter[it.target == currentManagedInterface].last))
                } else {
                    managedDeploymentAccessor = defaultDeploymentAccessor
                }
                
                if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATE_PROXY_DBUS, "true").
                    equals("true")) {
                    it.generateDBusProxy(_access, managedDeploymentAccessor, _providers, _res)
                }
                if (FPreferencesDBus::instance.getPreference(PreferenceConstantsDBus::P_GENERATE_STUB_DBUS, "true").
                    equals("true")) {
                    it.generateDBusStubAdapter(_access, managedDeploymentAccessor, _providers, _res)
                }
            ]
        ]
    }
    
    private boolean withDependencies_
    private Set<String> generatedFiles_    
}
