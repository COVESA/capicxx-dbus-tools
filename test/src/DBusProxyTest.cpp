// Copyright (C) 2013-2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef _GLIBCXX_USE_NANOSLEEP
#define _GLIBCXX_USE_NANOSLEEP
#endif

#include <algorithm>
#include <cstdint>
#include <iostream>
#include <string>
#include <thread>
#include <thread>
#include <vector>

#include <gtest/gtest.h>

#include <CommonAPI/CommonAPI.hpp>

#ifndef COMMONAPI_INTERNAL_COMPILATION
#define COMMONAPI_INTERNAL_COMPILATION
#endif

#include <CommonAPI/DBus/DBusInputStream.hpp>
#include <CommonAPI/DBus/DBusMessage.hpp>
#include <CommonAPI/DBus/DBusProxy.hpp>
#include <CommonAPI/DBus/DBusConnection.hpp>
#include <CommonAPI/DBus/DBusStubAdapter.hpp>
#include <CommonAPI/DBus/DBusFactory.hpp>
#include <CommonAPI/DBus/DBusAddress.hpp>
#include <CommonAPI/DBus/DBusAddressTranslator.hpp>

#include <v1/commonapi/tests/TestInterfaceDBusProxy.hpp>
#include <v1/commonapi/tests/TestInterfaceDBusStubAdapter.hpp>
#include <v1/commonapi/tests/TestInterfaceStubDefault.hpp>

#include <v1/commonapi/tests/ExtendedInterfaceProxy.hpp>
#include <v1/commonapi/tests/ExtendedInterfaceDBusProxy.hpp>
#include <v1/commonapi/tests/ExtendedInterfaceDBusStubAdapter.hpp>
#include <v1/commonapi/tests/ExtendedInterfaceStubDefault.hpp>

#include <v1/fake/legacy/service/LegacyInterfaceProxy.hpp>
#include <v1/fake/legacy/service/LegacyInterfaceNoObjectManagerProxy.hpp>

#include "DBusTestUtils.hpp"

static const std::string domain = "local";
static const std::string commonApiAddress = "CommonAPI.DBus.tests.DBusProxyTestService";
static const std::string commonApiAddressExtended = "CommonAPI.DBus.tests.DBusProxyTestService2";
static const std::string commonApiServiceName = "CommonAPI.DBus.tests.DBusProxyTestInterface";
static const std::string interfaceName = "commonapi.tests.TestInterface.v1_0";
static const std::string busName = "commonapi.tests.TestInterface_CommonAPI.DBus.tests.DBusProxyTestService";
static const std::string objectPath = "/CommonAPI/DBus/tests/DBusProxyTestService";
static const std::string objectPathExtended = "/CommonAPI/DBus/tests/DBusProxyTestService2";
static const std::string commonApiAddressFreedesktop = "CommonAPI.DBus.tests.DBusProxyTestInterface";

#define VERSION v1_0

class ProxyTest: public ::testing::Test {

protected:
    void SetUp() {
        runtime_ = CommonAPI::Runtime::get();

        proxyDBusConnection_ = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, "clientConnection");
        ASSERT_TRUE(proxyDBusConnection_->connect());

