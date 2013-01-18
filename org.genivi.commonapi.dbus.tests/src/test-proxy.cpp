/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <commonapi/tests/TestInterfaceProxy.h>

using namespace commonapi::tests;

int main(void) {
    auto runtime_ = CommonAPI::Runtime::load();
    std::shared_ptr<CommonAPI::Factory> factory = runtime_->createFactory();
    const std::string serviceAddress_ = "local:commonapi.tests.TestInterface:commonapi.tests.TestInterface";

    auto proxy = factory->buildProxy<commonapi::tests::TestInterfaceProxy>(serviceAddress_);

    int16_t myInt = 5;
    DerivedTypeCollection::TestUnionIn in(myInt);

    DerivedTypeCollection::TestUnionIn out;

    CommonAPI::CallStatus callStatus;
    proxy->testUnionMethod(in, callStatus, out);
    std::cout << "Status " << (int) callStatus << "\n";

    std::cout << "Union Method returned ";
    if (out.isType<std::string>()) {
        std::cout << out.get<std::string>() << "\n";
    } else if (out.isType<int16_t>()) {
        std::cout << out.get<int16_t>() << "\n";
    } else if (out.isType<double>()) {
        std::cout << out.get<double>() << "\n";
    }

    /*while(true) {
     }*/
}
