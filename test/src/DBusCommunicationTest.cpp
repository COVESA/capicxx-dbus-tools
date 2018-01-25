// Copyright (C) 2013-2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <gtest/gtest.h>

#include <cassert>
#include <cstdint>
#include <iostream>
#include <functional>
#include <memory>
#include <stdint.h>
#include <string>
#include <utility>
#include <tuple>
#include <type_traits>

#include <dbus/dbus.h>

#include <CommonAPI/CommonAPI.hpp>

#ifndef COMMONAPI_INTERNAL_COMPILATION
#define COMMONAPI_INTERNAL_COMPILATION
#endif

#include <CommonAPI/DBus/DBusAddressTranslator.hpp>
#include <CommonAPI/DBus/DBusConnection.hpp>
#include <CommonAPI/DBus/DBusProxy.hpp>

#include "commonapi/tests/PredefinedTypeCollection.hpp"
#include "commonapi/tests/DerivedTypeCollection.hpp"
#include "v1/commonapi/tests/TestInterfaceProxy.hpp"
#include "v1/commonapi/tests/TestInterfaceStubDefault.hpp"
#include "v1/commonapi/tests/TestInterfaceDBusStubAdapter.hpp"
#include "v1/commonapi/tests/TestInterfaceDBusProxy.hpp"

#include "stubs/TestInterfaceStubImpl.hpp"

#define VERSION v1_0

class DBusCommunicationTest: public ::testing::Test {
 public:

    void recvTimeout(const CommonAPI::CallStatus& callStatus, const std::string &_message) {
        std::lock_guard<std::mutex> timeoutsLock(timeoutsMutex_);
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::NOT_AVAILABLE);
        timeoutsOccured_.push_back(true);
        (void)_message;
    }

 protected:
    virtual void SetUp() {
        runtime_ = CommonAPI::Runtime::get();
        ASSERT_TRUE((bool)runtime_);
    }

    virtual void TearDown() {
        runtime_->unregisterService(domain_, interface_, serviceAddress_);
        runtime_->unregisterService(domain_, interface_, serviceAddress2_);
        runtime_->unregisterService(domain_, interface_, serviceAddress3_);
        runtime_->unregisterService(domain_, interface_, serviceAddress4_);
        runtime_->unregisterService(domain_, interface_, serviceAddress5_);
        std::this_thread::sleep_for(std::chrono::microseconds(30000));
    }

    std::shared_ptr<CommonAPI::Runtime> runtime_;

    std::string interface_;

    static const std::string domain_;
    static const std::string serviceAddress_;
    static const std::string serviceAddress2_;
    static const std::string serviceAddress3_;
    static const std::string serviceAddress4_;
    static const std::string nonstandardAddress_;
    static const std::string serviceAddress5_;

    std::mutex timeoutsMutex_;
    std::vector<bool> timeoutsOccured_;
};

const std::string DBusCommunicationTest::domain_ = "local";
const std::string DBusCommunicationTest::serviceAddress_ = "CommonAPI.DBus.tests.DBusProxyTestService";
const std::string DBusCommunicationTest::serviceAddress2_ = "CommonAPI.DBus.tests.DBusProxyTestService2";
const std::string DBusCommunicationTest::serviceAddress3_ = "CommonAPI.DBus.tests.DBusProxyTestService3";
const std::string DBusCommunicationTest::serviceAddress4_ = "CommonAPI.DBus.tests.DBusProxyTestService4";
const std::string DBusCommunicationTest::nonstandardAddress_ = "non.standard.participand.ID";
const std::string DBusCommunicationTest::serviceAddress5_ = "CommonAPI.DBus.tests.DBusProxyTestService5";


TEST_F(DBusCommunicationTest, RemoteMethodCallSucceeds) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint32_t v1 = 5;
    std::string v2 = "Ciao ;)";
    CommonAPI::CallStatus stat;
    defaultTestProxy->testVoidPredefinedTypeMethod(v1, v2, stat);

    EXPECT_EQ(stat, CommonAPI::CallStatus::SUCCESS);
}

