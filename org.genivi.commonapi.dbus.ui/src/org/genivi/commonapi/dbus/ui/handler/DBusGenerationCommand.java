/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.dbus.ui.handler;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.QualifiedName;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.genivi.commonapi.core.preferences.PreferenceConstants;
import org.genivi.commonapi.core.ui.handler.GenerationCommand;
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;
import org.genivi.commonapi.dbus.ui.CommonApiDBusUiPlugin;

public class DBusGenerationCommand  extends GenerationCommand {

	/**
	 * Init dbus preferences
	 * @param page
	 * @param project
	 */
	@Override
	protected void setupPreferences(IFile file) {

		initDbusPreferences(file, CommonApiDBusUiPlugin.getDefault().getPreferenceStore());
	}	

	@Override
	protected EclipseResourceFileSystemAccess2 createFileSystemAccess() {

		final EclipseResourceFileSystemAccess2 fsa = fileAccessProvider.get();

		fsa.setOutputConfigurations(FPreferencesDBus.getInstance().getOutputpathConfiguration());

		fsa.setMonitor(new NullProgressMonitor());

		return fsa;
	}

	/**
	 * Set the properties for the code generation from the resource properties (set with the property page, via the context menu).
	 * Take default values from the eclipse preference page.
	 * @param file 
	 * @param store - the eclipse preference store
	 */
	public void initDbusPreferences(IFile file, IPreferenceStore store) {
		FPreferencesDBus instance = FPreferencesDBus.getInstance();

		String outputFolderProxies = null;
		String outputFolderStubs = null;
		String licenseHeader = null;
		String generateProxy = null;
		String generatStub = null;		

		IProject project = file.getProject();
		IResource resource = file;
		
		try {
			// Should project or file specific properties be used ?
			String useProject1 = project.getPersistentProperty(new QualifiedName(PreferenceConstants.PROJECT_PAGEID, PreferenceConstants.P_USEPROJECTSETTINGS));
			String useProject2 = file.getPersistentProperty(new QualifiedName(PreferenceConstants.PROJECT_PAGEID, PreferenceConstants.P_USEPROJECTSETTINGS));
			if("true".equals(useProject1) || "true".equals(useProject2)) {
				resource = project;
			} 
			outputFolderProxies = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsDBus.PROJECT_PAGEID, PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS));
			outputFolderStubs = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsDBus.PROJECT_PAGEID, PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS));
			licenseHeader = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsDBus.PROJECT_PAGEID, PreferenceConstantsDBus.P_LICENSE_DBUS));
			generateProxy = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsDBus.PROJECT_PAGEID, PreferenceConstantsDBus.P_GENERATEPROXY_DBUS));
			generatStub = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsDBus.PROJECT_PAGEID, PreferenceConstantsDBus.P_GENERATESTUB_DBUS));
		} catch (CoreException e1) {
			System.err.println("Failed to get property for " + resource.getName());
		}
		// Set defaults in the very first case, where nothing was specified from the user.
		if(outputFolderProxies == null) {
			outputFolderProxies = store.getString(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS);			
		}
		if(outputFolderStubs == null) {
			outputFolderStubs = store.getString(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS);	
		}
		if(licenseHeader == null) {
			licenseHeader = store.getString(PreferenceConstantsDBus.P_LICENSE_DBUS);			
		}
		if(generateProxy == null) {
			generateProxy = store.getString(PreferenceConstantsDBus.P_GENERATEPROXY_DBUS);	
		}
		if(generatStub == null) {
			generatStub = store.getString(PreferenceConstantsDBus.P_GENERATESTUB_DBUS);
		}
		// finally, store the properties for the code generator
		instance.setPreference(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, outputFolderProxies);
		instance.setPreference(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, outputFolderStubs);
		instance.setPreference(PreferenceConstantsDBus.P_LICENSE_DBUS, licenseHeader);
		instance.setPreference(PreferenceConstantsDBus.P_GENERATEPROXY_DBUS, generateProxy);
		instance.setPreference(PreferenceConstantsDBus.P_GENERATESTUB_DBUS, generatStub);
	}   

}
