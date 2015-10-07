/* Copyright (C) 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.deployment;

import org.eclipse.emf.ecore.EObject;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FAttribute;
import org.franca.core.franca.FField;
import org.franca.core.franca.FInterface;
import org.franca.deploymodel.core.FDeployedInterface;
import org.franca.deploymodel.core.FDeployedProvider;
import org.franca.deploymodel.core.FDeployedTypeCollection;
import org.franca.deploymodel.dsl.fDeploy.FDInterfaceInstance;
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
	
	public enum DBusVariantType {
		DBus, CommonAPI
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
			try {
				return from(dbusInterface_.getDBusDefaultAttributeType(obj));
			} catch (NullPointerException npe) {
				//System.err.println("Failed to get DBusDefaultAttributeType from " + obj.getName());
			}
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
	
	
	public Boolean getIsObjectPath (EObject obj) {
		Boolean isObjectPath = false;
		try {
			if (type_ == DeploymentType.INTERFACE)
				isObjectPath = dbusInterface_.getIsObjectPath(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				isObjectPath = dbusTypeCollection_.getIsObjectPath(obj);
		}
		catch (java.lang.NullPointerException e) {}
                if (isObjectPath == null) isObjectPath = false;
		return isObjectPath;
	}
	public DBusVariantType getDBusVariantType (EObject obj) {
		DBusVariantType variantType = DBusVariantType.CommonAPI;
		try {
			if (type_ == DeploymentType.INTERFACE)
				variantType = from(dbusInterface_.getDBusVariantType(obj));
			else if (type_ == DeploymentType.TYPE_COLLECTION)
				variantType = from(dbusTypeCollection_.getDBusVariantType(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return variantType;
	}
		
	private DBusVariantType from(DeploymentInterfacePropertyAccessor.DBusVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentTypeCollectionPropertyAccessor.DBusVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentInterfacePropertyAccessor.DBusAttrVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentInterfacePropertyAccessor.DBusArgVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentInterfacePropertyAccessor.DBusStructVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentTypeCollectionPropertyAccessor.DBusStructVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentInterfacePropertyAccessor.DBusUnionVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	private DBusVariantType from(DeploymentTypeCollectionPropertyAccessor.DBusUnionVariantType type)
	{
		if (type != null) {
			switch(type) {
			case CommonAPI:
				return DBusVariantType.CommonAPI;
			case DBus:
				return DBusVariantType.DBus;
			}
		}
		return DBusVariantType.CommonAPI;
	}
	public DBusVariantType getDBusAttrVariantType (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return from(dbusInterface_.getDBusAttrVariantType(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	public DBusVariantType getDBusArgVariantType (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return from(dbusInterface_.getDBusArgVariantType(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}	
	public DBusVariantType getDBusStructVariantType (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return from(dbusInterface_.getDBusStructVariantType(obj));
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return from(dbusTypeCollection_.getDBusStructVariantType(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public DBusVariantType getDBusUnionVariantType (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return from(dbusInterface_.getDBusUnionVariantType(obj));
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return from(dbusTypeCollection_.getDBusUnionVariantType(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusInterfaceName (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusInterfaceName(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusObjectPath (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusObjectPath(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusServiceName (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusServiceName(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDbusDomain (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDomain(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusInstanceId (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getInstanceId(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
}