        proxy_ = std::make_shared<VERSION::commonapi::tests::TestInterfaceDBusProxy>(
            CommonAPI::DBus::DBusAddress(busName, objectPath, interfaceName),
                        proxyDBusConnection_);
        proxy_->init();
    }

    std::shared_ptr<CommonAPI::Runtime> runtime_;

    virtual void TearDown() {
        std::this_thread::sleep_for(std::chrono::microseconds(300000));
    }

    void registerTestStub() {
        stubDefault_ = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
        bool isTestStubAdapterRegistered_ = runtime_->registerService<VERSION::commonapi::tests::TestInterfaceStub>(domain, commonApiAddress, stubDefault_, "serviceConnection");
        ASSERT_TRUE(isTestStubAdapterRegistered_);

        std::this_thread::sleep_for(std::chrono::microseconds(100000));
    }

    void registerExtendedStub() {
        stubExtended_ = std::make_shared<VERSION::commonapi::tests::ExtendedInterfaceStubDefault>();

        bool isExtendedStubAdapterRegistered_ = runtime_->registerService<VERSION::commonapi::tests::ExtendedInterfaceStub>(domain, commonApiAddressExtended, stubExtended_, "serviceConnection");
        ASSERT_TRUE(isExtendedStubAdapterRegistered_);

        std::this_thread::sleep_for(std::chrono::microseconds(100000));
    }

    void deregisterTestStub() {
        const bool isStubAdapterUnregistered = CommonAPI::Runtime::get()->unregisterService(
            domain, stubDefault_->getStubAdapter()->getInterface(), commonApiAddress);
        ASSERT_TRUE(isStubAdapterUnregistered);
        stubDefault_.reset();
        isTestStubAdapterRegistered_ = false;
    }

    void deregisterExtendedStub() {
        const bool isStubAdapterUnregistered = runtime_->unregisterService(
            domain, stubExtended_->CommonAPI::Stub<VERSION::commonapi::tests::ExtendedInterfaceStubAdapter, VERSION::commonapi::tests::ExtendedInterfaceStubRemoteEvent>::getStubAdapter()->VERSION::commonapi::tests::ExtendedInterface::getInterface(), commonApiAddressExtended);
        ASSERT_TRUE(isStubAdapterUnregistered);
        stubExtended_.reset();
        isExtendedStubAdapterRegistered_ = false;
    }

    void proxyRegisterForAvailabilityStatus() {
        proxyAvailabilityStatus_ = CommonAPI::AvailabilityStatus::UNKNOWN;

        proxyStatusSubscription_ = proxy_->getProxyStatusEvent().subscribe([&](const CommonAPI::AvailabilityStatus& availabilityStatus) {
            proxyAvailabilityStatus_ = availabilityStatus;
        });
        std::this_thread::sleep_for(std::chrono::microseconds(100000));
    }

    void proxyDeregisterForAvailabilityStatus() {
        proxy_->getProxyStatusEvent().unsubscribe(proxyStatusSubscription_);
    }

    bool proxyWaitForAvailabilityStatus(const CommonAPI::AvailabilityStatus& availabilityStatus) const {
        for (int i = 0; i < 10; i++) {
            if (proxyAvailabilityStatus_ == availabilityStatus) {
                return true;
            }
            std::this_thread::sleep_for(std::chrono::microseconds(200000));
        }

        return false;
    }

    bool isExtendedStubAdapterRegistered_;
    bool isTestStubAdapterRegistered_;

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyDBusConnection_;
    std::shared_ptr<VERSION::commonapi::tests::TestInterfaceDBusProxy> proxy_;

    CommonAPI::AvailabilityStatus proxyAvailabilityStatus_;

    CommonAPI::ProxyStatusEvent::Subscription proxyStatusSubscription_;

    std::shared_ptr<VERSION::commonapi::tests::ExtendedInterfaceStubDefault> stubExtended_;
    std::shared_ptr<VERSION::commonapi::tests::TestInterfaceStubDefault> stubDefault_;
};

TEST_F(ProxyTest, HasCorrectConnectionName) {
    std::string actualName = proxy_->getDBusAddress().getService();
    EXPECT_EQ(busName, actualName);
}

TEST_F(ProxyTest, HasCorrectObjectPath) {
    std::string actualPath = proxy_->getDBusAddress().getObjectPath();
    EXPECT_EQ(objectPath, actualPath);
}

TEST_F(ProxyTest, HasCorrectInterfaceName) {
    std::string actualName = proxy_->getDBusAddress().getInterface();
    EXPECT_EQ(interfaceName, actualName);
}

TEST_F(ProxyTest, IsNotAvailable) {
    bool isAvailable = proxy_->isAvailable();
    EXPECT_FALSE(isAvailable);
}

TEST_F(ProxyTest, IsConnected) {
    ASSERT_TRUE(proxy_->getDBusConnection()->isConnected());
}

TEST_F(ProxyTest, DBusProxyStatusEventBeforeServiceIsRegistered) {
    proxyRegisterForAvailabilityStatus();

    EXPECT_NE(proxyAvailabilityStatus_, CommonAPI::AvailabilityStatus::AVAILABLE);

    registerTestStub();

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::AVAILABLE));

    deregisterTestStub();
    std::this_thread::sleep_for(std::chrono::microseconds(100000));

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::NOT_AVAILABLE));

    proxyDeregisterForAvailabilityStatus();
}

TEST_F(ProxyTest, DBusProxyStatusEventAfterServiceIsRegistered) {

    registerTestStub();

    proxyRegisterForAvailabilityStatus();

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::AVAILABLE));

    deregisterTestStub();
    std::this_thread::sleep_for(std::chrono::microseconds(100000));

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::NOT_AVAILABLE));

    proxyDeregisterForAvailabilityStatus();
}

