/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.dbus.cli;

import java.util.List;

import org.eclipse.emf.common.util.BasicDiagnostic;
import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.franca.deploymodel.dsl.fDeploy.FDModel;
import org.genivi.commonapi.core.verification.CommandlineValidator;
import org.genivi.commonapi.core.verification.DeploymentValidator;

public class CommandLineValidatorDBus extends CommandlineValidator{

	public CommandLineValidatorDBus(ValidationMessageAcceptor cliMessageAcceptor)
    {
        super(cliMessageAcceptor);
    }
    @Override
    public boolean validateDeployment(URI resourcePathUri)
    {
        addIgnoreString("Unable to resolve plug-in \"platform:/plugin/org.genivi.commonapi.someip/deployment/CommonAPI-SOMEIP_deployment_spec.fdepl\"");
        addIgnoreString("Unable to resolve plug-in \"platform:/plugin/org.genivi.commonapi.someip/deployment/CommonAPI-4-SOMEIP_deployment_spec.fdepl\"");
        addIgnoreString("Couldn't resolve reference to FDSpecification 'org.genivi.commonapi.someip.deployment'");
        addIgnoreString("Couldn't resolve reference to FDPropertyDecl");
        return super.validateDeployment(resourcePathUri);
    }

    @Override
    protected List<Diagnostic> validateDeployment(List<FDModel> fdepls)
    {
        BasicDiagnostic diagnostics = new BasicDiagnostic();
        DeploymentValidator coreValidator = new DeploymentValidator();
        coreValidator.validate(fdepls, diagnostics);
        return diagnostics.getChildren();
    }
}
