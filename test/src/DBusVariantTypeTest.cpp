/* Copyright (C) 2018 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file DBusVariantTypeTest
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
#include "v1/test/varianttype/TestInterfaceProxy.hpp"
#include "v1/test/varianttype/TestInterfaceDBusDeployment.hpp"
#include "stubs/VariantTypeStubImpl.hpp"

const std::string domain = "local";
const std::string testAddress = "test.varianttype.TestInterface";
const std::string connectionIdService = "service-sample";
const std::string connectionIdClient = "client-sample";

const int tasync = 10000;

using namespace v1::test::varianttype;

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

        testStub_ = std::make_shared<v1_0::test::varianttype::VariantTypeStub>();
        serviceRegistered_ = runtime_->registerService(domain, testAddress, testStub_, connectionIdService);
        ASSERT_TRUE(serviceRegistered_);

        testProxy_ = runtime_->buildProxy<v1_0::test::varianttype::TestInterfaceProxy>(domain, testAddress, connectionIdClient);
        int i = 0;
        while(!testProxy_->isAvailable() && i++ < 1000) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        ASSERT_TRUE(testProxy_->isAvailable());
    }

    void TearDown() {
        ASSERT_TRUE(runtime_->unregisterService(domain, v1_0::test::varianttype::TestInterfaceStubDefault::StubInterface::getInterface(), testAddress));

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

    std::shared_ptr<v1_0::test::varianttype::TestInterfaceProxy<>> testProxy_;
    std::shared_ptr<v1_0::test::varianttype::VariantTypeStub> testStub_;
};

// tests based on this class do not use any communication
class DeploymentTest2: public ::testing::Test {
protected:
    void SetUp() {
    }

    void TearDown() {

    }
};
/**
* @test Pass variant through an attribute
*/
TEST_F(DeploymentTest, DefaultVariantTypeAttr) {

    CommonAPI::CallStatus callStatus;
    {
        TestInterface::defaultTypeUnion ud = std::string("/d/2");
        TestInterface::defaultTypeUnion inv;
        testProxy_->getA_defAttribute().setValue(ud, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(ud, inv);

    }
}
/**
* @test Pass variant through an attribute, deployed as a dbus type variant
*/
TEST_F(DeploymentTest, DbusVariantTypeAttr) {

    CommonAPI::CallStatus callStatus;
    {
        TestInterface::dBusTypeUnion ud = std::string("/d/2");
        TestInterface::dBusTypeUnion inv;
        testProxy_->getA_dbusAttribute().setValue(ud, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(ud, inv);

    }
}
/**
* @test Pass variant through an attribute, deployed as a capi type variant
*/
TEST_F(DeploymentTest, CapiVariantTypeAttr) {

    CommonAPI::CallStatus callStatus;
    {
        TestInterface::commonapiTypeUnion ud = std::string("/d/2");
        TestInterface::commonapiTypeUnion inv;
        testProxy_->getA_capiAttribute().setValue(ud, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(ud, inv);

    }
}
/**
* @test look into deployment definitions to see if everything was set up correctly.
*/
TEST_F(DeploymentTest2, VerifyDeploymentValues) {

    EXPECT_EQ(::v1::test::varianttype::TestInterface_::dBusTypeUnionDeployment.isDBus_, true);
    EXPECT_EQ((std::get<0>(::v1::test::varianttype::TestInterface_::a_def_to_dbusDeployment.values_))->isObjectPath_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::a_def_to_dbusDeployment.isDBus_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::a_dbus_to_capiDeployment.isDBus_, false);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::a_capi_to_dbusDeployment.isDBus_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::m0_arg_def_to_dbusDeployment.isDBus_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::m0_arg_dbus_to_capiDeployment.isDBus_, false);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::m0_arg_capi_to_dbusDeployment.isDBus_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::b0_arg_def_to_dbusDeployment.isDBus_, true);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::b0_arg_dbus_to_capiDeployment.isDBus_, false);
    EXPECT_EQ(::v1::test::varianttype::TestInterface_::b0_arg_capi_to_dbusDeployment.isDBus_, true);
}
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
