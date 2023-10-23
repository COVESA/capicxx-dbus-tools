/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.cli;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.runtime.Platform;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.validation.AbstractValidationMessageAcceptor;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.franca.core.dsl.FrancaIDLRuntimeModule;
import org.franca.core.franca.FModel;
import org.franca.deploymodel.dsl.fDeploy.FDModel;
import org.genivi.commonapi.console.CommandlineTool;
import org.genivi.commonapi.console.ConsoleLogger;
import org.genivi.commonapi.core.generator.GeneratorFileSystemAccess;
import org.genivi.commonapi.core.verification.CommandlineValidator;
import org.genivi.commonapi.core.verification.ValidateElements;
import org.genivi.commonapi.core.verification.ValidatorCore;
import org.genivi.commonapi.dbus.generator.FrancaDBusGenerator;
import org.genivi.commonapi.dbus.preferences.FPreferencesDBus;
import org.genivi.commonapi.dbus.preferences.PreferenceConstantsDBus;

import com.google.inject.Guice;
import com.google.inject.Injector;

/**
 * Receive command line arguments and set them as preference values for the code
 * generation.
 */
public class DBusCommandlineToolMain extends CommandlineTool {
	protected FPreferencesDBus dbusPref;
	protected GeneratorFileSystemAccess fsa;
	protected Injector injector;
	protected IGenerator francaGenerator;
	protected String SCOPE = "DBus validation: ";
	private ValidateElements validateElements = new ValidateElements();

	private ValidationMessageAcceptor cliMessageAcceptor = new AbstractValidationMessageAcceptor() {

		@Override
		public void acceptInfo(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
			ConsoleLogger.printLog(SCOPE + message);
		}

		@Override
		public void acceptWarning(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
			ConsoleLogger.printLog("Warning: " + SCOPE + message);
		}

		@Override
		public void acceptError(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
			hasValidationError = true;
			ConsoleLogger.printErrorLog("Error: " + SCOPE + message);
		}
	};

	/**
	 * The constructor registers the needed bindings to use the generator
	 */
	public DBusCommandlineToolMain() {

		injector = Guice.createInjector(new FrancaIDLRuntimeModule());

		fsa = injector.getInstance(GeneratorFileSystemAccess.class);

		dbusPref = FPreferencesDBus.getInstance();

	}

	public int generateDBus(List<String> fileList) {
		francaGenerator = injector.getInstance(FrancaDBusGenerator.class);

		return doGenerate(fileList);
	}

	protected String normalize(String _path) {
		File itsFile = new File(_path);
		return itsFile.getAbsolutePath();
	}

	/**
	 * Call the franca generator for the specified list of files.
	 *
	 * @param fileList
	 *            the list of files to generate code from
	 */
	protected int doGenerate(List<String> _fileList) {
		fsa.setOutputConfigurations(FPreferencesDBus.getInstance()
				.getOutputpathConfiguration());

		XtextResourceSet rsset = injector.getProvider(XtextResourceSet.class)
				.get();

		int error_state = NO_ERROR_STATE;
		ConsoleLogger.printLog("Using Franca Version " + getFrancaVersion());

		// Create absolute paths
		List<String> fileList = new ArrayList<String>();
		for (String path : _fileList) {
			String absolutePath = normalize(path);
			fileList.add(absolutePath);
		}

		for (String file : fileList) {
			URI uri = URI.createFileURI(file);
			Resource resource = null;
			try {
				resource = rsset.createResource(uri);
			} catch (IllegalStateException ise) {
				ConsoleLogger.printErrorLog("Failed to create a resource from "
						+ file + "\n" + ise.getMessage());
				error_state = ERROR_STATE;
				continue;
			}
			hasValidationError = false;
			if (isValidation) {
				validateDBus(resource);
			}
			if (!hasValidationError) {
				ConsoleLogger.printLog("Generating code for " + file);
				try {
					if (FPreferencesDBus.getInstance().getPreference(
							PreferenceConstantsDBus.P_OUTPUT_SUBDIRS_DBUS, "false").equals("true")) {
						String subdir = (new File(file)).getName();
						subdir = subdir.replace(".fidl", "");
						subdir = subdir.replace(".fdepl", "");
						fsa.setOutputConfigurations(FPreferencesDBus.getInstance()
							.getOutputpathConfiguration(subdir));
					}
					francaGenerator.doGenerate(resource, fsa);
				} catch (Exception e) {
					ConsoleLogger
							.printErrorLog("Failed to generate dbus code: "
									+ e.getMessage());
					error_state = ERROR_STATE;
				}
			} else {
				error_state = ERROR_STATE;
			}
			if (resource != null) {
				// Clear each resource from the resource set in order to let
				// other fidl files import it.
				// Otherwise an IllegalStateException will be thrown for a
				// resource that was already created.
				resource.unload();
				rsset.getResources().clear();
			}
		}
		if (dumpGeneratedFiles) {
			fsa.dumpGeneratedFiles();
		}
		fsa.clearFileList();
		dumpGeneratedFiles = false;
		return error_state;
	}

