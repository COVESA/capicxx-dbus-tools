/* Copyright (C) 2014, 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include <unistd.h>

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/examples/ObjectPathSimpleProxy.hpp>

using namespace v1::commonapi::examples;

int main() {
    CommonAPI::Runtime::setProperty("LibraryBase", "ObjectPathSimple");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.examples.ObjectPathSimple";

    std::shared_ptr<ObjectPathSimpleProxyDefault> myProxy = runtime->buildProxy < ObjectPathSimpleProxy > (domain, instance);

    while (!myProxy->isAvailable()) {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
    }

    // Subscribe to broadcast
    myProxy->getTestbEvent().subscribe([&](const std::string& plain, const std::string& path) {
        std::cout << "Received status event: " << plain << " " << path << std::endl;
    });

    while (true) {
        std::string inX1 = "plain";
        std::string inX2 = "/object/path/example";
        CommonAPI::CallStatus callStatus;
        std::string outY1;
        std::string outY2;

        // Synchronous call
        std::cout << "Call method with synchronous semantics ..." << std::endl;
        myProxy->test(inX1, inX2, callStatus, outY1, outY2);

        std::cout << "Result of synchronous call of method: " << std::endl;
        std::cout << "   callStatus: " << ((callStatus == CommonAPI::CallStatus::SUCCESS) ? "SUCCESS" : "NO_SUCCESS")
                  << std::endl;
        std::cout << "   Input values: plain = " << inX1 << ", path = " << inX2 << std::endl;
        std::cout << "   Output values: plain = " << outY2 << ", path = " << outY1 << std::endl;

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    return 0;
}

