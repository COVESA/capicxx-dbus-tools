package org.genivi.commonapi.dbus.preferences;

import org.genivi.commonapi.core.preferences.PreferenceConstants;

public interface PreferenceConstantsDBus extends PreferenceConstants
{
    public static final String SCOPE                 	= "org.genivi.commonapi.dbus.ui";
    public static final String PROJECT_PAGEID        	= "org.genivi.commonapi.dbus.ui.preferences.CommonAPIDBusPreferencePage";

    // preference keys
    public static final String P_LICENSE_DBUS        	= P_LICENSE;
    public static final String P_OUTPUT_PROXIES_DBUS 	= P_OUTPUT_PROXIES;
    public static final String P_OUTPUT_STUBS_DBUS   	= P_OUTPUT_STUBS;
	public static final String P_OUTPUT_COMMON_DBUS     = P_OUTPUT_COMMON;
	public static final String P_OUTPUT_DEFAULT_DBUS	= P_OUTPUT_DEFAULT;
	public static final String P_OUTPUT_SUBDIRS_DBUS	= P_OUTPUT_SUBDIRS;
    public static final String P_GENERATE_COMMON_DBUS	= P_GENERATE_COMMON;
    public static final String P_GENERATE_PROXY_DBUS	= P_GENERATE_PROXY;
    public static final String P_GENERATE_STUB_DBUS     = P_GENERATE_STUB;
	public static final String P_LOGOUTPUT_DBUS        	= P_LOGOUTPUT;
	public static final String P_USEPROJECTSETTINGS_DBUS= P_USEPROJECTSETTINGS;
	public static final String P_GENERATE_CODE_DBUS     = P_GENERATE_CODE;
	public static final String P_GENERATE_DEPENDENCIES_DBUS = P_GENERATE_DEPENDENCIES;
	public static final String P_GENERATE_SYNC_CALLS_DBUS = P_GENERATE_SYNC_CALLS;
	public static final String P_ENABLE_DBUS_VALIDATOR  = "enableDBusValidator";
}