TEST_F(ProxyTest, IsAvailableBlocking) {
    registerTestStub();

    // blocking in terms of "if it's still unknown"
    for (int i = 0; !proxy_->isAvailableBlocking() && i < 3; i++) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    EXPECT_TRUE(proxy_->isAvailableBlocking());

    deregisterTestStub();
}

TEST_F(ProxyTest, HasNecessaryAttributesAndEvents) {
    (proxy_->getInterfaceVersionAttribute());
    (proxy_->getProxyStatusEvent());
}

TEST_F(ProxyTest, TestInterfaceVersionAttribute) {
    CommonAPI::InterfaceVersionAttribute& versionAttribute = proxy_->getInterfaceVersionAttribute();
    CommonAPI::Version version;
    CommonAPI::CallStatus status;
    ASSERT_NO_THROW(versionAttribute.getValue(status, version));
    ASSERT_EQ(CommonAPI::CallStatus::NOT_AVAILABLE, status);
}

TEST_F(ProxyTest, AsyncCallbacksAreCalledIfServiceNotAvailable) {
    ::commonapi::tests::DerivedTypeCollection::TestEnumExtended2 testInputStruct;
    ::commonapi::tests::DerivedTypeCollection::TestMap testInputMap;
    CommonAPI::CallInfo info;
    std::promise<bool> wasCalledPromise;
    std::future<bool> wasCalledFuture = wasCalledPromise.get_future();
    proxy_->testDerivedTypeMethodAsync(testInputStruct, testInputMap, [&] (
                    const CommonAPI::CallStatus& callStatus,
                    const ::commonapi::tests::DerivedTypeCollection::TestEnumExtended2&,
                    const ::commonapi::tests::DerivedTypeCollection::TestMap&) {
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::NOT_AVAILABLE);
        wasCalledPromise.set_value(true);
    }
                    , &info);
    ASSERT_TRUE(wasCalledFuture.get());
}


TEST_F(ProxyTest, CallMethodFromExtendedInterface) {
    registerExtendedStub();

    auto extendedProxy = runtime_->buildProxy<VERSION::commonapi::tests::ExtendedInterfaceProxy>(domain, commonApiAddressExtended);

    // give the proxy time to become available
    for (uint32_t i = 0; !extendedProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
    }

    EXPECT_TRUE(extendedProxy->isAvailable());

    uint32_t inInt;
    bool wasCalled = false;
    extendedProxy->TestIntMethodExtendedAsync(
                    inInt,
                    [&](const CommonAPI::CallStatus& callStatus) {
                        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
                        wasCalled = true;
                    });
    std::this_thread::sleep_for(std::chrono::microseconds(100000));

    EXPECT_TRUE(wasCalled);
    deregisterExtendedStub();
}