TEST_F(DBusCommunicationTest, RemoteMethodCallWithErrorReply) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubImpl>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    bool errorReplyEventReceived = false;
    defaultTestProxy->getDisconnectedErrorEvent().subscribe([&errorReplyEventReceived, &stub](const std::string &_errorMessage, const std::string &_errorDescription,
            const int32_t _errorCode) {
        EXPECT_EQ(stub->getErrorReplyMessage(), _errorMessage);
        EXPECT_EQ(stub->getErrorReplyDescription(), _errorDescription);
        EXPECT_EQ(stub->getErrorReplyCode(), _errorCode);
        errorReplyEventReceived = true;
    });

    CommonAPI::CallStatus stat;
    std::string message;
    defaultTestProxy->testErrorReplyMethod("dummyStr", stat, message);
    EXPECT_EQ(stat, CommonAPI::CallStatus::REMOTE_ERROR);
    ASSERT_TRUE(errorReplyEventReceived);
}

TEST_F(DBusCommunicationTest, RemoteAsyncMethodCallWithErrorReply) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubImpl>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    bool errorReplyEventReceived = false;
    defaultTestProxy->getDisconnectedErrorEvent().subscribe([&errorReplyEventReceived, &stub](const std::string &_errorMessage, const std::string &_errorDescription,
            const int32_t _errorCode) {
        EXPECT_EQ(stub->getErrorReplyMessage(), _errorMessage);
        EXPECT_EQ(stub->getErrorReplyDescription(), _errorDescription);
        EXPECT_EQ(stub->getErrorReplyCode(), _errorCode);
        errorReplyEventReceived = true;
    });

    bool errorReplyResponseReceived = false;
    defaultTestProxy->testErrorReplyMethodAsync("dummyStr", [&errorReplyResponseReceived](const CommonAPI::CallStatus &_status, const std::string &_message) {
        (void)_message;
        EXPECT_EQ(_status, CommonAPI::CallStatus::REMOTE_ERROR);
        errorReplyResponseReceived = true;
    });

    for(unsigned int i = 0; !errorReplyEventReceived && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(errorReplyEventReceived);

    for(unsigned int i = 0; !errorReplyResponseReceived && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(errorReplyResponseReceived);
}

TEST_F(DBusCommunicationTest, RemoteAsyncMethodCallWithErrorReplyProxyNotAvailable) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    int counter = 0;
    while ( defaultTestProxy->isAvailable() && counter < 100 ) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
        counter++;
    }
    ASSERT_FALSE(defaultTestProxy->isAvailable());

    bool errorReplyEventReceived = false;
    defaultTestProxy->getDisconnectedErrorEvent().subscribe([&errorReplyEventReceived](const std::string &_errorMessage, const std::string &_errorDescription,
            const int32_t _errorCode) {
        (void)_errorMessage;
        (void)_errorDescription;
        (void)_errorCode;
        errorReplyEventReceived = true;
    });

    std::function<void (const CommonAPI::CallStatus&, const std::string&)> timeoutCallback = 
        std::bind(&DBusCommunicationTest::recvTimeout, this, std::placeholders::_1, std::placeholders::_2);

    CommonAPI::CallInfo info(100);
    defaultTestProxy->testErrorReplyMethodAsync("dummyStr", timeoutCallback, &info);

    int t=0;
    timeoutsMutex_.lock();
    while(timeoutsOccured_.size() == 0 && t <= 8) {
        timeoutsMutex_.unlock();
        std::this_thread::sleep_for(std::chrono::microseconds(80000));
        timeoutsMutex_.lock();
        t++;
    }

    EXPECT_EQ(1u, timeoutsOccured_.size());
    ASSERT_TRUE(timeoutsOccured_[0]);
    timeoutsMutex_.unlock();
    ASSERT_FALSE(errorReplyEventReceived);
}

