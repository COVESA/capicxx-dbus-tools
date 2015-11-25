package org.genivi.commonapi.dbus.preferences;

public interface PreferenceConstantsDBus
{
    public static final String SCOPE                 	= "org.genivi.commonapi.dbus.ui";
    public static final String PROJECT_PAGEID        	= "org.genivi.commonapi.dbus.ui.preferences.CommonAPIDBusPreferencePage";

    // preference keys
    public static final String P_LICENSE_DBUS        	= "licenseHeader";
    public static final String P_OUTPUT_PROXIES_DBUS 	= "outputDirProxiesDBus";
    public static final String P_OUTPUT_STUBS_DBUS   	= "outputDirStubsDBus";
	public static final String P_OUTPUT_COMMON_DBUS     = "outputDirCommon";
	public static final String P_OUTPUT_DEFAULT_DBUS	= "outputDirDefault";
    public static final String P_GENERATE_COMMON_DBUS	= "generatecommon";
    public static final String P_GENERATE_PROXY_DBUS	= "generateproxy";
    public static final String P_GENERATE_STUB_DBUS     = "generatestub";
	public static final String P_LOGOUTPUT_DBUS        	= "logoutput";
	public static final String P_USEPROJECTSETTINGS_DBUS= "useProjectSettings";
	public static final String P_GENERATE_CODE_DBUS     = "generateCode";
	public static final String P_GENERATE_DEPENDENCIES_DBUS = "generateDependencies";
	public static final String P_GENERATE_SYNC_CALLS_DBUS = "generateSyncCalls";
	public static final String P_ENABLE_DBUS_VALIDATOR  = "enableDBusValidator";
	// preference values
    public static final String DEFAULT_OUTPUT     		= "./src-gen/";
	public static final String LOGLEVEL_QUIET     		= "quiet";
	public static final String LOGLEVEL_VERBOSE   		= "verbose";
    public static final String DEFAULT_LICENSE    		= "This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.\n"
            + "If a copy of the MPL was not distributed with this file, You can obtain one at\n"
            + "http://mozilla.org/MPL/2.0/.";
	public static final String NO_CODE                  = "";

}
