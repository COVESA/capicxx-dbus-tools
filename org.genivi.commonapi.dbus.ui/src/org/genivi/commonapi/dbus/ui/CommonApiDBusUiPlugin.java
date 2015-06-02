/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.ui;

import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.osgi.framework.BundleContext;

public class CommonApiDBusUiPlugin extends AbstractUIPlugin
{
    public static final String           PLUGIN_ID = "org.genivi.commonapi.dbus.ui"; //$NON-NLS-1$

    private static CommonApiDBusUiPlugin INSTANCE;

    public CommonApiDBusUiPlugin()
    {
    }

    @Override
    public void start(final BundleContext context) throws Exception
    {
        super.start(context);
        INSTANCE = this;
    }

    @Override
    public void stop(final BundleContext context) throws Exception
    {
        INSTANCE = null;
        super.stop(context);
    }

    public static CommonApiDBusUiPlugin getInstance()
    {
        return INSTANCE;
    }

    public static CommonApiDBusUiPlugin getDefault()
    {
        return INSTANCE;
    }
    
	public static IPreferenceStore getValidatorPreferences() {
		return INSTANCE.getPreferenceStore();
	}
}
