/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <commonapi/tests/TestInterfaceDBusStubAdapter.h>
#include <commonapi/tests/TestInterfaceStubDefault.h>

#include <CommonAPI/Runtime.h>

#include <iostream>
#include <cassert>

int main(void) {
//	auto dbusConnection = CommonAPI::DBus::DBusConnection::getSessionBus();
//	if (!dbusConnection->isConnected()) {
//		std::cout << "Connecting to Session Bus\n";
//		assert(dbusConnection->connect());
//	}
//
//	assert(dbusConnection->requestServiceNameAndBlock("commonapi.tests.TestInterface"));
//
//	auto testInterfaceStubDefault = std::make_shared<commonapi::tests::TestInterfaceStubDefault>();
//
//	auto testInterfaceDBusStubAdapter = std::make_shared<commonapi::tests::TestInterfaceDBusStubAdapter>(
//			"commonapi.tests.TestInterface",
//			"/commonapi/tests/TestInterface",
//			dbusConnection,
//			testInterfaceStubDefault);
//	testInterfaceDBusStubAdapter->init();
//
//	while (dbusConnection->readWriteDispatch(100))
//		;
//
//	return 0;

    auto runtime_ = CommonAPI::Runtime::load();
    std::shared_ptr<CommonAPI::Factory> factory = runtime_->createFactory();
	const std::string serviceAddress_ = "local:commonapi.tests.TestInterface:commonapi.tests.TestInterface";

    auto myStub = std::make_shared<commonapi::tests::TestInterfaceStubDefault>();
    bool success = factory->registerService(myStub, serviceAddress_);

    //myStub->fireTestPredefinedTypeBroadcastEvent(1, "hello");

    while(true) {
    }
}
