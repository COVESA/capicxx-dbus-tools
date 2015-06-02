/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.dbus.validator.preference;

import org.eclipse.jface.preference.BooleanFieldEditor;
import org.eclipse.jface.preference.FieldEditorPreferencePage;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.genivi.commonapi.dbus.ui.CommonApiDBusUiPlugin;

public class ValidatorDBusPreferencesPage extends FieldEditorPreferencePage
        implements IWorkbenchPreferencePage {

    public final static String ENABLED_DBUS_VALIDATOR = "ENABLED_DBUS_VALIDATOR";
    public final static String ENABLED_WORKSPACE_CHECK = "ENABLED_WORKSPACE_CHECK";

    @Override
    public void checkState() {
        super.checkState();
    }

    @Override
    public void createFieldEditors() {
        addField(new BooleanFieldEditor(ENABLED_DBUS_VALIDATOR,
                "validator enabled", getFieldEditorParent()));
        addField(new BooleanFieldEditor(
                ENABLED_WORKSPACE_CHECK,
                "enable the whole workspace check (Note: Validations takes up to two minutes if enabled)",
                getFieldEditorParent()));
    }

    @Override
    public void init(IWorkbench workbench) {
        IPreferenceStore prefStore = CommonApiDBusUiPlugin.getDefault()
                .getPreferenceStore();
        setPreferenceStore(prefStore);
        setDescription("Disable or enable the dbus validator!");
        prefStore.setDefault(
                ValidatorDBusPreferencesPage.ENABLED_DBUS_VALIDATOR, true);

    }

}
