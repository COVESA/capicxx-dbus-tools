/*
 * Copyright (C) 2013 BMW Group Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de) This Source Code Form is
 * subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the
 * MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

package org.genivi.commonapi.dbus.preferences;

import java.util.HashMap;
import java.util.Map;
import java.io.File;

import org.eclipse.xtext.generator.IFileSystemAccess;
import org.eclipse.xtext.generator.OutputConfiguration;
import org.franca.core.franca.FModel;
import org.genivi.commonapi.core.preferences.PreferenceConstants;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;

public class FPreferencesDBus {

	   private static FPreferencesDBus instance = null;
	    private Map<String, String> preferences = null;

	    public Map<String, String> getPreferences() {
			return preferences;
		}

		private FPreferencesDBus() {
	        preferences = new HashMap<String, String>();
	        clidefPreferences();
	    }

	    public void resetPreferences(){
	        preferences.clear();
	    }

	    public static FPreferencesDBus getInstance() {
	        if (instance == null) {
	            instance = new FPreferencesDBus();
	        }
	        return instance;
	    }

	    private void clidefPreferences(){

	        if (!preferences.containsKey(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS, PreferenceConstantsDBus.DEFAULT_OUTPUT);
	        }    	
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, PreferenceConstantsDBus.DEFAULT_OUTPUT);
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, PreferenceConstantsDBus.DEFAULT_OUTPUT);
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_OUTPUT_DEFAULT_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_OUTPUT_DEFAULT_DBUS, PreferenceConstants.DEFAULT_OUTPUT);
	        }    
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_OUTPUT_SUBDIRS_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_OUTPUT_SUBDIRS_DBUS, "false");
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_LICENSE_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_LICENSE_DBUS, PreferenceConstantsDBus.DEFAULT_LICENSE);
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_COMMON_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_COMMON_DBUS, "true");
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_STUB_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_STUB_DBUS, "true");
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_PROXY_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_PROXY_DBUS, "true");
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_LOGOUTPUT_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_LOGOUTPUT_DBUS, "true");
	        }	        
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_CODE_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_CODE_DBUS, "true");    
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_DEPENDENCIES_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_DEPENDENCIES_DBUS, "true");    
	        }
	        if (!preferences.containsKey(PreferenceConstantsDBus.P_GENERATE_SYNC_CALLS_DBUS)) {
	            preferences.put(PreferenceConstantsDBus.P_GENERATE_SYNC_CALLS_DBUS, "true");    
	        }
	    }

	    public String getPreference(String preferencename, String defaultValue) {
	    	
	    	if (preferences.containsKey(preferencename)) {
	    		return preferences.get(preferencename);
	    	}
	    	System.err.println("Unknown preference " + preferencename);
	        return "";
	    }

	    public void setPreference(String name, String value) {
	        if(preferences != null) {
	        	preferences.put(name, value);
	        }
	    }

	    public String getModelPath(FModel model) {
	        String ret = model.eResource().getURI().toString();
	        return ret;
	    }
	    
	    /**
	     * Set the output path configurations (based on stored the preference values) for file system access types 
	     * (instance of AbstractFileSystemAccess)
	     * @return
	     */
	    public HashMap<String, OutputConfiguration> getOutputpathConfiguration() {
	        return getOutputpathConfiguration(null);
	    }

	    /**
	     * Set the output path configurations (based on stored the preference values) for file system access types
	     * (instance of AbstractFileSystemAccess)
			 * @subdir the subdir to use, can be null
	     * @return
	     */
	    public HashMap<String, OutputConfiguration> getOutputpathConfiguration(String subdir) {

	        String defaultDir = getPreference(PreferenceConstantsDBus.P_OUTPUT_DEFAULT_DBUS, PreferenceConstants.DEFAULT_OUTPUT);
	        String commonDir = getPreference(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS, defaultDir);
	        String outputProxyDir = getPreference(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, defaultDir);
	        String outputStubDir = getPreference(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, defaultDir);

	        if (null != subdir && getPreference(PreferenceConstants.P_OUTPUT_SUBDIRS, "false").equals("true")) {
	            defaultDir = new File(defaultDir, subdir).getPath();
	            commonDir = new File(commonDir, subdir).getPath();
	            outputProxyDir = new File(outputProxyDir, subdir).getPath();
	            outputStubDir = new File(outputStubDir, subdir).getPath();
	        }

	        HashMap<String, OutputConfiguration>  outputs = new HashMap<String, OutputConfiguration> ();
	        
	        OutputConfiguration commonOutput = new OutputConfiguration(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS);
	        commonOutput.setDescription("Common Output Folder");
	        commonOutput.setOutputDirectory(commonDir);
	        commonOutput.setCreateOutputDirectory(true);
	        outputs.put(IFileSystemAccess.DEFAULT_OUTPUT, commonOutput);
	        
	        OutputConfiguration proxyOutput = new OutputConfiguration(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS);
	        proxyOutput.setDescription("Proxy Output Folder");
	        proxyOutput.setOutputDirectory(outputProxyDir);
	        proxyOutput.setCreateOutputDirectory(true);
	        outputs.put(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, proxyOutput);
	        
	        OutputConfiguration stubOutput = new OutputConfiguration(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS);
	        stubOutput.setDescription("Stub Output Folder");
	        stubOutput.setOutputDirectory(outputStubDir);
	        stubOutput.setCreateOutputDirectory(true);
	        outputs.put(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, stubOutput);
	        
	        return outputs;
	    }

}
