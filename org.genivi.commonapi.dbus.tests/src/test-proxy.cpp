/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <commonapi/tests/TestInterfaceProxy.h>
#include <test/bmw/TestProxy.h>

using namespace commonapi::tests;

int main(void) {
    auto runtime_ = CommonAPI::Runtime::load();
    std::shared_ptr<CommonAPI::Factory> factory = runtime_->createFactory();
    const std::string serviceAddress_ = "local:commonapi.tests.TestInterface:commonapi.tests.TestInterface";

    auto proxy = factory->buildProxy<commonapi::tests::TestInterfaceProxy>(serviceAddress_);

    int16_t myInt = 5;
    DerivedTypeCollection::TestUnionIn in(myInt);

    DerivedTypeCollection::TestUnionIn out;

    DerivedTypeCollection::TestUnionOut ext(myInt);

    std::cout << "Comparing variant with extended: " << std::boolalpha << (ext == in) << "\n";

    CommonAPI::CallStatus callStatus;
    proxy->testUnionMethod(in, callStatus, out);
    std::cout << "Status " << (int) callStatus << "\n";

    if (callStatus == CommonAPI::CallStatus::SUCCESS) {
        std::cout << "Union Method returned ";
        if (out.isType<std::string>()) {
            std::cout << out.get<std::string>() << "\n";
        } else if (out.isType<int16_t>()) {
            std::cout << out.get<int16_t>() << "\n";
        } else if (out.isType<double>()) {
            std::cout << out.get<double>() << "\n";
        }
    } else {
        std::cout << "Service not available. \n";
    }

    const std::string serviceTestAddress_ = "local:test.bmw.Test:commonapi.tests.TestInterface";
    auto testProxy = factory->buildProxy<test::bmw::TestProxy>(serviceTestAddress_);

    std::vector<std::string> arraytest;
    arraytest.push_back(std::string("Hello"));
    arraytest.push_back(std::string("Hello2"));

    std::string test = "Testing";
    uint8_t val;

    testProxy->DefGet(arraytest, test, callStatus, val);
	if (callStatus == CommonAPI::CallStatus::SUCCESS) {
		std::cout << "defget method returned " << val;
	}

    testProxy->Get(arraytest, test, callStatus, val);
    if (callStatus == CommonAPI::CallStatus::SUCCESS) {
            std::cout << " get method returned " << val;
    }


    std::vector<uint32_t> vec;
    vec.push_back(1);
    vec.push_back(2);
    test::bmw::Test::testStruct setter(test, vec);

	testProxy->Set(setter, callStatus, val);
	if (callStatus == CommonAPI::CallStatus::SUCCESS) {
		std::cout << " Set method returned " << val;
	}

	test::bmw::Test::myUnion un = vec;

	testProxy->Unions(un, callStatus, val);
	testProxy->Get(arraytest, test, callStatus, val);
	if (callStatus == CommonAPI::CallStatus::SUCCESS) {
		std::cout << " union method returned " << val;
	}

    /*while(true) {
     }*/
}
