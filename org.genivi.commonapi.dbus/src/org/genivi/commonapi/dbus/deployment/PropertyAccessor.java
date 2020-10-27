/* Copyright (C) 2015-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.deployment;

import org.eclipse.emf.ecore.EObject;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FArrayType;
import org.franca.core.franca.FAttribute;
import org.franca.core.franca.FBroadcast;
import org.franca.core.franca.FField;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMethod;
import org.franca.core.franca.FStructType;
import org.franca.core.franca.FUnionType;
import org.franca.deploymodel.core.FDeployedInterface;
import org.franca.deploymodel.ext.providers.FDeployedProvider;
import org.franca.deploymodel.core.FDeployedTypeCollection;
import org.franca.deploymodel.dsl.fDeploy.FDExtensionElement;
import org.genivi.commonapi.dbus.Deployment;

public class PropertyAccessor extends org.genivi.commonapi.core.deployment.PropertyAccessor {
	
	Deployment.IDataPropertyAccessor dbusDataAccessor_;
	Deployment.ProviderPropertyAccessor dbusProvider_;

	PropertyAccessor parent_;
	String name_;
	
	public enum PropertiesType {
		CommonAPI, freedesktop
	}
	
	public enum DBusVariantType {
		DBus, CommonAPI
	}	
	public PropertyAccessor() {
		super();
		dbusDataAccessor_ = null;
		dbusProvider_ = null;
		parent_ = null;
		name_ = null;
	}
	
	public PropertyAccessor(FDeployedInterface _target) {
		super(_target);
		dbusDataAccessor_ = new Deployment.InterfacePropertyAccessor(_target);
		dbusProvider_ = null;
		parent_ = null;
		name_ = null;
	}

	public PropertyAccessor(FDeployedTypeCollection _target) {
		super(_target);
		dbusDataAccessor_ = new Deployment.TypeCollectionPropertyAccessor(_target);
		dbusProvider_ = null;
		parent_ = null;
		name_ = null;
	}

	public PropertyAccessor(FDeployedProvider _target) {
		super(_target);
		dbusProvider_ = new Deployment.ProviderPropertyAccessor(_target);
		parent_ = null;
		dbusDataAccessor_ = null;
		name_ = null;
	}
	public PropertyAccessor(PropertyAccessor _parent, FField _element) {
		super();
		dbusProvider_ = null;
		if (_parent.type_ != DeploymentType.PROVIDER && _parent != null && _parent.dbusDataAccessor_ != null) {
			dbusDataAccessor_ = _parent.dbusDataAccessor_.getOverwriteAccessor(_element);
			type_ = DeploymentType.OVERWRITE;
		}
		else
			dbusDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}
	public PropertyAccessor(PropertyAccessor _parent, FArrayType _element) {
		super();
		dbusProvider_ = null;
		if (_parent.type_ != DeploymentType.PROVIDER && _parent != null && _parent.dbusDataAccessor_ != null) {
			dbusDataAccessor_ = _parent.dbusDataAccessor_.getOverwriteAccessor(_element);
			type_ = DeploymentType.OVERWRITE;
		}
		else
			dbusDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}
	public PropertyAccessor(PropertyAccessor _parent, FArgument _element) {
		type_ = DeploymentType.OVERWRITE;
		dbusProvider_ = null;
		if (_parent.type_ == DeploymentType.INTERFACE) {
			Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) _parent.dbusDataAccessor_;
			dbusDataAccessor_ = ipa.getOverwriteAccessor(_element);
		}
		else
			dbusDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}
	public PropertyAccessor(PropertyAccessor _parent, FAttribute _element) {
		type_ = DeploymentType.OVERWRITE;
		dbusProvider_ = null;
		if (_parent.type_ == DeploymentType.INTERFACE) {
			Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) _parent.dbusDataAccessor_;
			dbusDataAccessor_ = ipa.getOverwriteAccessor(_element);
		}
		else
			dbusDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}
	public String getName() {
		if (name_ == null)
			return "";
		return name_;
	}
	private void setName(FField _element) {
		String containername = "";
		if (_element.eContainer() instanceof FStructType)
			containername = ((FStructType)(_element.eContainer())).getName() + "_";
		if (_element.eContainer() instanceof FUnionType)
			containername = ((FUnionType)(_element.eContainer())).getName() + "_";
		String parentname = parent_.name_;
		if (parentname != null) {
			name_ = parentname + containername + _element.getName() + "_";
		}
		else
			name_ = containername + _element.getName() + "_";
		return;
	}
	private void setName(FArgument _element) {
		if (_element.eContainer() instanceof FMethod)
			name_ = ((FMethod)(_element.eContainer())).getName() + "_" + _element.getName() + "_";
		if (_element.eContainer() instanceof FBroadcast)
			name_ = ((FBroadcast)(_element.eContainer())).getName() + "_" + _element.getName() + "_";
		return;
	}
	private void setName(FArrayType _element) {
		if (dbusDataAccessor_ != parent_.dbusDataAccessor_) {
			String parentname = parent_.getName();
			if (parentname != null) {
				name_ = parentname + _element.getName() + "_";
			}
			else
				name_ = _element.getName() + "_";
		}
		else {
			name_ = parent_.getName();
		}
		return;
	}

	private void setName(FAttribute _element) {
		name_ = _element.getName() + "_";
		return;
	}
	public PropertyAccessor getParent() {
		return parent_;
	}
	public PropertyAccessor getOverwriteAccessor(EObject _object) {
		if (_object instanceof FArgument)
			return new PropertyAccessor(this, (FArgument)_object);
		if (_object instanceof FAttribute)
			return new PropertyAccessor(this, (FAttribute)_object);
		if (_object instanceof FField)
			return new PropertyAccessor(this, (FField)_object);
		if (_object instanceof FArrayType)
			return new PropertyAccessor(this, (FArrayType)_object);
		return null;
	}
	public boolean isProperOverwrite() {
		// is proper overwrite if we are overwrite and none of my parents is the same accessor
		return (type_ == DeploymentType.OVERWRITE && !hasSameAccessor(dbusDataAccessor_));
	}
	protected boolean hasSameAccessor(Deployment.IDataPropertyAccessor _accessor)
	{
		if (parent_ == null)
			return false;
		if (parent_.dbusDataAccessor_ == _accessor)
			return true;
		return parent_.hasSameAccessor(_accessor);
	}
	public PropertiesType getPropertiesType (FInterface obj) {
		if (type_ == DeploymentType.INTERFACE) {
			try {
				return from(((Deployment.InterfacePropertyAccessor)dbusDataAccessor_).getDBusDefaultAttributeType(obj));
			} catch (NullPointerException npe) {
				//System.err.println("Failed to get DBusDefaultAttributeType from " + obj.getName());
			}
		}
		return PropertiesType.CommonAPI; // LB: maybe we should throw an exception here...
	}
	
	private PropertiesType from(Deployment.Enums.DBusDefaultAttributeType _source) {
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
			if (type_ != DeploymentType.PROVIDER)
				isObjectPath = dbusDataAccessor_.getIsObjectPath(obj);
		}
		catch (java.lang.NullPointerException e) {}
                if (isObjectPath == null) isObjectPath = false;
		return isObjectPath;
	}
	public Boolean getIsUnixFD (EObject obj) {
		Boolean isUnixFD = false;
		try {
			if (type_ != DeploymentType.PROVIDER)
				isUnixFD = dbusDataAccessor_.getIsUnixFD(obj);
		}
		catch (java.lang.NullPointerException e) {}
            if (isUnixFD == null) isUnixFD = false;
		return isUnixFD;
	}	
	public DBusVariantType getDBusVariantType (FUnionType obj) {
		DBusVariantType variantType = DBusVariantType.CommonAPI;
		try {
			if (type_ != DeploymentType.PROVIDER)
				variantType = from(dbusDataAccessor_.getDBusVariantType(obj));
	}
		catch (java.lang.NullPointerException e) {}
		return variantType;
	}
		
	private DBusVariantType from(Deployment.Enums.DBusVariantType type)
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

	public String getDBusInterfaceName (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusInterfaceName(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusObjectPath (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusObjectPath(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusServiceName (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDBusServiceName(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDbusDomain (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getDomain(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getDBusInstanceId (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return dbusProvider_.getInstanceId(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getDBusPredefined (FDExtensionElement obj) {
		Boolean isDBusPredefined = false;
		try {
			if (type_ == DeploymentType.PROVIDER)
				isDBusPredefined = dbusProvider_.getDBusPredefined(obj);
		}
		catch (java.lang.NullPointerException e) {}
			if (isDBusPredefined == null) isDBusPredefined = false;
		return isDBusPredefined;
	}

	public static void BroadcastType() {
	  throw new UnsupportedOperationException("TODO: auto-generated method stub");
	}
	
}