TEST_F(DBusCommunicationTest, RemoteAsyncMethodCallWithErrorReplyProxyBecomesAvailable) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    int counter = 0;
    while ( defaultTestProxy->isAvailable() && counter < 100 ) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
        counter++;
    }
    ASSERT_FALSE(defaultTestProxy->isAvailable());

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubImpl>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool errorReplyEventReceived = false;
    defaultTestProxy->getDisconnectedErrorEvent().subscribe([&errorReplyEventReceived, &stub](const std::string &_errorMessage, const std::string &_errorDescription,
            const int32_t _errorCode) {
        EXPECT_EQ(stub->getErrorReplyMessage(), _errorMessage);
        EXPECT_EQ(stub->getErrorReplyDescription(), _errorDescription);
        EXPECT_EQ(stub->getErrorReplyCode(), _errorCode);
        errorReplyEventReceived = true;
    });

    CommonAPI::CallInfo info(1000);
    bool errorReplyResponseReceived = false;
    defaultTestProxy->testErrorReplyMethodAsync("dummyStr", [&errorReplyResponseReceived](const CommonAPI::CallStatus &_status, const std::string &_message) {
        (void)_message;
        EXPECT_EQ(_status, CommonAPI::CallStatus::REMOTE_ERROR);
        errorReplyResponseReceived = true;
    }, &info);

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    counter = 0;
    while (!defaultTestProxy->isAvailable() && 100 > counter++) {
        std::this_thread::sleep_for(std::chrono::microseconds(20000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    for(unsigned int i = 0; !errorReplyEventReceived && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(errorReplyEventReceived);

    for(unsigned int i = 0; !errorReplyResponseReceived && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(errorReplyResponseReceived);
}

TEST_F(DBusCommunicationTest, RemoteOverloadedMethodCall) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubImpl>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint8_t x = 5;
    uint8_t y = 4;
    uint8_t z = 0;
    CommonAPI::CallStatus callStatus;

    defaultTestProxy->testOverloadedMethod(x, callStatus, z);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(x, z);

    x = 5;
    y = 4;
    z = 0;
    defaultTestProxy->testOverloadedMethod(x, y, callStatus, z);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(x+y, z);

}

TEST_F(DBusCommunicationTest, RemoteAsyncOverloadedMethodCall) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubImpl>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint8_t x = 5;
    std::vector<uint8_t> values;

    defaultTestProxy->testOverloadedMethodAsync(x, [&values](const CommonAPI::CallStatus& callStatus, uint8_t z) {
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        values.push_back(z);
    });

    for(unsigned int i = 0; values.empty() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }

    EXPECT_EQ(1u, values.size());
    EXPECT_EQ(x, values[0]);

    x = 5;
    uint8_t y = 4;
    values.clear();

    defaultTestProxy->testOverloadedMethodAsync(x, y, [&values](const CommonAPI::CallStatus& callStatus, uint8_t z) {
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        values.push_back(z);
    });

    for(unsigned int i = 0; values.empty() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }

    EXPECT_EQ(1u, values.size());
    EXPECT_EQ(x+y, values[0]);
}

TEST_F(DBusCommunicationTest, AccessStubAdapterAfterInitialised) {
    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();
    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");

    unsigned int in = 5;
    stub->setTestPredefinedTypeAttributeAttribute(in);

    for (unsigned int i = 0; !serviceRegistered && i < 100; i++) {
        if (!serviceRegistered) {
            serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        }
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);
    ASSERT_EQ(in, stub->getTestPredefinedTypeAttributeAttribute());
}

TEST_F(DBusCommunicationTest, AccessStubAdapterBeforeInitialised) {
    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    unsigned int in = 5;
    stub->setTestPredefinedTypeAttributeAttribute(in);

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");

    for (unsigned int i = 0; !serviceRegistered && i < 100; i++) {
        if (!serviceRegistered) {
            serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        }
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);
}

TEST_F(DBusCommunicationTest, SameStubCanBeRegisteredSeveralTimes) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress_);
    auto defaultTestProxy2 = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress2_);
    auto defaultTestProxy3 = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress3_);
    ASSERT_TRUE((bool)defaultTestProxy);
    ASSERT_TRUE((bool)defaultTestProxy2);
    ASSERT_TRUE((bool)defaultTestProxy3);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
    bool serviceRegistered2 = runtime_->registerService(domain_, serviceAddress2_, stub, "connection");
    bool serviceRegistered3 = runtime_->registerService(domain_, serviceAddress3_, stub, "connection");
    for (unsigned int i = 0; (!serviceRegistered || !serviceRegistered2 || !serviceRegistered3) && i < 100; ++i) {
        if (!serviceRegistered) {
            serviceRegistered = runtime_->registerService(domain_, serviceAddress_, stub, "connection");
        }
        if (!serviceRegistered2) {
            serviceRegistered2 = runtime_->registerService(domain_, serviceAddress2_, stub, "connection");
        }
        if (!serviceRegistered3) {
            serviceRegistered3 = runtime_->registerService(domain_, serviceAddress3_, stub, "connection");
        }
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);
    ASSERT_TRUE(serviceRegistered2);
    ASSERT_TRUE(serviceRegistered3);

    for(unsigned int i = 0; (!defaultTestProxy->isAvailable() || !defaultTestProxy2->isAvailable() || !defaultTestProxy3->isAvailable()) && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());
    ASSERT_TRUE(defaultTestProxy2->isAvailable());
    ASSERT_TRUE(defaultTestProxy3->isAvailable());

    uint32_t v1 = 5;
    std::string v2 = "Ciao ;)";
    CommonAPI::CallStatus stat, stat2, stat3;
    defaultTestProxy->testVoidPredefinedTypeMethod(v1, v2, stat);
    defaultTestProxy2->testVoidPredefinedTypeMethod(v1, v2, stat2);
    defaultTestProxy3->testVoidPredefinedTypeMethod(v1, v2, stat3);

    EXPECT_EQ(stat, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(stat2, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(stat3, CommonAPI::CallStatus::SUCCESS);
}


TEST_F(DBusCommunicationTest, RemoteMethodCallWithNonstandardAddressSucceeds) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, nonstandardAddress_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, nonstandardAddress_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, nonstandardAddress_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint32_t v1 = 5;
    std::string v2 = "Hai :)";
    CommonAPI::CallStatus stat;
    defaultTestProxy->testVoidPredefinedTypeMethod(v1, v2, stat);

    EXPECT_EQ(stat, CommonAPI::CallStatus::SUCCESS);
}

