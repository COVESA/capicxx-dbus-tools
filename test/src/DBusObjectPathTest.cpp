/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file DBusObjectPathTest
*/

#include <condition_variable>
#include <fstream>
#include <functional>
#include <mutex>
#include <numeric>
#include <thread>

#include <gtest/gtest.h>

#include <CommonAPI/CommonAPI.hpp>

#ifndef COMMONAPI_INTERNAL_COMPILATION
#define COMMONAPI_INTERNAL_COMPILATION
#endif
#include "v1/test/objectpath/TestInterfaceProxy.hpp"
#include "stubs/ObjectPathStubImpl.hpp"

const std::string domain = "local";
const std::string testAddress = "test.objectpath.TestInterface";
const std::string connectionIdService = "service-sample";
const std::string connectionIdClient = "client-sample";

const int tasync = 10000;

class Environment: public ::testing::Environment {
public:
    virtual ~Environment() {
    }

    virtual void SetUp() {
    }

    virtual void TearDown() {
    }
};

class DeploymentTest: public ::testing::Test {
protected:
    void SetUp() {
        runtime_ = CommonAPI::Runtime::get();
        ASSERT_TRUE((bool)runtime_);

        testStub_ = std::make_shared<v1_0::test::objectpath::ObjectPathStub>();
        serviceRegistered_ = runtime_->registerService(domain, testAddress, testStub_, connectionIdService);
        ASSERT_TRUE(serviceRegistered_);

        testProxy_ = runtime_->buildProxy<v1_0::test::objectpath::TestInterfaceProxy>(domain, testAddress, connectionIdClient);
        int i = 0;
        while(!testProxy_->isAvailable() && i++ < 1000) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        ASSERT_TRUE(testProxy_->isAvailable());
    }

    void TearDown() {
        ASSERT_TRUE(runtime_->unregisterService(domain, v1_0::test::objectpath::TestInterfaceStubDefault::StubInterface::getInterface(), testAddress));

        // wait that proxy is not available
        int counter = 0;  // counter for avoiding endless loop
        while ( testProxy_->isAvailable() && counter < 1000 ) {
            std::this_thread::sleep_for(std::chrono::microseconds(tasync));
            counter++;
        }

        ASSERT_FALSE(testProxy_->isAvailable());
    }

    bool received_;
    bool serviceRegistered_;
    std::shared_ptr<CommonAPI::Runtime> runtime_;

    std::shared_ptr<v1_0::test::objectpath::TestInterfaceProxy<>> testProxy_;
    std::shared_ptr<v1_0::test::objectpath::ObjectPathStub> testStub_;
};
/**
* @test Pass an attribute with string value and a deployment.
*/
TEST_F(DeploymentTest, StringAttributeWithDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        std::string goodpath = "/a/bc";
        std::string inv;

        testProxy_->getA0Attribute().setValue(goodpath, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(goodpath, inv);

        testProxy_->getA1Attribute().setValue(goodpath, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(goodpath, inv);

    }
}

/**
* @test Pass a method argument using object paths.
*/
TEST_F(DeploymentTest, StringMethodArgumentWithDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        std::string goodpath = "/a/bc";
        v1_0::test::objectpath::TestInterface::MyStruct str;
        std::vector<std::string> array;
        array.push_back(goodpath);
        array.push_back(goodpath);
        str.setS2(goodpath);
        str.setS0(goodpath);
        str.setS1(array);
        str.setS3(array);
        v1_0::test::objectpath::TestInterface::MyUnion u;
        u = goodpath;

        testProxy_->f0(goodpath, goodpath, str, u, callStatus);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}

/**
* @test Pass a broadcast argument using object paths
*/
TEST_F(DeploymentTest, StringBroadcastArgumentWithDeployment) {

    CommonAPI::CallStatus callStatus;
    std::atomic<CommonAPI::CallStatus> subStatus;
    std::atomic<uint8_t> result;

    // subscribe to broadcast
    subStatus = CommonAPI::CallStatus::UNKNOWN;
    result = 0;
    testProxy_->getB0Event().subscribe([&](
        const std::string &arg1,
        const v1_0::test::objectpath::TestInterface::StringType &arg2,
        const v1_0::test::objectpath::TestInterface::MyStruct &arg3,
        const v1_0::test::objectpath::TestInterface::MyUnion &arg4
    ) {
        (void) arg1;
        (void) arg2;
        (void) arg3;
        (void) arg4;
        result = 1;
    },
    [&](
        const CommonAPI::CallStatus &status
    ) {
        subStatus = status;
    });

    // check that subscription has succeeded
    for (int i = 0; i < 100; i++) {
        if (subStatus == CommonAPI::CallStatus::SUCCESS) break;
        std::this_thread::sleep_for(std::chrono::microseconds(tasync));
    }
    EXPECT_EQ(CommonAPI::CallStatus::SUCCESS, subStatus);

    // send value 1 via a method call - this tells stub to broadcast
    uint8_t in_ = 1;
    testProxy_->stubCmd(in_, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

    // check that value was correctly received
    for (int i = 0; i < 100; i++) {
        if (result == 1) break;
        std::this_thread::sleep_for(std::chrono::microseconds(tasync));
    }
    EXPECT_EQ(result, 1);

}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
