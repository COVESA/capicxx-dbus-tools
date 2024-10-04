/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file DBusUnixFDPathTest
*/

#include <condition_variable>
#include <fstream>
#include <functional>
#include <mutex>
#include <numeric>
#include <thread>
#include <thread>

#include <gtest/gtest.h>

#include <CommonAPI/CommonAPI.hpp>

#ifndef COMMONAPI_INTERNAL_COMPILATION
#define COMMONAPI_INTERNAL_COMPILATION
#endif
#include "v1/test/unixfd/TestInterfaceProxy.hpp"
#include "stubs/UnixFDStubImpl.hpp"

const std::string domain = "local";
const std::string testAddress = "test.unixfd.TestInterface";
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

        testStub_ = std::make_shared<v1_0::test::unixfd::UnixFDStub>();
        serviceRegistered_ = runtime_->registerService(domain, testAddress, testStub_, connectionIdService);
        ASSERT_TRUE(serviceRegistered_);

        testProxy_ = runtime_->buildProxy<v1_0::test::unixfd::TestInterfaceProxy>(domain, testAddress, connectionIdClient);
        int i = 0;
        while(!testProxy_->isAvailable() && i++ < 1000) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        ASSERT_TRUE(testProxy_->isAvailable());

        fd_ = 1;
    }

    void TearDown() {
        ASSERT_TRUE(runtime_->unregisterService(domain, v1_0::test::unixfd::TestInterfaceStubDefault::StubInterface::getInterface(), testAddress));

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

    std::shared_ptr<v1_0::test::unixfd::TestInterfaceProxy<>> testProxy_;
    std::shared_ptr<v1_0::test::unixfd::UnixFDStub> testStub_;

    int fd_;
};
/**
* @test Pass an attribute with UNIX fd value and a deployment.
*/
TEST_F(DeploymentTest, UnixFDAttributeWithDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        uint32_t outv = (uint32_t)fd_;
        uint32_t inv;

        testProxy_->getA0Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        testProxy_->getA1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

    }
}

/**
* @test Pass a method argument using Unix FD values.
*/
TEST_F(DeploymentTest, UnixFDMethodArgumentWithDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        uint32_t outv = (uint32_t)fd_;
        v1_0::test::unixfd::TestInterface::MyStruct str;
        std::vector<uint32_t> array;
        array.push_back(outv);
        array.push_back(outv);
        str.setFd2(outv);
        str.setFd0(outv);
        str.setFd1(array);
        str.setFd3(array);
        v1_0::test::unixfd::TestInterface::MyUnion u;
        u = outv;
        testProxy_->f0(outv, outv, str, u, callStatus);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        uint32_t outv = (uint32_t)fd_;
        int32_t ioutv = (int32_t)fd_;
        v1_0::test::unixfd::TestInterface::MyStruct str;
        std::vector<uint32_t> array;
        array.push_back(outv);
        array.push_back(outv);
        str.setFd2(outv);
        str.setFd0(outv);
        str.setFd1(array);
        str.setFd3(array);
        v1_0::test::unixfd::TestInterface::MyUnion u;
        u = ioutv;
        testProxy_->f0(outv, outv, str, u, callStatus);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}

/**
* @test Pass a broadcast argument using unix fds
*/
TEST_F(DeploymentTest, UnixFDBroadcastArgumentWithDeployment) {

    CommonAPI::CallStatus callStatus;
    std::atomic<CommonAPI::CallStatus> subStatus;
    std::atomic<uint8_t> result;
    std::atomic<uint32_t> r1;
    std::atomic<v1_0::test::unixfd::TestInterface::UnixFD> r2;
    std::atomic<uint32_t> r3;
    std::atomic<uint32_t> r4;
    std::atomic<uint32_t> r5;
    std::atomic<uint32_t> r6;
    std::atomic<uint32_t> r7;
    std::atomic<uint32_t> r8;
    std::atomic<uint32_t> r9;

    // subscribe to broadcast
    subStatus = CommonAPI::CallStatus::UNKNOWN;
    result = 0;
    testProxy_->getB0Event().subscribe([&](
        const uint32_t &arg1,
        const v1_0::test::unixfd::TestInterface::UnixFD &arg2,
        const v1_0::test::unixfd::TestInterface::MyStruct &arg3,
        const v1_0::test::unixfd::TestInterface::MyUnion &arg4
    ) {
        r1 = arg1;
        r2 = arg2;
        r3 = arg3.getFd2();
        r4 = arg3.getFd0();
        std::vector<uint32_t> array = arg3.getFd1();
        r5 = array.at(0);
        r6 = array.at(1);
        std::vector<uint32_t> array2 = arg3.getFd3();
        r7 = array2.at(0);
        r8 = array2.at(1);
        if (arg4 == (uint32_t)1) r9 = 1;
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
    EXPECT_EQ(r1, (uint32_t)1);
    EXPECT_EQ(r2, (uint32_t)1);
    EXPECT_EQ(r3, (uint32_t)1);
    EXPECT_EQ(r4, (uint32_t)1);
    EXPECT_EQ(r5, (uint32_t)1);
    EXPECT_EQ(r6, (uint32_t)1);
    EXPECT_EQ(r7, (uint32_t)1);
    EXPECT_EQ(r8, (uint32_t)1);
    EXPECT_EQ(r9, (uint32_t)1);

}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
