/* Copyright (C) 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.deployment;

import org.franca.core.franca.FInterface;
import org.franca.deploymodel.core.FDeployedInterface;
import org.franca.deploymodel.core.FDeployedProvider;
import org.franca.deploymodel.core.FDeployedTypeCollection;
import org.genivi.commonapi.dbus.DeploymentInterfacePropertyAccessor;
import org.genivi.commonapi.dbus.DeploymentInterfacePropertyAccessor.DBusDefaultAttributeType;
import org.genivi.commonapi.dbus.DeploymentProviderPropertyAccessor;
import org.genivi.commonapi.dbus.DeploymentTypeCollectionPropertyAccessor;

public class PropertyAccessor extends org.genivi.commonapi.core.deployment.PropertyAccessor {
	
	DeploymentInterfacePropertyAccessor dbusInterface_;
	DeploymentTypeCollectionPropertyAccessor dbusTypeCollection_;
	DeploymentProviderPropertyAccessor dbusProvider_;
	
	public enum PropertiesType {
		CommonAPI, freedesktop
	}
	
	public PropertyAccessor() {
		super();
		dbusInterface_ = null;
		dbusTypeCollection_ = null;
		dbusProvider_ = null;
	}
	
	public PropertyAccessor(FDeployedInterface _target) {
		super(_target);
		dbusInterface_ = new DeploymentInterfacePropertyAccessor(_target);
		dbusTypeCollection_ = null;
		dbusProvider_ = null;
	}

	public PropertyAccessor(FDeployedTypeCollection _target) {
		super(_target);
		dbusInterface_ = null;
		dbusTypeCollection_ = new DeploymentTypeCollectionPropertyAccessor(_target);
		dbusProvider_ = null;
	}

	public PropertyAccessor(FDeployedProvider _target) {
		super(_target);
		dbusInterface_ = null;
		dbusTypeCollection_ = null;
		dbusProvider_ = new DeploymentProviderPropertyAccessor(_target);
	}

	public PropertiesType getPropertiesType (FInterface obj) {
		if (type_ == DeploymentType.INTERFACE) {
			return from(dbusInterface_.getDBusDefaultAttributeType(obj));
		}
		return PropertiesType.CommonAPI; // LB: maybe we should throw an exception here...
	}
	
	private PropertiesType from(DBusDefaultAttributeType _source) {
		if (_source != null) {
			switch (_source) {
			case freedesktop:
				return PropertiesType.freedesktop;
			default:
				return PropertiesType.CommonAPI;
			}
		} 
		return PropertiesType.CommonAPI;
	}
}
