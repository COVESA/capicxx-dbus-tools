/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.validator;

import org.franca.core.franca.FModel;
import org.genivi.commonapi.dbus.verification.ValidatorDBus;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;
import org.genivi.commonapi.dbus.ui.CommonApiDBusUiPlugin;
import org.genivi.commonapi.dbus.validator.preference.ValidatorDBusPreferencesPage;

/**
 * This validator is automatically triggered from the XText editor.
 */
public class ValidatorDBusUi extends ValidatorDBus {

    @Override
    public void validateModel(FModel model,
            ValidationMessageAcceptor messageAcceptor) {
        if (!isValidatorEnabled()) {
            return;
        }
        super.validateModel(model, messageAcceptor);
    }


	@Override
    protected boolean isWholeWorkspaceCheckActive() {

    	IPreferenceStore prefs = CommonApiDBusUiPlugin.getValidatorPreferences();
    	return prefs != null && prefs.getBoolean(ValidatorDBusPreferencesPage.ENABLED_WORKSPACE_CHECK);
    }

    /**
     * Check whether the validation is enabled in the eclipse preferences
     * @return
     */
	@Override
    public boolean isValidatorEnabled() {

    	IPreferenceStore prefs = CommonApiDBusUiPlugin.getValidatorPreferences();
    	return prefs != null && prefs.getBoolean(PreferenceConstantsDBus.P_ENABLE_DBUS_VALIDATOR);
    }
}