TEST_F(DBusCommunicationTest, MixedSyncAndAsyncCallsSucceed) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress5_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress5_, stub, "connection");
    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress5_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for (unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint32_t v1 = 5;
    std::string v2 = "Hai :)";
    CommonAPI::CallStatus stat;
    unsigned int responseCounter = 0;
    for (unsigned int i = 0; i < 10; i++) {
        defaultTestProxy->testVoidPredefinedTypeMethodAsync(v1, v2, [&responseCounter](const CommonAPI::CallStatus& status) {
                if(status == CommonAPI::CallStatus::SUCCESS) {
                    responseCounter++;
                }
            }
        );

        defaultTestProxy->testVoidPredefinedTypeMethod(v1, v2, stat);
        EXPECT_EQ(stat, CommonAPI::CallStatus::SUCCESS);
    }

    for (unsigned int i = 0; i < 500 && responseCounter < 10; i++) {
        std::this_thread::sleep_for(std::chrono::microseconds(1000));
    }
    EXPECT_EQ(10u, responseCounter);
}


TEST_F(DBusCommunicationTest, RemoteMethodCallHeavyLoad) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress4_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress4_, stub, "connection");
    for (unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
        serviceRegistered = runtime_->registerService(domain_, serviceAddress4_, stub, "connection");
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(serviceRegistered);

    for (unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    uint32_t v1 = 5;
    std::string v2 = "Ciao ;)";
    CommonAPI::CallStatus stat;

    for (uint32_t i = 0; i < 1000; i++) {
        defaultTestProxy->testVoidPredefinedTypeMethod(v1, v2, stat);
        EXPECT_EQ(stat, CommonAPI::CallStatus::SUCCESS);
    }
}

TEST_F(DBusCommunicationTest, ProxyCanFetchVersionAttributeFromStub) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, serviceAddress4_);
    ASSERT_TRUE((bool)defaultTestProxy);

    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
    interface_ = stub->getStubAdapter()->getInterface();

    bool serviceRegistered = runtime_->registerService(domain_, serviceAddress4_, stub, "connection");

    ASSERT_TRUE(serviceRegistered);

    for (unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
    }
    ASSERT_TRUE(defaultTestProxy->isAvailable());

    CommonAPI::InterfaceVersionAttribute& versionAttribute = defaultTestProxy->getInterfaceVersionAttribute();

    CommonAPI::Version version;
    CommonAPI::CallStatus status;
    versionAttribute.getValue(status, version);
    ASSERT_EQ(CommonAPI::CallStatus::SUCCESS, status);
    ASSERT_TRUE(version.Major > 0 || version.Minor > 0);
}