TEST_F(ProxyTest, CallMethodFromParentInterface) {
    registerExtendedStub();

    auto extendedProxy = runtime_->buildProxy<VERSION::commonapi::tests::ExtendedInterfaceProxy>(domain, commonApiAddressExtended);

    for (uint32_t i = 0; !extendedProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    EXPECT_TRUE(extendedProxy->isAvailable());

    bool wasCalled = false;
    extendedProxy->testEmptyMethodAsync(
                    [&](const CommonAPI::CallStatus& callStatus) {
                        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
                        wasCalled = true;
                    });
    std::this_thread::sleep_for(std::chrono::microseconds(100000));
    EXPECT_TRUE(wasCalled);

    deregisterExtendedStub();
}

TEST_F(ProxyTest, CanHandleRemoteAttribute) {
    registerTestStub();

    for (uint32_t i = 0; !proxy_->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
    }
    ASSERT_TRUE(proxy_->isAvailable());

    CommonAPI::CallStatus callStatus(CommonAPI::CallStatus::REMOTE_ERROR);
    uint32_t value;

    auto& testAttribute = proxy_->getTestPredefinedTypeAttributeAttribute();

    testAttribute.getValue(callStatus, value);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

    value = 7;
    uint32_t responseValue;
    testAttribute.setValue(value, callStatus, responseValue);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(value, responseValue);

    std::this_thread::sleep_for(std::chrono::microseconds(50000));
    deregisterTestStub();
}


TEST_F(ProxyTest, CanHandleRemoteAttributeFromParentInterface) {
    registerExtendedStub();

    auto extendedProxy = runtime_->buildProxy<VERSION::commonapi::tests::ExtendedInterfaceProxy>(domain, commonApiAddressExtended);

    for (uint32_t i = 0; !extendedProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
    }
    ASSERT_TRUE(extendedProxy->isAvailable());

    CommonAPI::CallStatus callStatus(CommonAPI::CallStatus::REMOTE_ERROR);
    uint32_t value;

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    auto& testAttribute = extendedProxy->getTestPredefinedTypeAttributeAttribute();

    testAttribute.getValue(callStatus, value);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

    value = 7;
    uint32_t responseValue;
    testAttribute.setValue(value, callStatus, responseValue);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(value, responseValue);

    std::this_thread::sleep_for(std::chrono::microseconds(50000));
    deregisterExtendedStub();
}

TEST_F(ProxyTest, ProxyCanFetchVersionAttributeFromInheritedInterfaceStub) {
    registerExtendedStub();

    auto extendedProxy = runtime_->buildProxy<VERSION::commonapi::tests::ExtendedInterfaceProxy>(domain, commonApiAddressExtended);

    for (uint32_t i = 0; !extendedProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
    }
    EXPECT_TRUE(extendedProxy->isAvailable());


    CommonAPI::InterfaceVersionAttribute& versionAttribute = extendedProxy->getInterfaceVersionAttribute();

    CommonAPI::Version version;
    bool wasCalled = false;

    std::future<CommonAPI::CallStatus> futureVersion = versionAttribute.getValueAsync([&](const CommonAPI::CallStatus& callStatus, CommonAPI::Version version) {
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_TRUE(version.Major > 0 || version.Minor > 0);
        wasCalled = true;
    });

    futureVersion.wait();
    std::this_thread::sleep_for(std::chrono::microseconds(100000));

    EXPECT_TRUE(wasCalled);

    deregisterExtendedStub();
}

// this test does not build its proxies within SetUp
class ProxyTest2: public ::testing::Test {
protected:
    virtual void SetUp() {
        runtime_ = CommonAPI::Runtime::get();
    }

    virtual void TearDown() {
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
    }

    void registerTestStub(const std::string commonApiAddress) {
        stubDefault_ = std::make_shared<VERSION::commonapi::tests::TestInterfaceStubDefault>();
        bool isTestStubAdapterRegistered_ = runtime_->registerService<
            VERSION::commonapi::tests::TestInterfaceStub>(domain, commonApiAddress, stubDefault_, "serviceConnection");
        ASSERT_TRUE(isTestStubAdapterRegistered_);

        std::this_thread::sleep_for(std::chrono::microseconds(100000));
    }

    void deregisterTestStub(const std::string commonApiAddress) {
        const bool isStubAdapterUnregistered = CommonAPI::Runtime::get()->unregisterService(domain, stubDefault_->getStubAdapter()->getInterface(), commonApiAddress);
        ASSERT_TRUE(isStubAdapterUnregistered);
        stubDefault_.reset();
        isTestStubAdapterRegistered_ = false;
    }

    void proxyRegisterForAvailabilityStatus() {
        proxyAvailabilityStatus_ = CommonAPI::AvailabilityStatus::UNKNOWN;

        proxyStatusSubscription_ = proxy_->getProxyStatusEvent().subscribe(
                        [&](const CommonAPI::AvailabilityStatus& availabilityStatus) {
                            proxyAvailabilityStatus_ = availabilityStatus;
                        });
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    void proxyDeregisterForAvailabilityStatus() {
        proxy_->getProxyStatusEvent().unsubscribe(proxyStatusSubscription_);
    }

    bool proxyWaitForAvailabilityStatus(const CommonAPI::AvailabilityStatus& availabilityStatus) const {
        for (int i = 0; i < 100; i++) {
            if (proxyAvailabilityStatus_ == availabilityStatus)
                return true;
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        return false;
    }

    bool isTestStubAdapterRegistered_;
    std::shared_ptr<CommonAPI::Runtime> runtime_;

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyDBusConnection_;
    std::shared_ptr<VERSION::commonapi::tests::TestInterfaceDBusProxy> proxy_;
    CommonAPI::AvailabilityStatus proxyAvailabilityStatus_;

    CommonAPI::ProxyStatusEvent::Subscription proxyStatusSubscription_;

    std::shared_ptr<VERSION::commonapi::tests::TestInterfaceStubDefault> stubDefault_;
};

TEST_F(ProxyTest2, DBusProxyStatusEventAfterServiceIsRegistered) {
    registerTestStub(commonApiAddress);

    proxyDBusConnection_ = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, "clientConnection");
    ASSERT_TRUE(proxyDBusConnection_->connect());

    proxy_ = std::make_shared<VERSION::commonapi::tests::TestInterfaceDBusProxy>(CommonAPI::DBus::DBusAddress(busName, objectPath, interfaceName), proxyDBusConnection_);
    proxy_->init();

    proxyRegisterForAvailabilityStatus();

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::AVAILABLE));

    deregisterTestStub(commonApiAddress);
    std::this_thread::sleep_for(std::chrono::microseconds(100000));

    EXPECT_TRUE(proxyWaitForAvailabilityStatus(CommonAPI::AvailabilityStatus::NOT_AVAILABLE));

    proxyDeregisterForAvailabilityStatus();
}

