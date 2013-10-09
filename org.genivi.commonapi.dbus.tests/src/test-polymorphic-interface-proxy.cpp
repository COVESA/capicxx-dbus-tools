/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#include <commonapi/tests/TestPolymorphicInterfaceProxy.h>
#include <CommonAPI/CommonAPI.h>

#include <cassert>

int main(void) {
    auto runtime_ = CommonAPI::Runtime::load();
    std::shared_ptr<CommonAPI::Factory> factory = runtime_->createFactory();
    const std::string serviceAddress_ = "local:commonapi.tests.TestPolymorphicInterface:commonapi.tests.TestPolymorphicInterface";

    auto proxy = factory->buildProxy<commonapi::tests::TestPolymorphicInterfaceProxy>(serviceAddress_);

    CommonAPI::CallStatus callStatus;
    std::shared_ptr<commonapi::tests::TestPolymorphicInterface::TestBaseStruct> testBaseStructOut;


    auto testBaseStructIn = std::make_shared<commonapi::tests::TestPolymorphicInterface::TestBaseStruct>();
    testBaseStructIn->testBaseStructStringValue = "Hello World!";
    testBaseStructIn->testBaseStructUInt16Value = 1234;

    std::cout << "Sending TestBaseStruct (id: " << testBaseStructIn->getSerialId() << ") ...\n";
    proxy->testPolymorphicStruct(testBaseStructIn, callStatus, testBaseStructOut);
    std::cout << "Status: " << (int) callStatus << "\n";
    assert(callStatus == CommonAPI::CallStatus::SUCCESS);


    auto testStructDerived1tIn = std::make_shared<commonapi::tests::TestPolymorphicInterface::TestStructDerived1>();
    testStructDerived1tIn->testBaseStructStringValue = "Hello World!";
    testStructDerived1tIn->testBaseStructUInt16Value = 1234;
    testStructDerived1tIn->testStructDerived1Int16Value = 432;

    std::cout << "Sending TestStructDerived1 (id: " << testStructDerived1tIn->getSerialId() << ") ...\n";
    proxy->testPolymorphicStruct(testStructDerived1tIn, callStatus, testBaseStructOut);
    std::cout << "Status: " << (int) callStatus << "\n";
    assert(callStatus == CommonAPI::CallStatus::SUCCESS);


    auto testStructDerived2tIn = std::make_shared<commonapi::tests::TestPolymorphicInterface::TestStructDerived2>();
    testStructDerived2tIn->testBaseStructStringValue = "Hello World!";
    testStructDerived2tIn->testBaseStructUInt16Value = 1234;
    testStructDerived2tIn->testStructDerived2Int32Value = 43256;

    std::cout << "Sending TestStructDerived1 (id: " << testStructDerived2tIn->getSerialId() << ") ...\n";
    proxy->testPolymorphicStruct(testStructDerived2tIn, callStatus, testBaseStructOut);
    std::cout << "Status: " << (int) callStatus << "\n";
    assert(callStatus == CommonAPI::CallStatus::SUCCESS);


    auto testStructDerived2DerivedtIn = std::make_shared<commonapi::tests::TestPolymorphicInterface::TestStructDerived2Derived>();
    testStructDerived2DerivedtIn->testBaseStructStringValue = "Hello World!";
    testStructDerived2DerivedtIn->testBaseStructUInt16Value = 1234;
    testStructDerived2DerivedtIn->testStructDerived2Int32Value = 43256;
    testStructDerived2DerivedtIn->testStructDerived2DerivedUInt32Value = 56789;

    std::cout << "Sending TestStructDerived1 (id: " << testStructDerived2DerivedtIn->getSerialId() << ") ...\n";
    proxy->testPolymorphicStruct(testStructDerived2DerivedtIn, callStatus, testBaseStructOut);
    std::cout << "Status: " << (int) callStatus << "\n";
    assert(callStatus == CommonAPI::CallStatus::SUCCESS);

    return 0;
}