//XXX This test case requires CommonAPI::DBus::DBusConnection::suspendDispatching and ...::resumeDispatching to be public!

//static const std::string commonApiAddress = "local:CommonAPI.DBus.tests.DBusProxyTestInterface:CommonAPI.DBus.tests.DBusProxyTestService";
//static const std::string interfaceName = "CommonAPI.DBus.tests.DBusProxyTestInterface";
//static const std::string busName = "CommonAPI.DBus.tests.DBusProxyTestService";
//static const std::string objectPath = "/CommonAPI/DBus/tests/DBusProxyTestService";

//TEST_F(DBusCommunicationTest, AsyncCallsAreQueuedCorrectly) {
//    auto proxyDBusConnection = CommonAPI::DBus::DBusConnection::getSessionBus();
//    ASSERT_TRUE(proxyDBusConnection->connect());
//
//    auto stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
//
//    bool serviceRegistered = stubFactory_->registerService(stub, serviceAddress_);
//    for(unsigned int i = 0; !serviceRegistered && i < 100; ++i) {
//        serviceRegistered = stubFactory_->registerService(stub, serviceAddress_);
//        std::this_thread::sleep_for(std::chrono::microseconds(10000));
//    }
//    ASSERT_TRUE(serviceRegistered);
//
//    auto defaultTestProxy = std::make_shared<VERSION::commonapi::tests::TestInterfaceDBusProxy>(
//                            commonApiAddress,
//                            interfaceName,
//                            busName,
//                            objectPath,
//                            proxyDBusConnection);
//
//    for(unsigned int i = 0; !defaultTestProxy->isAvailable() && i < 100; ++i) {
//        std::this_thread::sleep_for(std::chrono::microseconds(10000));
//    }
//    ASSERT_TRUE(defaultTestProxy->isAvailable());
//
//    auto val1 = ::commonapi::tests::DerivedTypeCollection::TestEnumExtended2::E_OK;
//    ::commonapi::tests::DerivedTypeCollection::TestMap val2;
//    CommonAPI::CallStatus status;
//    unsigned int numCalled = 0;
//    const unsigned int maxNumCalled = 1000;
//    for(unsigned int i = 0; i < maxNumCalled/2; ++i) {
//        defaultTestProxy->testVoidDerivedTypeMethodAsync(val1, val2,
//                [&] (CommonAPI::CallStatus stat) {
//                    if(stat == CommonAPI::CallStatus::SUCCESS) {
//                        numCalled++;
//                    }
//                }
//        );
//    }
//
//    proxyDBusConnection->suspendDispatching();
//
//    for(unsigned int i = maxNumCalled/2; i < maxNumCalled; ++i) {
//        defaultTestProxy->testVoidDerivedTypeMethodAsync(val1, val2,
//                [&] (CommonAPI::CallStatus stat) {
//                    if(stat == CommonAPI::CallStatus::SUCCESS) {
//                        numCalled++;
//                    }
//                }
//        );
//    }
//    sleep(2);
//
//    proxyDBusConnection->resumeDispatching();
//
//    sleep(2);
//
//    ASSERT_EQ(maxNumCalled, numCalled);
//
//    numCalled = 0;
//
//    defaultTestProxy->getTestPredefinedTypeBroadcastEvent().subscribe(
//            [&] (uint32_t, std::string) {
//                numCalled++;
//            }
//    );
//
//    proxyDBusConnection->suspendDispatching();
//
//    for(unsigned int i = 0; i < maxNumCalled; ++i) {
//        stub->fireTestPredefinedTypeBroadcastEvent(0, "Nonething");
//    }
//
//    sleep(2);
//    proxyDBusConnection->resumeDispatching();
//    sleep(2);
//
//    ASSERT_EQ(maxNumCalled, numCalled);
//}