TEST_F(ProxyTest2, DBusProxyCanUseOrgFreedesktopAddress) {
    registerTestStub(commonApiAddressFreedesktop);

    std::shared_ptr<VERSION::commonapi::tests::TestInterfaceProxy<>> proxy =
        runtime_->buildProxy<VERSION::commonapi::tests::TestInterfaceProxy>(domain, commonApiAddressFreedesktop);

    for (int i = 0; i < 100; i++) {
        if (proxy->isAvailable())
            break;
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    const bool proxyIsAvailable = proxy->isAvailable();

    EXPECT_TRUE(proxyIsAvailable);

    if(proxyIsAvailable) { // if we are not available, we failed the test and do not check a method call
        bool wasCalled = false;
        proxy->testEmptyMethodAsync(
                        [&](const CommonAPI::CallStatus& callStatus) {
                            ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
                            wasCalled = true;
                        });
        std::this_thread::sleep_for(std::chrono::microseconds(100000));
        EXPECT_TRUE(wasCalled);
    }

    deregisterTestStub(commonApiAddressFreedesktop);
}

static const std::string fakeLegacyServiceInstance = "fake.legacy.service";

class ProxyTestCreateAndDeleteFakeLegacyService: public ::testing::Test {
public:

    template<template<typename ...> class Proxy_>
    class TestHelper {
    public:

        void startFakeLegacyServices(const bool _withObjectManager = false) {
            for(uint32_t i = 1; i <= services_; i++) {
                CommonAPI::Address capiAddress("domain", Proxy_<>::getInterface(), fakeLegacyServiceInstance + std::to_string(i));
                auto addressTranslator = CommonAPI::DBus::DBusAddressTranslator::get();
                CommonAPI::DBus::DBusAddress dbusAddress;
                addressTranslator->translate(capiAddress, dbusAddress);

                fakeLegacyServices_.push_back(dbusAddress);
                if(_withObjectManager) {
                    startFakeLegacyServiceWithObjectMananger(dbusAddress);
                } else {
                    startFakeLegacyServiceNoObjectMananger(dbusAddress);
                }
            }
        }

        void createAndDeleteProxies() {

            std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
            ASSERT_TRUE((bool)runtime);

            // create dummy proxy to avoid destruction of DBusConnection and DBusServiceRegistry
            dummyProxy = runtime->buildProxy<Proxy_>(domain, fakeLegacyServiceInstance + std::to_string(services_));

            for (uint32_t i = 0; !dummyProxy->isAvailable() && i < 200; ++i) {
                std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
            }
            ASSERT_TRUE(dummyProxy->isAvailable());

            // create proxy for each service
            // only a certain number of proxies can be connected simultaneously ('maxConnectedProxies')
            for(uint32_t i = 1; i <= services_;) {
                for(auto it = connectedProxies_.begin(); it != connectedProxies_.end();) {
                    it = connectedProxies_.erase(it);
                }
                for(uint32_t j = i; j < i + maxConnectedProxies_; j++) {
                    auto proxy = runtime->buildProxy<Proxy_>(domain, fakeLegacyServiceInstance + std::to_string(j));
                    ASSERT_TRUE((bool)proxy);
                    connectedProxies_.push_back(proxy);
                }
                i += maxConnectedProxies_;
            }

            // create proxy for each service in reverse order
            for(uint32_t i = services_; i >= 1;) {
                for(auto it = connectedProxies_.begin(); it != connectedProxies_.end();) {
                    it = connectedProxies_.erase(it);
                }
                for(uint32_t j = i; j > i - maxConnectedProxies_; j--) {
                    auto proxy = runtime->buildProxy<Proxy_>(domain, fakeLegacyServiceInstance + std::to_string(j));
                    ASSERT_TRUE((bool)proxy);
                    connectedProxies_.push_back(proxy);
                }
                i -= maxConnectedProxies_;
            }
        }

        void checkAvailability() {
            // check if the last built proxies are available
            for(const auto &it : connectedProxies_) {
                for (uint32_t i = 0; !it->isAvailable() && i < 200; ++i) {
                    std::this_thread::sleep_for(std::chrono::microseconds(20 * 1000));
                }
                EXPECT_TRUE(it->isAvailable());
            }
        }

        void unregisterFakeLegacyServices() {
            // unregister fake legacy services
            for(const auto &it : fakeLegacyServices_) {
                CommonAPI::DBus::DBusAddress dbusAddress = it;
                callPythonService("sendToFakeLegacyService.py finish " + dbusAddress.getService() + " " + dbusAddress.getObjectPath() + " " + dbusAddress.getInterface());
            }
        }

    protected:

        void startFakeLegacyServiceWithObjectMananger(const CommonAPI::DBus::DBusAddress& _dbusAddress) {
            callPythonService("fakeLegacyService.py " + _dbusAddress.getService() + " " + _dbusAddress.getObjectPath() + " " + _dbusAddress.getInterface() + " --withObjectManager");
        }

        void startFakeLegacyServiceNoObjectMananger(const CommonAPI::DBus::DBusAddress& _dbusAddress) {
            callPythonService("fakeLegacyService.py " + _dbusAddress.getService() + " " + _dbusAddress.getObjectPath() + " " + _dbusAddress.getInterface());
        }

        void callPythonService(const std::string& _pythonFileNameAndCommand) {
            const char *pathToFolderForFakeLegacyService =
                    getenv("TEST_COMMONAPI_DBUS_FAKE_LEGACY_SERVICE_FOLDER");

            ASSERT_NE(pathToFolderForFakeLegacyService, nullptr) << "Environment variable "
                    "TEST_COMMONAPI_DBUS_FAKE_LEGACY_SERVICE_FOLDER "
                    "is not set!";

            std::stringstream stream;
            stream << "python3 " << pathToFolderForFakeLegacyService << "/" << _pythonFileNameAndCommand + " &";

            int resultCode = system(stream.str().c_str());
            EXPECT_EQ(0, resultCode);
        }

        const uint32_t services_ = 10;
        const uint32_t maxConnectedProxies_ = 5;

        std::vector<CommonAPI::DBus::DBusAddress> fakeLegacyServices_;
        std::vector<std::shared_ptr<Proxy_<>>> connectedProxies_;

        // dummy proxy to avoid destruction of DBusConnection and DBusServiceRegistry
        std::shared_ptr<Proxy_<>> dummyProxy;
    };

protected:
    void SetUp() {
        runtime_ = CommonAPI::Runtime::get();

        proxyDBusConnection_ = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, "clientConnection");
        ASSERT_TRUE(proxyDBusConnection_->connect());
    }

    std::shared_ptr<CommonAPI::Runtime> runtime_;

    virtual void TearDown() {
        std::this_thread::sleep_for(std::chrono::microseconds(300000));
    }

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyDBusConnection_;
};

TEST_F(ProxyTestCreateAndDeleteFakeLegacyService, DBusProxiesAvailableForFakeLegacyServicesWithObjectManager) {
    TestHelper<VERSION::fake::legacy::service::LegacyInterfaceProxy> helper;

    helper.startFakeLegacyServices(true);
    helper.createAndDeleteProxies();
    helper.checkAvailability();
    helper.unregisterFakeLegacyServices();
}

TEST_F(ProxyTestCreateAndDeleteFakeLegacyService, DBusProxiesAvailableForFakeLegacyServicesNoObjectManager) {
    TestHelper<VERSION::fake::legacy::service::LegacyInterfaceNoObjectManagerProxy> helper;

    helper.startFakeLegacyServices();
    helper.createAndDeleteProxies();
    helper.checkAvailability();
    helper.unregisterFakeLegacyServices();
}

#ifndef __NO_MAIN__
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
#endif
