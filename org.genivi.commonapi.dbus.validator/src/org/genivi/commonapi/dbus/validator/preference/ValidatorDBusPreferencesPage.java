/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.validator.preference;

import org.eclipse.jface.preference.BooleanFieldEditor;
import org.eclipse.jface.preference.FieldEditorPreferencePage;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;
import org.genivi.commonapi.dbus.ui.CommonApiDBusUiPlugin;

public class ValidatorDBusPreferencesPage extends FieldEditorPreferencePage
        implements IWorkbenchPreferencePage {

    public final static String ENABLED_WORKSPACE_CHECK = "ENABLED_WORKSPACE_CHECK";

    @Override
    public void checkState() {
        super.checkState();
    }

    @Override
    public void createFieldEditors() {
        addField(new BooleanFieldEditor(PreferenceConstantsDBus.P_ENABLE_DBUS_VALIDATOR,
                "Enable CommonAPI D-Bus specific validation of Franca IDL files", getFieldEditorParent()));
        addField(new BooleanFieldEditor(
                ENABLED_WORKSPACE_CHECK,
                "Enable whole workspace check",
                getFieldEditorParent()));
    }

    @Override
    public void init(IWorkbench workbench) {
        IPreferenceStore prefStore = CommonApiDBusUiPlugin.getValidatorPreferences();
        setPreferenceStore(prefStore);
    }

}
