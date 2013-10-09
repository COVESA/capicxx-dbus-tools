/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#include <commonapi/tests/TestPolymorphicInterfaceStubDefault.h>

#include <CommonAPI/CommonAPI.h>

#include <iostream>
#include <cassert>


class TestPolymorphicInterfaceStubDefaultImpl: public commonapi::tests::TestPolymorphicInterfaceStubDefault {
 public:
    virtual void testPolymorphicStruct(
    		std::shared_ptr<commonapi::tests::TestPolymorphicInterface::TestBaseStruct> testBaseStructIn,
    		std::shared_ptr<commonapi::tests::TestPolymorphicInterface::TestBaseStruct>& testBaseStructOut) {
    	std::cout << "remote call testPolymorphicStruct():\n"
    			<< "    serialId = " << testBaseStructIn->getSerialId() << std::endl
    			<< "    testBaseStructUInt16Value = " << testBaseStructIn->testBaseStructUInt16Value << std::endl
    			<< "    testBaseStructStringValue = " << testBaseStructIn->testBaseStructStringValue << std::endl;

    	switch (testBaseStructIn->getSerialId()) {
    	case commonapi::tests::TestPolymorphicInterface::TestStructDerived1::SERIAL_ID:
    		std::cout << "    testStructDerived1Int16Value = "
    				<< dynamic_cast<commonapi::tests::TestPolymorphicInterface::TestStructDerived1*>(testBaseStructIn.get())->testStructDerived1Int16Value
    				<< std::endl;
    		break;

    	case commonapi::tests::TestPolymorphicInterface::TestStructDerived2::SERIAL_ID:
    		std::cout << "    testStructDerived2Int32Value = "
    				<< dynamic_cast<commonapi::tests::TestPolymorphicInterface::TestStructDerived2*>(testBaseStructIn.get())->testStructDerived2Int32Value
    				<< std::endl;
    		break;

    	case commonapi::tests::TestPolymorphicInterface::TestStructDerived2Derived::SERIAL_ID:
    		std::cout << "    testStructDerived2Int32Value = "
    				<< dynamic_cast<commonapi::tests::TestPolymorphicInterface::TestStructDerived2Derived*>(testBaseStructIn.get())->testStructDerived2Int32Value
    				<< std::endl
    				<<  "    testStructDerived2DerivedUInt32Value = "
    				<< dynamic_cast<commonapi::tests::TestPolymorphicInterface::TestStructDerived2Derived*>(testBaseStructIn.get())->testStructDerived2DerivedUInt32Value
    				<< std::endl;
    		break;
    	}

    	testBaseStructOut = testBaseStructIn;
    }
};


int main(void) {
    auto runtime_ = CommonAPI::Runtime::load();
    std::shared_ptr<CommonAPI::Factory> factory = runtime_->createFactory();
	const std::string serviceAddress_ = "local:commonapi.tests.TestPolymorphicInterface:commonapi.tests.TestPolymorphicInterface";

    auto testPolymorphicInterfaceStub = std::make_shared<TestPolymorphicInterfaceStubDefaultImpl>();
    bool success = factory->registerService(testPolymorphicInterfaceStub, serviceAddress_);
    assert(success);

    while(true) {
    }

    return 0;
}
