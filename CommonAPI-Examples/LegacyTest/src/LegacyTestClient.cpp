/* Copyright (C) 2014, 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include <unistd.h>
#include <gtest/gtest.h>

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/examples/LegacyTestProxy.hpp>

using namespace v1::commonapi::examples;

class Environment: public ::testing::Environment {
public:
    virtual ~Environment() {
    }

    virtual void SetUp() {
    }

    virtual void TearDown() {
    }
};

class LegacyTestClient: public ::testing::Test {

public:

protected:
    void SetUp() {
    CommonAPI::Runtime::setProperty("LibraryBase", "LegacyTest");

        runtime = CommonAPI::Runtime::get();

        std::string domain = "local";
        std::string instance = "commonapi.examples.LegacyTest";
        myProxy = runtime->buildProxy < LegacyTestProxy > (domain, instance);

        while (!myProxy->isAvailable()) {
            std::this_thread::sleep_for(std::chrono::microseconds(10));
        }
        ASSERT_TRUE(myProxy->isAvailable());

    }

    void TearDown() {

    }

    uint8_t value_;
    std::shared_ptr<CommonAPI::Runtime> runtime;
    std::shared_ptr<LegacyTestProxyDefault> myProxy;
};

TEST_F(LegacyTestClient, LegacyClient) {

    static int callbackcount = 0;

    // Subscribe to broadcast
    myProxy->getTestbEvent().subscribe([&](const std::string& plain, const std::string& path) {
        callbackcount++;
    });

    std::string inX1 = "plain";
    std::string inX2 = "/object/path/example";
    CommonAPI::CallStatus callStatus;
    std::string outY1;
    std::string outY2;
    int32_t inInt = 10;

    int32_t outInt;
    LegacyTest::pathunion outPu;

    // Synchronous call
    myProxy->test(inX1, inX2, callStatus, outY1, outY2);

    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Synchronous call with an union
    static const std::string strArg("/test/path/in/union");
    LegacyTest::pathunion inPu(strArg);

    myProxy->testunion(inInt, inPu, callStatus, outInt, outPu);

    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Synchronous call with a structure
    LegacyTest::pathstruct inPs("/path/in/struct", "plain string");
    LegacyTest::pathstruct outPs;

    myProxy->teststruct(inPs, callStatus, outPs);

    std::this_thread::sleep_for(std::chrono::seconds(1));

    // attribute tests.
    std::string inS1 = "test of normal string";
    std::string outS1;
    myProxy->getNopathAttribute().setValue(inS1, callStatus, outS1);
    EXPECT_EQ(outS1, inS1);
    std::this_thread::sleep_for(std::chrono::seconds(1));

    std::string inS2 = "/test/of/object/path/attribute";
    std::string outS2;
    myProxy->getObjectpathAttribute().setValue(inS2, callStatus, outS2);
    EXPECT_EQ(outS2, inS2);
    std::this_thread::sleep_for(std::chrono::seconds(1));

    std::string inS3 = "test of normal default string";
    std::string outS3;
    myProxy->getDefvalueAttribute().setValue(inS3, callStatus, outS3);
    EXPECT_EQ(outS3, inS3);
    std::this_thread::sleep_for(std::chrono::seconds(1));

    // kill off the service with a special attribute setting
    std::string inSk = "kill";
    std::string outSk;
    myProxy->getNopathAttribute().setValue(inSk, callStatus, outSk);
    std::this_thread::sleep_for(std::chrono::seconds(1));

    ASSERT_TRUE(callbackcount > 0);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