	/**
	 * Validate the fidl/fdepl file resource
	 *
	 * @param resource
	 */
	public void validateDBus(Resource resource) {
		EObject model = null;
		CommandLineValidatorDBus cliValidator = new CommandLineValidatorDBus(
				cliMessageAcceptor);

		//ConsoleLogger.printLog("validating " + resource.getURI().lastSegment());

		model = cliValidator.loadResource(resource);

		if (model != null) {
			if (model instanceof FDModel) {
				validateElements.verifyEqualInOutAndAddSuffix((FDModel) model);

				// check existence of imported fidl/fdepl files
				cliValidator.validateImports((FDModel) model, resource.getURI());

				// perform DBus specific deployment validation
				cliValidator.validateDeployment(resource.getURI());
			}
			// check existence of imported fidl/fdepl files
			if (model instanceof FModel) {
				validateElements.verifyEqualInOutAndAddSuffix((FModel) model);

				cliValidator.validateImports((FModel) model, resource.getURI());

				// validate against GENIVI rules
				ValidatorCore validator = new ValidatorCore();
				try {
					validator.validateModel((FModel) model, cliMessageAcceptor);
				} catch (Exception e) {
					ConsoleLogger.printErrorLog(e.getMessage());
					hasValidationError = true;
					return;
				}
			}
			// XText validation
			cliValidator.validateResourceWithImports(resource);
		} else {
			// model is null, no resource factory was registered !
			hasValidationError = true;
		}
	}

	public void setNoCommonCode() {
		dbusPref.setPreference(PreferenceConstantsDBus.P_GENERATE_COMMON_DBUS,
				"false");
		ConsoleLogger.printLog("No common code will be generated");
	}

	public void setNoProxyCode() {
		dbusPref.setPreference(PreferenceConstantsDBus.P_GENERATE_PROXY_DBUS,
				"false");
		ConsoleLogger.printLog("No proxy code will be generated");
	}

	public void setNoStubCode() {
		dbusPref.setPreference(PreferenceConstantsDBus.P_GENERATE_STUB_DBUS,
				"false");
		ConsoleLogger.printLog("No stub code will be generated");
	}

	public void setDefaultDirectory(String optionValue) {
		ConsoleLogger.printLog("Default output directory: " + optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_DEFAULT_DBUS,
				optionValue);
		// In the case where no other output directories are set,
		// this default directory will be used for them
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS,
				optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS,
				optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS,
				optionValue);
	}

	public void setDestinationSubdirs() {
		ConsoleLogger.printLog("Using destination subdirs");
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_SUBDIRS_DBUS,
			"true");
	}

	public void setCommonDirectory(String optionValue) {
		ConsoleLogger.printLog("Common output directory: " + optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_COMMON_DBUS,
				optionValue);
	}

	public void setProxyDirectory(String optionValue) {
		ConsoleLogger.printLog("Proxy output directory: " + optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_PROXIES_DBUS,
				optionValue);
	}

	public void setStubDirectory(String optionValue) {
		ConsoleLogger.printLog("Stub output directory: " + optionValue);
		dbusPref.setPreference(PreferenceConstantsDBus.P_OUTPUT_STUBS_DBUS,
				optionValue);
	}

	public void setLogLevel(String optionValue) {
		if (PreferenceConstantsDBus.LOGLEVEL_QUIET.equals(optionValue)) {
			dbusPref.setPreference(PreferenceConstantsDBus.P_LOGOUTPUT_DBUS,
					"false");
			ConsoleLogger.enableLogging(false);
			ConsoleLogger.enableErrorLogging(false);
		}
		if (PreferenceConstantsDBus.LOGLEVEL_VERBOSE.equals(optionValue)) {
			dbusPref.setPreference(PreferenceConstantsDBus.P_LOGOUTPUT_DBUS,
					"true");
			ConsoleLogger.enableErrorLogging(true);
			ConsoleLogger.enableLogging(true);
		}
	}

	public void disableValidation() {
		ConsoleLogger.printLog("Validation is off");
		isValidation = false;
	}

	/**
	 * set a preference value to disable code generation
	 */
	public void disableCodeGeneration() {
		ConsoleLogger.printLog("Code generation is off");
		dbusPref.setPreference(PreferenceConstantsDBus.P_GENERATE_CODE_DBUS,
				"false");
	}

	/**
	 * Set a preference value to disable code generation for included types and
	 * interfaces
	 */
	public void noCodeforDependencies() {
		ConsoleLogger.printLog("Code generation for includes is off");
		dbusPref.setPreference(
				PreferenceConstantsDBus.P_GENERATE_DEPENDENCIES_DBUS, "false");
	}

	public void disableSyncCalls() {
		ConsoleLogger.printLog("Code generation for synchronous calls is off");
		dbusPref.setPreference(
				PreferenceConstantsDBus.P_GENERATE_SYNC_CALLS_DBUS, "false");
	}

	/**
	 * Set the text from a file which will be inserted as a comment in each
	 * generated file (for example your license)
	 *
	 * @param fileWithText
	 * @return
	 */
	public void setLicenseText(String fileWithText) {

		String licenseText = getLicenseText(fileWithText);

		if (licenseText != null && !licenseText.isEmpty()) {
			dbusPref.setPreference(PreferenceConstantsDBus.P_LICENSE_DBUS,
					licenseText);
		}
	}

	@Override
	public String getFrancaVersion() {
		return Platform.getBundle("org.franca.core").getVersion().toString();
	}

	public void listGeneratedFiles() {
		dumpGeneratedFiles = true;
	}

}
