/* Copyright (C) 2014, 2015 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <thread>
#include <iostream>
#include <gtest/gtest.h>

#include <CommonAPI/CommonAPI.hpp>
#include "LegacyTestStubImpl.hpp"

class Environment: public ::testing::Environment {
public:
    virtual ~Environment() {
    }

    virtual void SetUp() {
    }

    virtual void TearDown() {
    }
};

class LegacyTestServer: public ::testing::Test {

public:

protected:
    void SetUp() {
        CommonAPI::Runtime::setProperty("LibraryBase", "LegacyTest");

        runtime = CommonAPI::Runtime::get();

        std::string domain = "local";
        std::string instance = "commonapi.examples.LegacyTest";

        myService = std::make_shared<LegacyTestStubImpl>();
        runtime->registerService(domain, instance, myService);
    }

    void TearDown() {

    }

    std::shared_ptr<CommonAPI::Runtime> runtime;
    std::shared_ptr<LegacyTestStubImpl> myService;
};

TEST_F(LegacyTestServer, LegacyServer) {
    for (int i = 8; i > 0; i--) {
        myService->incCounter(); // Change value of attribute, see stub implementation
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}

