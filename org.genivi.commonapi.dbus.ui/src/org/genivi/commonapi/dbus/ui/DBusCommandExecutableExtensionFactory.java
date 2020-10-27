/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.ui;

import org.eclipse.xtext.generator.IGenerator;
import org.genivi.commonapi.core.ui.CommandExecutableExtensionFactory;
import org.genivi.commonapi.dbus.generator.FrancaDBusGenerator;
import org.osgi.framework.Bundle;

import com.google.inject.Binder;

public class DBusCommandExecutableExtensionFactory extends CommandExecutableExtensionFactory {
	@Override
	protected Bundle getBundle() {
		return CommonApiDBusUiPlugin.getInstance().getBundle();
	}

	@Override
	protected void bindGeneratorClass(Binder binder) {
		binder.bind(IGenerator.class).to(FrancaDBusGenerator.class);
	}
}
