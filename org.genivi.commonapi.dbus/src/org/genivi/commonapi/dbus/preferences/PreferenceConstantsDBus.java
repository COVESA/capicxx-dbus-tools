package org.genivi.commonapi.dbus.preferences;

public interface PreferenceConstantsDBus 
{
    public static final String SCOPE                 	= "org.genivi.commonapi.dbus.ui";
    public static final String PROJECT_PAGEID        	= "org.genivi.commonapi.dbus.ui.preferences.CommonAPIDBusPreferencePage";
	
    // preference keys
    public static final String P_LICENSE_DBUS        	= "licenseHeader";
    public static final String P_OUTPUT_PROXIES_DBUS 	= "outputDirProxiesDBus";
    public static final String P_OUTPUT_STUBS_DBUS   	= "outputDirStubsDBus";
	public static final String P_OUTPUT_DEFAULT_DBUS	= "outputDirDefault";
    public static final String P_GENERATEPROXY_DBUS		= "generateproxy";
    public static final String P_GENERATESTUB_DBUS     	= "generatestub";
	public static final String P_LOGOUTPUT_DBUS        	= "logoutput";
	
	// preference values
    public static final String DEFAULT_OUTPUT     		= "./src-gen/";
	public static final String LOGLEVEL_QUIET     		= "quiet";
	public static final String LOGLEVEL_VERBOSE   		= "verbose";
    public static final String DEFAULT_LICENSE    		= "This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.\n"
            + "If a copy of the MPL was not distributed with this file, You can obtain one at\n"
            + "http://mozilla.org/MPL/2.0/.";
	
}