class DBusLowLevelCommunicationTest: public ::testing::Test {
 protected:
    virtual void SetUp() {
        runtime_ = CommonAPI::Runtime::get();
        ASSERT_TRUE((bool)runtime_);
    }

    virtual void TearDown() {
        std::this_thread::sleep_for(std::chrono::microseconds(30000));
    }

    std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> createDBusStubAdapter(std::shared_ptr<CommonAPI::DBus::DBusConnection> dbusConnection,
                                                                            const std::string& commonApiAddress) {
        CommonAPI::DBus::DBusAddress dbusAddress;
        CommonAPI::DBus::DBusAddressTranslator::get()->translate(commonApiAddress, dbusAddress);

        std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> dbusStubAdapter;
        std::shared_ptr<VERSION::commonapi::tests::TestInterfaceStubDefault> stub = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();

        dbusStubAdapter = std::make_shared<VERSION::commonapi::tests::TestInterfaceDBusStubAdapter<VERSION::commonapi::tests::TestInterfaceStub>>(dbusAddress, dbusConnection, stub);

        dbusStubAdapter->init(dbusStubAdapter);

        std::shared_ptr<CommonAPI::DBus::DBusObjectManagerStub> rootDBusObjectManagerStub = dbusConnection->getDBusObjectManager()->getRootDBusObjectManagerStub();

        rootDBusObjectManagerStub->exportManagedDBusStubAdapter(dbusStubAdapter);

        const auto dbusObjectManager = dbusConnection->getDBusObjectManager();
        dbusObjectManager->registerDBusStubAdapter(dbusStubAdapter);

        return dbusStubAdapter;
    }

    std::shared_ptr<CommonAPI::Runtime> runtime_;
    std::shared_ptr<CommonAPI::Factory> proxyFactory_;

    static const std::string domain_;
    static const std::string lowLevelCapiAddress_;
    static const std::string lowLevelAddressInstance_;
    static const std::string lowLevelConnectionName_;
};

const std::string DBusLowLevelCommunicationTest::domain_ = "local";
const std::string DBusLowLevelCommunicationTest::lowLevelCapiAddress_ = "local:commonapi.tests.TestInterface:v1_0:CommonAPI.DBus.tests.DBusProxyLowLevelService";
const std::string DBusLowLevelCommunicationTest::lowLevelAddressInstance_ = "CommonAPI.DBus.tests.DBusProxyLowLevelService";
const std::string DBusLowLevelCommunicationTest::lowLevelConnectionName_ = "commonapi.tests.TestInterface.v1_0_CommonAPI.DBus.tests.DBusProxyLowLevelService";

namespace DBusCommunicationTestNamespace {
::DBusHandlerResult onLibdbusObjectPathMessageThunk(::DBusConnection* libdbusConnection,
                                                    ::DBusMessage* libdbusMessage,
                                                    void* userData) {
    (void)libdbusConnection;
    (void)libdbusMessage;
    (void)userData;
    return ::DBusHandlerResult::DBUS_HANDLER_RESULT_HANDLED;
}

DBusObjectPathVTable libdbusObjectPathVTable = {
                NULL,
                &onLibdbusObjectPathMessageThunk,
                NULL, NULL, NULL, NULL
};
}

