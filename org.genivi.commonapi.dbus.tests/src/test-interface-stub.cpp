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
