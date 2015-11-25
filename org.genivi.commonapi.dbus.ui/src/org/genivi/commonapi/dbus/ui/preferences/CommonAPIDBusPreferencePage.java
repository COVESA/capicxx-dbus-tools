/*
 * Copyright (C) 2013 BMW Group Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de) This Source Code Form is
 * subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the
 * MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

package org.genivi.commonapi.dbus.ui.preferences;

import org.eclipse.core.runtime.preferences.DefaultScope;
import org.eclipse.jface.preference.FieldEditor;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.jface.preference.StringFieldEditor;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.genivi.commonapi.core.ui.preferences.FieldEditorOverlayPage;
import org.genivi.commonapi.core.ui.preferences.MultiLineStringFieldEditor;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;
import org.genivi.commonapi.dbus.ui.CommonApiDBusUiPlugin;

/**
 * This class represents a preference page that is contributed to the
 * Preferences dialog. By subclassing <samp>FieldEditorOverlayPage</samp>..
 * <p>
 * This page is used to modify preferences. They are stored in the preference store that
 * belongs to the main plug-in class.
 */

public class CommonAPIDBusPreferencePage extends FieldEditorOverlayPage implements IWorkbenchPreferencePage
{
    private FieldEditor license     = null;
    private FieldEditor proxyOutput = null;
    private FieldEditor stubOutput  = null;
    private FieldEditor commonOutput  = null;


    public CommonAPIDBusPreferencePage()
    {
        super(GRID);
        setDescription("Preferences for CommonAPI-DBus");
    }

    /**
     * Creates the field editors. Field editors are abstractions of the common
     * GUI blocks needed to manipulate various types of preferences. Each field
     * editor knows how to save and restore itself.
     */
    @Override
    public void createFieldEditors()
    {
        license = new MultiLineStringFieldEditor(PreferenceConstantsDBus.P_LICENSE_DBUS, "The header to insert for all generated files", 60,
                getFieldEditorParent());
        license.setLabelText(""); // need to set this parameter (seems to be a bug)
        addField(license);
        // output directory definitions
        commonOutput = new StringFieldEditor(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS, "Output directory for the common part", 30,
        		getFieldEditorParent());
        addField(commonOutput);
        proxyOutput = new StringFieldEditor(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS, "Output directory for proxies inside project",
                30, getFieldEditorParent());
        addField(proxyOutput);
        stubOutput = new StringFieldEditor(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS, "Output directory for stubs inside project", 30,
                getFieldEditorParent());
        addField(stubOutput);

    }

    @Override
    protected void performDefaults()
    {
        DefaultScope.INSTANCE.getNode(PreferenceConstantsDBus.SCOPE).put(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS,
                PreferenceConstantsDBus.DEFAULT_OUTPUT);
        DefaultScope.INSTANCE.getNode(PreferenceConstantsDBus.SCOPE).put(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS,
                PreferenceConstantsDBus.DEFAULT_OUTPUT);
        DefaultScope.INSTANCE.getNode(PreferenceConstantsDBus.SCOPE).put(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS,
                PreferenceConstantsDBus.DEFAULT_OUTPUT);

        super.performDefaults();
    }

    @Override
    public void init(IWorkbench workbench)
    {
        if (!isPropertyPage())
            setPreferenceStore(CommonApiDBusUiPlugin.getDefault().getPreferenceStore());
    }

    @Override
    protected String getPageId()
    {
        return PreferenceConstantsDBus.PROJECT_PAGEID;
    }

    @Override
    protected IPreferenceStore doGetPreferenceStore()
    {
        return CommonApiDBusUiPlugin.getDefault().getPreferenceStore();
    }

    @Override
    public boolean performOk()
    {
        boolean result = super.performOk();

        return result;
    }

}