TEST_F(DBusLowLevelCommunicationTest, AgressiveNameClaimingOfServicesIsHandledCorrectly) {
    auto defaultTestProxy = runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain_, lowLevelAddressInstance_);
    ASSERT_TRUE((bool)defaultTestProxy);

    uint32_t counter = 0;
    CommonAPI::AvailabilityStatus status;

    CommonAPI::ProxyStatusEvent& proxyStatusEvent = defaultTestProxy->getProxyStatusEvent();
    proxyStatusEvent.subscribe([&counter, &status](const CommonAPI::AvailabilityStatus& stat) {
        ++counter;
        status = stat;
    });

    std::this_thread::sleep_for(std::chrono::microseconds(1000000));

    EXPECT_EQ(1u, counter);
    EXPECT_EQ(CommonAPI::AvailabilityStatus::NOT_AVAILABLE, status);

    //Set up low level connections
    ::DBusConnection* libdbusConnection1 = dbus_bus_get_private(DBUS_BUS_SESSION, NULL);
    ::DBusConnection* libdbusConnection2 = dbus_bus_get_private(DBUS_BUS_SESSION, NULL);

    ASSERT_TRUE(libdbusConnection1);
    ASSERT_TRUE(libdbusConnection2);

    dbus_connection_set_exit_on_disconnect(libdbusConnection1, false);
    dbus_connection_set_exit_on_disconnect(libdbusConnection2, false);

    bool endDispatch = false;
    std::promise<bool> ended;
    std::future<bool> hasEnded = ended.get_future();

    std::thread([&]() {
            dbus_bool_t libdbusSuccess = true;
            while (!endDispatch && libdbusSuccess) {
                libdbusSuccess = dbus_connection_read_write_dispatch(libdbusConnection1, 10);
                libdbusSuccess &= dbus_connection_read_write_dispatch(libdbusConnection2, 10);
            }
            ended.set_value(true);
    }).detach();

    //Test first connect
    std::shared_ptr<CommonAPI::DBus::DBusConnection> dbusConnection1 = std::make_shared<CommonAPI::DBus::DBusConnection>(libdbusConnection1, "connection1");
    ASSERT_TRUE(dbusConnection1->isConnected());
    std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> adapter1 = createDBusStubAdapter(dbusConnection1, lowLevelCapiAddress_);

    int libdbusStatus = dbus_bus_request_name(libdbusConnection1,
                    lowLevelConnectionName_.c_str(),
                    DBUS_NAME_FLAG_ALLOW_REPLACEMENT | DBUS_NAME_FLAG_REPLACE_EXISTING,
                    NULL);

    dbus_connection_try_register_object_path(libdbusConnection1,
                    "/",
                    &DBusCommunicationTestNamespace::libdbusObjectPathVTable,
                    NULL,
                    NULL);

    std::this_thread::sleep_for(std::chrono::microseconds(1000000));

    EXPECT_EQ(DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER, libdbusStatus);
    EXPECT_EQ(2u, counter);
    EXPECT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, status);

    //Test second connect
    std::shared_ptr<CommonAPI::DBus::DBusConnection> dbusConnection2 = std::make_shared<CommonAPI::DBus::DBusConnection>(libdbusConnection2, "connection2");
    ASSERT_TRUE(dbusConnection2->isConnected());
    std::shared_ptr<CommonAPI::DBus::DBusStubAdapter> adapter2 = createDBusStubAdapter(dbusConnection2, lowLevelCapiAddress_);

    libdbusStatus = dbus_bus_request_name(libdbusConnection2,
                    lowLevelConnectionName_.c_str(),
                    DBUS_NAME_FLAG_ALLOW_REPLACEMENT | DBUS_NAME_FLAG_REPLACE_EXISTING,
                    NULL);

    dbus_connection_try_register_object_path(libdbusConnection2,
                    "/",
                    &DBusCommunicationTestNamespace::libdbusObjectPathVTable,
                    NULL,
                    NULL);

    std::this_thread::sleep_for(std::chrono::microseconds(1000000));

    EXPECT_EQ(DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER, libdbusStatus);

    //4 Because a short phase of non-availability will be inbetween
    EXPECT_EQ(4u, counter);
    EXPECT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, status);

    //Close connections
    endDispatch = true;
    ASSERT_TRUE(hasEnded.get());
}

#ifndef __NO_MAIN__
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
#endif
