// Copyright (C) 2013-2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef _GLIBCXX_USE_NANOSLEEP
#define _GLIBCXX_USE_NANOSLEEP
#endif

#include <CommonAPI/CommonAPI.hpp>

#define COMMONAPI_INTERNAL_COMPILATION
#include <CommonAPI/DBus/DBusObjectManagerStub.hpp>
#include <CommonAPI/DBus/DBusConnection.hpp>
#include <CommonAPI/DBus/DBusInputStream.hpp>
#include <CommonAPI/DBus/DBusFactory.hpp>
#include <CommonAPI/DBus/DBusStubAdapter.hpp>

#include <CommonAPI/ProxyManager.hpp>

#include "v1/commonapi/tests/managed/RootInterfaceStubDefault.hpp"
#include "v1/commonapi/tests/managed/LeafInterfaceStubDefault.hpp"
#include "v1/commonapi/tests/managed/BranchInterfaceStubDefault.hpp"
#include "v1/commonapi/tests/managed/SecondRootStubDefault.hpp"

#include "v1/commonapi/tests/managed/RootInterfaceProxy.hpp"
#include "v1/commonapi/tests/managed/RootInterfaceDBusProxy.hpp"
#include "v1/commonapi/tests/managed/LeafInterfaceProxy.hpp"

#include "v1/commonapi/tests/managed/RootInterfaceDBusStubAdapter.hpp"
#include "v1/commonapi/tests/managed/LeafInterfaceDBusStubAdapter.hpp"

#include <gtest/gtest.h>
#include <algorithm>
#include <array>
#include <memory>

#include <pugixml/pugixml.hpp>

#define VERSION v1_0

static const std::string serviceConnectionId = "managed-test-service";
static const std::string clientConnectionId = "managed-test-client";
static const std::string clientConnectionId2 = "managed-test-client2";;

static const std::string domain = "local";

static const std::string instanceNameBase = "commonapi.tests.managed";
static const std::string objectPathBase = "/commonapi/tests/managed";

//Root
static const std::string rootDbusInterfaceName = "commonapi.tests.managed.RootInterface.v1_0";
static const std::string rootCapiInterfaceName = "commonapi.tests.managed.RootInterface:v1_0";

static const std::string rootInstanceName =  instanceNameBase + ".RootInterface";
static const std::string rootDbusServiceName = rootDbusInterfaceName + "_" + rootInstanceName;
static const std::string rootDbusObjectPath = objectPathBase + "/RootInterface";

//SecondRoot
static const std::string secondRootDbusInterfaceName = "commonapi.tests.managed.SecondRoot.v1_0";
static const std::string secondRootInstanceName = instanceNameBase + ".SecondRoot";
static const std::string secondRootDbusServiceName = secondRootDbusInterfaceName + "_" + secondRootInstanceName;
static const std::string secondRootDbusObjectPath = objectPathBase + "/SecondRoot";

//Leaf
static const std::string leafDbusInterfaceName = "commonapi.tests.managed.LeafInterface.v1_0";

//Leaf based on Root
static const std::string leafInstanceNameRoot =  rootInstanceName + ".LeafInterface";
static const std::string leafDbusServiceNameRoot = leafDbusInterfaceName + "_" + leafInstanceNameRoot;
static const std::string leafDbusObjectPathRoot = rootDbusObjectPath + "/LeafInterface";

//Leaf based on SecondRoot
static const std::string leafInstanceNameSecondRoot = secondRootInstanceName + ".LeafInterface";
static const std::string leafDbusObjectPathSecondRoot = secondRootDbusObjectPath + "/LeafInterface";

//Branch
static const std::string branchDbusInterfaceName = "commonapi.tests.managed.BranchInterface.v1_0";
static const std::string branchInstanceNameRoot = rootInstanceName + ".BranchInterface";
static const std::string branchDbusServiceNameRoot = branchDbusInterfaceName + "_" + branchInstanceNameRoot;
static const std::string branchDbusObjectPathRoot = rootDbusObjectPath + "/BranchInterface";

class DBusManagedTest: public ::testing::Test {
protected:
    virtual void SetUp() {
        leafStatus_ = CommonAPI::AvailabilityStatus::UNKNOWN;
        runtime_ = CommonAPI::Runtime::get();

        manualDBusConnection_ = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, "manualConnection");
        ASSERT_TRUE(manualDBusConnection_->connect(false));
    }

    virtual void TearDown() {
        manualDBusConnection_->disconnect();
        manualDBusConnection_.reset();
    }

    const CommonAPI::DBus::DBusObjectManagerStub::DBusObjectPathAndInterfacesDict getManagedObjects(const std::string& _dbusServiceName,
                                                                                                const std::string& _dbusObjectPath,
                                                                                                std::shared_ptr<CommonAPI::DBus::DBusConnection> _connection) {
        auto dbusMessageCall = CommonAPI::DBus::DBusMessage::createMethodCall(
                        CommonAPI::DBus::DBusAddress(_dbusServiceName, _dbusObjectPath, CommonAPI::DBus::DBusObjectManagerStub::getInterfaceName()),
                        "GetManagedObjects");

        CommonAPI::DBus::DBusError dbusError;
        CommonAPI::CallInfo info(1000);
        auto dbusMessageReply = _connection->sendDBusMessageWithReplyAndBlock(dbusMessageCall, dbusError, &info);

        CommonAPI::DBus::DBusObjectManagerStub::DBusObjectPathAndInterfacesDict dbusObjectPathAndInterfacesDict;
        if(!dbusMessageReply)
            return dbusObjectPathAndInterfacesDict;

        CommonAPI::DBus::DBusInputStream dbusInputStream(dbusMessageReply);

        dbusInputStream >> dbusObjectPathAndInterfacesDict;

        return dbusObjectPathAndInterfacesDict;
    }

    bool isManaged(const std::string& _dbusObjectPath,
                   const std::string& _dbusInterfaceName,
                   CommonAPI::DBus::DBusObjectManagerStub::DBusObjectPathAndInterfacesDict& dbusObjectPathAndInterfacesDict)
    {
        for(auto dbusObjectPathDict : dbusObjectPathAndInterfacesDict)
        {
            std::string dbusObjectPath = dbusObjectPathDict.first;
            if(dbusObjectPath != _dbusObjectPath)
                continue;
            CommonAPI::DBus::DBusObjectManagerStub::DBusInterfacesAndPropertiesDict dbusInterfacesAndPropertiesDict = dbusObjectPathDict.second;
            for(auto dbusInterfaceDict : dbusInterfacesAndPropertiesDict)
            {
                std::string dbusInterfaceName = dbusInterfaceDict.first;
                if(dbusInterfaceName == _dbusInterfaceName)
                    return true;
            }
        }
        return false;
    }

    const std::string getIntrospection(const std::string& _dbusServiceName,
                                       const std::string& _dbusObjectPath,
                                       std::shared_ptr<CommonAPI::DBus::DBusConnection> _connection) {
        std::string introspection = "";
        auto dbusMessageCall = CommonAPI::DBus::DBusMessage::createMethodCall(
            CommonAPI::DBus::DBusAddress(_dbusServiceName, _dbusObjectPath, "org.freedesktop.DBus.Introspectable"),
            "Introspect");

        CommonAPI::DBus::DBusError dbusError;
        CommonAPI::CallInfo info(1000);
        auto dbusMessageReply = _connection->sendDBusMessageWithReplyAndBlock(dbusMessageCall, dbusError, &info);

        if(!dbusMessageReply || dbusMessageReply.isErrorType())
            return introspection;

        CommonAPI::DBus::DBusInputStream dbusInputStream(dbusMessageReply);

        dbusInputStream >> introspection;

        return introspection;
    }

    bool introspectionContains(const std::string& _dbusObjectPath,
                               const std::string& _dbusInterfaceName,
                               const std::string& _introspection) {
        pugi::xml_document xmlDocument;
        pugi::xml_parse_result parsedResult = xmlDocument.load_buffer(_introspection.c_str(), _introspection.length(), pugi::parse_minimal, pugi::encoding_utf8);

        if(_introspection == "" || parsedResult.status != pugi::xml_parse_status::status_ok) {
            return false;
        }

        const pugi::xml_node rootNode = xmlDocument.child("node");

        bool objectPathFound, interfaceFound;
        parseIntrospectionNode(rootNode, _dbusObjectPath, _dbusInterfaceName, objectPathFound, interfaceFound);

        return (objectPathFound && interfaceFound);
    }

    std::shared_ptr<CommonAPI::Runtime> runtime_;
    std::shared_ptr<CommonAPI::DBus::DBusConnection> manualDBusConnection_;
    CommonAPI::AvailabilityStatus leafStatus_;

public:
    void managedObjectSignalled(std::string address, CommonAPI::AvailabilityStatus status) {
        (void)address;
        leafStatus_ = status;
    }

private:

    void parseIntrospectionObjectPath(const pugi::xml_node& _node,
                                      const std::string& _dbusObjectPath,
                                      const std::string& _dbusInterfaceName,
                                      bool& _objectPathFound,
                                      bool& _interfaceFound) {
        std::string dbusObjectPath = std::string(_node.attribute("name").as_string());
        if(dbusObjectPath == _dbusObjectPath) {
            _objectPathFound = true;
        }
        for(pugi::xml_node subNode : _node.children()) {
            parseIntrospectionNode(subNode,
                                   _dbusObjectPath,
                                   _dbusInterfaceName,
                                   _objectPathFound,
                                   _interfaceFound);
        }
    }

    void parseIntrospectionInterface(const pugi::xml_node& _node,
                                     const std::string& _dbusObjectPath,
                                     const std::string& _dbusInterfaceName,
                                     bool& _objectPathFound,
                                     bool& _interfaceFound) {
        std::string dbusInterfaceName = _node.attribute("name").as_string();
        if(dbusInterfaceName == _dbusInterfaceName) {
            _interfaceFound = true;
        }
        for(pugi::xml_node subNode : _node.children()) {
            parseIntrospectionNode(subNode,
                                   _dbusObjectPath,
                                   _dbusInterfaceName,
                                   _objectPathFound,
                                   _interfaceFound);
        }
    }

    void parseIntrospectionNode(const pugi::xml_node& _node,
                                const std::string& _dbusObjectPath,
                                const std::string& _dbusInterfaceName,
                                bool& _objectPathFound,
                                bool& _interfaceFound) {
        std::string nodeName = std::string(_node.name());
        if(nodeName == "node") {
            std::string dbusObjectPath = std::string(_node.attribute("name").as_string());
            if(dbusObjectPath == _dbusObjectPath) {
                _objectPathFound = true;
            }
        } else if(nodeName == "interface") {
            std::string dbusInterfaceName = _node.attribute("name").as_string();
            if(dbusInterfaceName == _dbusInterfaceName) {
                _interfaceFound = true;
            }
        }

        for(pugi::xml_node& subNode : _node.children()) {
            parseIntrospectionNode(subNode,
                                   _dbusObjectPath,
                                   _dbusInterfaceName,
                                   _objectPathFound,
                                   _interfaceFound);
        }
    }
};

TEST_F(DBusManagedTest, RegisterRoot) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTest, RegisterLeafUnmanaged) {
    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, leafInstanceNameRoot, leafStub, serviceConnectionId));

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that leaf is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceNameRoot,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::LeafInterfaceStubDefault::StubInterface::getInterface(), leafInstanceNameRoot);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that leaf is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceNameRoot,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTest, RegisterLeafManaged) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager& proxyManagerLeafInterface = rootProxy->getProxyManagerLeafInterface();
    proxyManagerLeafInterface.getInstanceAvailabilityStatusChangedEvent().subscribe(
                    std::bind(&DBusManagedTest::managedObjectSignalled,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    ASSERT_TRUE(rootStub->deregisterManagedStubLeafInterface(leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTest, RegisterLeafManagedAndCreateProxyForLeaf) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName , rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager& proxyManagerLeafInterface = rootProxy->getProxyManagerLeafInterface();
    proxyManagerLeafInterface.getInstanceAvailabilityStatusChangedEvent().subscribe(
                    std::bind(&DBusManagedTest::managedObjectSignalled,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto leafProxy = proxyManagerLeafInterface.buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(leafInstanceNameRoot);
    for (uint32_t i = 0; !leafProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }

    ASSERT_TRUE(leafProxy->isAvailable());

    CommonAPI::CallStatus callStatus;
    VERSION::commonapi::tests::managed::LeafInterface::testLeafMethodError error;
    int outInt;
    std::string outString;
    leafProxy->testLeafMethod(42, "Test", callStatus, error, outInt, outString);

    ASSERT_TRUE(callStatus == CommonAPI::CallStatus::SUCCESS);

    ASSERT_TRUE(rootStub->deregisterManagedStubLeafInterface(leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    ASSERT_TRUE(runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName));

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTest, RegisterLeafManagedAndCreateProxyForLeafInAvailabilityEvent) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName , rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    std::condition_variable proxyCondVar;
    bool proxyCallsSuccessful = false;

    CommonAPI::ProxyManager& proxyManagerLeafInterface = rootProxy->getProxyManagerLeafInterface();
    proxyManagerLeafInterface.getInstanceAvailabilityStatusChangedEvent().subscribe(
            [&](const std::string instanceName, CommonAPI::AvailabilityStatus availabilityStatus) {
    (void)instanceName;

        if(availabilityStatus == CommonAPI::AvailabilityStatus::AVAILABLE) {
            leafStatus_ = CommonAPI::AvailabilityStatus::AVAILABLE;

            //another connection must be used
            auto leafProxy = proxyManagerLeafInterface.buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(leafInstanceNameRoot, clientConnectionId2);
            for (uint32_t i = 0; !leafProxy->isAvailable() && i < 200; ++i) {
                std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
            }

            ASSERT_TRUE(leafProxy->isAvailable());

            CommonAPI::CallStatus callStatus;
            VERSION::commonapi::tests::managed::LeafInterface::testLeafMethodError error;
            int outInt;
            std::string outString;
            leafProxy->testLeafMethod(42, "Test", callStatus, error, outInt, outString);

            ASSERT_TRUE(callStatus == CommonAPI::CallStatus::SUCCESS);

            proxyCallsSuccessful = true;
            proxyCondVar.notify_one();

        } else if(availabilityStatus == CommonAPI::AvailabilityStatus::NOT_AVAILABLE) {
            leafStatus_ = CommonAPI::AvailabilityStatus::NOT_AVAILABLE;
        }
    });

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    std::mutex m;
    std::unique_lock<std::mutex> lock(m);
    std::chrono::milliseconds timeout(2000);

    if(!proxyCallsSuccessful)
        proxyCondVar.wait_for(lock, timeout);
    ASSERT_TRUE(proxyCallsSuccessful);

    ASSERT_TRUE(rootStub->deregisterManagedStubLeafInterface(leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    ASSERT_TRUE(runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName));

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();

}

TEST_F(DBusManagedTest, RegisterLeafManagedAndCreateProxyForLeafInAvailabilityEventCallMethodInProxyStatusEvent) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName , rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    std::condition_variable proxyCondVar;
    bool proxyCallsSuccessful = false;

    std::shared_ptr<VERSION::commonapi::tests::managed::LeafInterfaceProxy<>> leafProxy;

    CommonAPI::ProxyManager& proxyManagerLeafInterface = rootProxy->getProxyManagerLeafInterface();
    proxyManagerLeafInterface.getInstanceAvailabilityStatusChangedEvent().subscribe(
            [&](const std::string instanceName, CommonAPI::AvailabilityStatus availabilityStatus) {

        (void)instanceName;

        if(availabilityStatus == CommonAPI::AvailabilityStatus::AVAILABLE) {
            leafStatus_ = CommonAPI::AvailabilityStatus::AVAILABLE;

            //same connection can be used
            leafProxy = proxyManagerLeafInterface.buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(leafInstanceNameRoot, clientConnectionId);
            leafProxy->getProxyStatusEvent().subscribe([&] (const CommonAPI::AvailabilityStatus status) {
                if(status == CommonAPI::AvailabilityStatus::AVAILABLE) {

                    CommonAPI::CallStatus callStatus;
                    VERSION::commonapi::tests::managed::LeafInterface::testLeafMethodError error;
                    int outInt;
                    std::string outString;
                    leafProxy->testLeafMethod(42, "Test", callStatus, error, outInt, outString);

                    ASSERT_TRUE(callStatus == CommonAPI::CallStatus::SUCCESS);

                    proxyCallsSuccessful = true;
                    proxyCondVar.notify_one();

                }
            });
        } else if(availabilityStatus == CommonAPI::AvailabilityStatus::NOT_AVAILABLE) {
            leafStatus_ = CommonAPI::AvailabilityStatus::NOT_AVAILABLE;
            proxyCallsSuccessful = false;
            leafProxy.reset();
        }
    });

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    std::mutex m;
    std::unique_lock<std::mutex> lock(m);
    std::chrono::milliseconds timeout(2000);

    if(!proxyCallsSuccessful)
        proxyCondVar.wait_for(lock, timeout);
    ASSERT_TRUE(proxyCallsSuccessful);

    ASSERT_TRUE(rootStub->deregisterManagedStubLeafInterface(leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //register leaf again
    leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    if(!proxyCallsSuccessful)
        proxyCondVar.wait_for(lock, timeout);
    ASSERT_TRUE(proxyCallsSuccessful);

    ASSERT_TRUE(rootStub->deregisterManagedStubLeafInterface(leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    ASSERT_TRUE(runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName));

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTest, PropagateTeardown) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager& proxyManagerLeafInterface = rootProxy->getProxyManagerLeafInterface();
    proxyManagerLeafInterface.getInstanceAvailabilityStatusChangedEvent().subscribe(
                    std::bind(&DBusManagedTest::managedObjectSignalled,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::AVAILABLE);

    //check that leaf is in introspection
    ASSERT_TRUE(introspectionContains(leafDbusObjectPathRoot,
                                      leafDbusInterfaceName,
                                      getIntrospection(leafDbusServiceNameRoot,
                                                       leafDbusObjectPathRoot,
                                                       manualDBusConnection_)));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto leafProxy = proxyManagerLeafInterface.buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(leafInstanceNameRoot);

    for (uint32_t i = 0; !leafProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }

    ASSERT_TRUE(leafProxy->isAvailable());

    CommonAPI::CallStatus callStatus;
    VERSION::commonapi::tests::managed::LeafInterface::testLeafMethodError error;
    int outInt;
    std::string outString;
    leafProxy->testLeafMethod(42, "Test", callStatus, error, outInt, outString);

    ASSERT_TRUE(callStatus == CommonAPI::CallStatus::SUCCESS);

    rootStub->getStubAdapter()->deactivateManagedInstances();

    for (uint32_t i = 0; leafStatus_ != CommonAPI::AvailabilityStatus::NOT_AVAILABLE && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(leafStatus_ == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that root is still in introspection
    ASSERT_TRUE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that leaf is not in introspection
    ASSERT_FALSE(introspectionContains(leafDbusObjectPathRoot,
                                       leafDbusInterfaceName,
                                       getIntrospection(leafDbusServiceNameRoot,
                                                        leafDbusObjectPathRoot,
                                                        manualDBusConnection_)));

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root is still registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is not in introspection
    ASSERT_FALSE(introspectionContains(rootDbusObjectPath,
                                      rootDbusInterfaceName,
                                      getIntrospection(rootDbusServiceName,
                                                       rootDbusObjectPath,
                                                       manualDBusConnection_)));

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

class DBusManagedTestExtended: public DBusManagedTest {
protected:
    virtual void SetUp() {
        runtime_ = CommonAPI::Runtime::get();

        leafInstanceAvailability = CommonAPI::AvailabilityStatus::UNKNOWN;
        branchInstanceAvailability = CommonAPI::AvailabilityStatus::UNKNOWN;

        manualDBusConnection_ = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, "manualConnection");
        ASSERT_TRUE(manualDBusConnection_->connect(false));
    }

    virtual void TearDown() {
        manualDBusConnection_->disconnect();
        manualDBusConnection_.reset();
    }

    inline const std::string getSuffixedRootInstanceName(const std::string& suffix) {
        return rootInstanceName + suffix;
    }

    inline bool registerRootStubForSuffix(const std::string& suffix) {
        auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
        const std::string instanceName = getSuffixedRootInstanceName(suffix);
        bool registered = runtime_->registerService(domain, instanceName, rootStub, serviceConnectionId);

        if(registered)
            rootStubs_.insert( { instanceName, rootStub });

        return registered;
    }

    inline bool unregisterRootForSuffix(const std::string& suffix) {
        const std::string instanceName = getSuffixedRootInstanceName(suffix);

        std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceStubDefault> rootStub = rootStubs_.find(instanceName)->second;
        rootStub->getStubAdapter()->deactivateManagedInstances();

        bool unregistered = runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), instanceName);

        if(unregistered)
            rootStubs_.erase(instanceName);

        return unregistered;
    }

    inline void createRootProxyForSuffix(const std::string& suffix) {
        CommonAPI::DBus::DBusAddress rootDBusAddress;
        CommonAPI::Address rootCommonAPIAddress(domain, rootCapiInterfaceName, getSuffixedRootInstanceName(suffix));
        CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

        std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
        proxyConnection->connect();

        std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
            VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                        rootDBusAddress,
                        proxyConnection
                        );
        rootProxy->init();
        rootProxies_.push_back(rootProxy);
        rootProxy->isAvailable();
    }

    template<typename _ProxyType>
    bool waitForAllProxiesToBeAvailable(const std::vector<_ProxyType>& dbusProxies) {
        bool allAreAvailable = false;
        for (size_t i = 0; i < 500 && !allAreAvailable; i++) {
            allAreAvailable = std::all_of(dbusProxies.begin(),
                                          dbusProxies.end(),
                                          [](const _ProxyType& proxy) {
                                              return proxy->isAvailable();
                                          });
            std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
        }
        return allAreAvailable;
    }

    bool registerXLeafStubsForAllRoots(uint32_t x) {
        bool success = true;
        bool expectedValueForRegistration = true;
        for (auto rootStubIterator: rootStubs_) {
            for (uint32_t i = 0; i < x; i++) {
                std::shared_ptr<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault> leafStub = std::make_shared<
                    VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
                bool s = rootStubIterator.second->registerManagedStubLeafInterfaceAutoInstance(leafStub);
                success &= (s == expectedValueForRegistration);
            }
            expectedValueForRegistration = true;
        }
        return success;
    }

    void createXLeafProxiesForAllExistingLeafs() {
        for (auto rootProxyIterator : rootProxies_) {
            std::vector<std::shared_ptr<VERSION::commonapi::tests::managed::LeafInterfaceProxyDefault>> leafProxiesForRootX;

            CommonAPI::ProxyManager& leafProxyManager = rootProxyIterator->getProxyManagerLeafInterface();
            std::vector<std::string> availableInstances;
            CommonAPI::CallStatus status;
            leafProxyManager.getAvailableInstances(status, availableInstances);

            for (const std::string& availableInstance : availableInstances) {
                auto newLeafProxy = leafProxyManager.buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(availableInstance);
                leafProxiesForRootX.push_back(newLeafProxy);
            }
            leafProxies_.push_back(std::move(leafProxiesForRootX));
         }
    }

    std::unordered_map<std::string, std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>> rootStubs_;
    std::vector<std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>> rootProxies_;
    std::vector<std::vector<std::shared_ptr<VERSION::commonapi::tests::managed::LeafInterfaceProxyDefault>>> leafProxies_;

    CommonAPI::AvailabilityStatus leafInstanceAvailability;
    CommonAPI::AvailabilityStatus branchInstanceAvailability;
public:
    void onLeafInstanceAvailabilityStatusChanged(const std::string instanceName, CommonAPI::AvailabilityStatus availabilityStatus) {
        (void)instanceName;
        leafInstanceAvailability = availabilityStatus;
    }

    void onBranchInstanceAvailabilityStatusChanged(const std::string instanceName, CommonAPI::AvailabilityStatus availabilityStatus) {
        (void)instanceName;
        branchInstanceAvailability = availabilityStatus;
    }
};

TEST_F(DBusManagedTestExtended, RegisterSeveralRootsOnSameObjectPath) {

    /* set environment variable (default config: commonapi-dbus.ini) to
     * to register the roots on the same object path
     */
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    ASSERT_TRUE(registerRootStubForSuffix("One"));
    ASSERT_TRUE(registerRootStubForSuffix("Two"));
    ASSERT_TRUE(registerRootStubForSuffix("Three"));

    const std::string dbusServiceNameBase = "commonapi.tests.managed.roots.on.same.object.path.RootInterface";
    //check that root one is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root two is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root three is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    ASSERT_TRUE(unregisterRootForSuffix("One"));
    ASSERT_TRUE(unregisterRootForSuffix("Two"));
    ASSERT_TRUE(unregisterRootForSuffix("Three"));

    //check that root one is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root two is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root three is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

}

TEST_F(DBusManagedTestExtended, RegisterSeveralRootsOnSameObjectPathAndCommunicate) {

    /* set environment variable (default config: commonapi-dbus.ini) to
     * to register the roots on the same object path
     */
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    ASSERT_TRUE(registerRootStubForSuffix("One"));
    ASSERT_TRUE(registerRootStubForSuffix("Two"));
    ASSERT_TRUE(registerRootStubForSuffix("Three"));

    const std::string dbusServiceNameBase = "commonapi.tests.managed.roots.on.same.object.path.RootInterface";

    //check that root one is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root two is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root three is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    createRootProxyForSuffix("One");
    createRootProxyForSuffix("Two");
    createRootProxyForSuffix("Three");

    bool allRootProxiesAreAvailable = waitForAllProxiesToBeAvailable(rootProxies_);
    ASSERT_TRUE(allRootProxiesAreAvailable);

    CommonAPI::CallStatus callStatus;
    CommonAPI::CallInfo *info = NULL;
    VERSION::commonapi::tests::managed::RootInterface::testRootMethodError applicationError;
    int32_t outInt;
    std::string outString;

    for (size_t i = 0; i < rootProxies_.size(); ++i) {
        rootProxies_[i]->testRootMethod(-5,
                                        std::string("More Cars"),
                                        callStatus,
                                        applicationError,
                                        outInt,
                                        outString,
                                        info);
        ASSERT_EQ(CommonAPI::CallStatus::SUCCESS, callStatus);
    }

    ASSERT_TRUE(unregisterRootForSuffix("One"));
    ASSERT_TRUE(unregisterRootForSuffix("Two"));
    ASSERT_TRUE(unregisterRootForSuffix("Three"));

    //check that root one is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root two is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root three is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    rootProxies_.clear();
}

TEST_F(DBusManagedTestExtended, RegisterSeveralRootsAndSeveralLeafsForEachOnSameObjectPath) {

    /* set environment variable (default config: commonapi-dbus.ini) to
     * to register the roots on the same object path
     */
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    ASSERT_TRUE(registerRootStubForSuffix("One"));
    ASSERT_TRUE(registerRootStubForSuffix("Two"));
    ASSERT_TRUE(registerRootStubForSuffix("Three"));

    const std::string dbusServiceNameBase = "commonapi.tests.managed.roots.on.same.object.path.RootInterface";

    //check that root one is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root two is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that root three is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    bool allLeafStubsWereRegistered = registerXLeafStubsForAllRoots(5);
    ASSERT_TRUE(allLeafStubsWereRegistered);

    //TODO check if leafs were registered

    ASSERT_TRUE(unregisterRootForSuffix("One"));
    ASSERT_TRUE(unregisterRootForSuffix("Two"));
    ASSERT_TRUE(unregisterRootForSuffix("Three"));

    //check that root one is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root two is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root three is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three","/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTestExtended, RegisterSeveralRootsAndSeveralLeafsForEachOnSameObjectPathAndCommunicate) {

    /* set environment variable (default config: commonapi-dbus.ini) to
     * to register the roots on the same object path
     */
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    ASSERT_TRUE(registerRootStubForSuffix("One"));
    ASSERT_TRUE(registerRootStubForSuffix("Two"));
    ASSERT_TRUE(registerRootStubForSuffix("Three"));

    const std::string dbusServiceNameBase = "commonapi.tests.managed.roots.on.same.object.path.RootInterface";

    //check that root one is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One", "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName,dbusObjectPathAndInterfacesDict));

    //check that root two is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two", "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName,dbusObjectPathAndInterfacesDict));

    //check that root three is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three", "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName,dbusObjectPathAndInterfacesDict));

    createRootProxyForSuffix("One");
    createRootProxyForSuffix("Two");
    createRootProxyForSuffix("Three");

    bool allRootProxiesAreAvailable = waitForAllProxiesToBeAvailable(rootProxies_);
    ASSERT_TRUE(allRootProxiesAreAvailable);

    bool allLeafStubsWereRegistered = registerXLeafStubsForAllRoots(5);
    ASSERT_TRUE(allLeafStubsWereRegistered);

    //TODO check if leafs were registered

    createXLeafProxiesForAllExistingLeafs();

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(3u, leafProxies_.size());

    uint32_t runNr = 1;
    for (const auto& leafProxiesForCurrentRoot : leafProxies_) {
        ASSERT_EQ(5u, leafProxiesForCurrentRoot.size())<< "in run #" << runNr;

        bool allLeafProxiesForCurrentRootAreAvailable = waitForAllProxiesToBeAvailable(leafProxiesForCurrentRoot);
        ASSERT_TRUE(allLeafProxiesForCurrentRootAreAvailable);

        ++runNr;
    }

    ASSERT_TRUE(unregisterRootForSuffix("One"));
    ASSERT_TRUE(unregisterRootForSuffix("Two"));
    ASSERT_TRUE(unregisterRootForSuffix("Three"));

    //check that root one is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "One", "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root two is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Two", "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that root three is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(dbusServiceNameBase + "Three", "/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    rootProxies_.clear();
    leafProxies_.clear();
}

TEST_F(DBusManagedTestExtended, RegisterTwoRootsForSameLeafInterface) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto secondRootStub = std::make_shared<VERSION::commonapi::tests::managed::SecondRootStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, secondRootInstanceName, secondRootStub));

    //check that second root is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(secondRootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(secondRootDbusObjectPath, secondRootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto leafStub1 = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    auto leafStub2 = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub1, leafInstanceNameRoot));
    ASSERT_TRUE(secondRootStub->registerManagedStubLeafInterface(leafStub2, leafInstanceNameSecondRoot));

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that second root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(secondRootDbusServiceName, secondRootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathSecondRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    rootStub->getStubAdapter()->deactivateManagedInstances();
    secondRootStub->getStubAdapter()->deactivateManagedInstances();

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that second root no longer manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(secondRootDbusServiceName, secondRootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::SecondRootStubDefault::StubInterface::getInterface(), secondRootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that second root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(secondRootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTestExtended, RegisterLeafsWithDistinctInterfacesOnSameRootManaged) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& leafInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerLeafInterface().getInstanceAvailabilityStatusChangedEvent();
    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& branchInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerBranchInterface().getInstanceAvailabilityStatusChangedEvent();

    leafInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onLeafInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));
    branchInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onBranchInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    auto branchStub = std::make_shared<VERSION::commonapi::tests::managed::BranchInterfaceStubDefault>();

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceNameRoot));

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, leafInstanceAvailability);

    // check that event for branch instances is not triggered by leaf instances
    ASSERT_NE(CommonAPI::AvailabilityStatus::AVAILABLE, branchInstanceAvailability);

    ASSERT_TRUE(rootStub->registerManagedStubBranchInterface(branchStub, branchInstanceNameRoot));

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, branchInstanceAvailability);

    //check that root manages leaf and branch
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));
    ASSERT_TRUE(isManaged(branchDbusObjectPathRoot, branchDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    rootStub->getStubAdapter()->deactivateManagedInstances();

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_TRUE(leafInstanceAvailability == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);
    ASSERT_TRUE(branchInstanceAvailability == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that root no longer manages leaf and branch
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTestExtended, RegisterLeafsWithDistinctInterfacesOnSameRootUnmanaged) {
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
            VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& leafInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerLeafInterface().getInstanceAvailabilityStatusChangedEvent();
    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& branchInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerBranchInterface().getInstanceAvailabilityStatusChangedEvent();

    leafInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onLeafInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));
    branchInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onBranchInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    runtime_->registerService(domain, leafInstanceNameRoot, leafStub, serviceConnectionId);

    auto branchStub = std::make_shared<VERSION::commonapi::tests::managed::BranchInterfaceStubDefault>();
    runtime_->registerService(domain, branchInstanceNameRoot, branchStub, serviceConnectionId);

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    // check, that events do not get triggered by unmanaged registration
    ASSERT_EQ(CommonAPI::AvailabilityStatus::UNKNOWN, leafInstanceAvailability);
    ASSERT_EQ(CommonAPI::AvailabilityStatus::UNKNOWN, branchInstanceAvailability);

    //check that root don't manages leaf and branch
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that leaf is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceNameRoot, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that branch is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(branchDbusServiceNameRoot, "/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(branchDbusObjectPathRoot, branchDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::LeafInterfaceStubDefault::StubInterface::getInterface(), leafInstanceNameRoot);
    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::BranchInterfaceStubDefault::StubInterface::getInterface(), branchInstanceNameRoot);
    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that leaf is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceNameRoot,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that branch is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(branchDbusServiceNameRoot,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTestExtended, RegisterSimpleChildInstance)
{
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto simpleLeafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();

    const std::string simpleLeafInstanceName =  "1";
    const std::string simpleLeafDbusServiceName = leafDbusInterfaceName + "_" + simpleLeafInstanceName;

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(simpleLeafStub, simpleLeafInstanceName));

    //check that root manages simple instance
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());

    //check that simple instance is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(simpleLeafDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTestExtended, RegisterSimpleChildInstanceAndHierachicalLeafInstance)
{
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
            VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& leafInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerLeafInterface().getInstanceAvailabilityStatusChangedEvent();
    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& branchInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerBranchInterface().getInstanceAvailabilityStatusChangedEvent();

    leafInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onLeafInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));
    branchInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onBranchInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto validLeafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    auto simpleLeafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    auto validBranchStub = std::make_shared<VERSION::commonapi::tests::managed::BranchInterfaceStubDefault>();

    const std::string simpleLeafInstanceName =  "1";
    const std::string simpleLeafDbusServiceName = leafDbusInterfaceName + "_" + simpleLeafInstanceName;
    const std::string simpleLeafDbusObjectPath = "/1";

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(validLeafStub, leafInstanceNameRoot));

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, leafInstanceAvailability);

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(simpleLeafStub, simpleLeafInstanceName));

    //check that root manages simple instance
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(simpleLeafDbusObjectPath, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    //check that simple instance is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(simpleLeafDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());

    ASSERT_TRUE(rootStub->registerManagedStubBranchInterface(validBranchStub, branchInstanceNameRoot));

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, branchInstanceAvailability);

    //check that root manages valid leaf and valid branch
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPathRoot, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));
    ASSERT_TRUE(isManaged(branchDbusObjectPathRoot, branchDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    rootStub->getStubAdapter()->deactivateManagedInstances();

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_TRUE(leafInstanceAvailability == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);
    ASSERT_TRUE(branchInstanceAvailability == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that root no longer manages leaf and branch
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTestExtended, RegisterLeafsWithAutoGeneratedInstanceIds)
{
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    int numberOfAutoGeneratedInstances = 5;
    for(int i=0; i<numberOfAutoGeneratedInstances; i++)
    {
        ASSERT_TRUE(rootStub->registerManagedStubLeafInterfaceAutoInstance(leafStub));
    }

    //check that root manages the auto generated leafs
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE((int)dbusObjectPathAndInterfacesDict.size() == numberOfAutoGeneratedInstances);

    rootStub->getStubAdapter()->deactivateManagedInstances();

    //check that root doesn't manage the auto generated leafs anymore
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTestExtended, RegisterLeafsWithAutoGeneratedInstanceIdsAndCommunicate)
{
    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
        VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();
    int numberOfAutoGeneratedInstances = 5;
    for(int i=0; i<numberOfAutoGeneratedInstances; i++)
    {
        ASSERT_TRUE(rootStub->registerManagedStubLeafInterfaceAutoInstance(leafStub));
    }

    //check that root manages the auto generated leafs
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE((int)dbusObjectPathAndInterfacesDict.size() == numberOfAutoGeneratedInstances);

    for(int i=0; i<numberOfAutoGeneratedInstances; i++)
    {
        const std::string autoGeneratedInstanceName = rootInstanceName + ".i" + std::to_string(i + 1);
        auto leafProxy = rootProxy->getProxyManagerLeafInterface().buildProxy<VERSION::commonapi::tests::managed::LeafInterfaceProxy>(autoGeneratedInstanceName);

        for (uint32_t i = 0; !leafProxy->isAvailable() && i < 200; ++i) {
            std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
        }

        ASSERT_TRUE(leafProxy->isAvailable());

        CommonAPI::CallStatus callStatus;
        VERSION::commonapi::tests::managed::LeafInterface::testLeafMethodError error;
        int outInt;
        std::string outString;
        leafProxy->testLeafMethod(42, "Test", callStatus, error, outInt, outString);

        ASSERT_TRUE(callStatus == CommonAPI::CallStatus::SUCCESS);
    }

    rootStub->getStubAdapter()->deactivateManagedInstances();

    //check that root doesn't manage the auto generated leafs anymore
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

TEST_F(DBusManagedTestExtended, ConfigurationFileAffectsInterfaceUnmanaged) {

    //set environment variable (default config: commonapi-dbus.ini)
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();

    //match with declared addresses in commonapi-dbus.ini
    const std::string leafInstanceName = "commonapi.tests.managed.config.affects.LeafInterface.Unmanaged";
    const std::string leafDbusServiceName = "commonapi.tests.managed.config.affects.interface.unmanaged";
    const std::string leafDbusObjectPath = "/commonapi/tests/managed/RootInterface/LeafInterface/Unmanaged";

    ASSERT_TRUE(runtime_->registerService(domain, leafInstanceName, leafStub, serviceConnectionId));

    //check that leaf is registered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPath, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::LeafInterfaceStubDefault::StubInterface::getInterface(), leafInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    //check that leaf is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(leafDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());
}

TEST_F(DBusManagedTestExtended, ConfigurationFileAffectsInterfaceManaged) {

    //set environment variable (default config: commonapi-dbus.ini)
    const char *defaultConfigSet = getenv("COMMONAPI_DBUS_CONFIG");
    ASSERT_TRUE(defaultConfigSet);

    auto rootStub = std::make_shared<VERSION::commonapi::tests::managed::RootInterfaceStubDefault>();
    ASSERT_TRUE(runtime_->registerService(domain, rootInstanceName, rootStub, serviceConnectionId));

    //check that root is registered
    auto dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(rootDbusObjectPath, rootDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    CommonAPI::DBus::DBusAddress rootDBusAddress;
    CommonAPI::Address rootCommonAPIAddress(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);
    CommonAPI::DBus::DBusAddressTranslator::get()->translate(rootCommonAPIAddress, rootDBusAddress);

    std::shared_ptr<CommonAPI::DBus::DBusConnection> proxyConnection = CommonAPI::DBus::DBusConnection::getBus(CommonAPI::DBus::DBusType_t::SESSION, clientConnectionId);
    proxyConnection->connect();

    std::shared_ptr<VERSION::commonapi::tests::managed::RootInterfaceDBusProxy> rootProxy = std::make_shared<
            VERSION::commonapi::tests::managed::RootInterfaceDBusProxy>(
                    rootDBusAddress,
                    proxyConnection
                    );

    rootProxy->init();

    for (uint32_t i = 0; !rootProxy->isAvailable() && i < 200; ++i) {
        std::this_thread::sleep_for(std::chrono::microseconds(10 * 1000));
    }
    ASSERT_TRUE(rootProxy->isAvailable());

    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& leafInstanceAvailabilityStatusEvent =
                    rootProxy->getProxyManagerLeafInterface().getInstanceAvailabilityStatusChangedEvent();

    leafInstanceAvailabilityStatusEvent.subscribe(
                    std::bind(&DBusManagedTestExtended::onLeafInstanceAvailabilityStatusChanged,
                              this,
                              std::placeholders::_1,
                              std::placeholders::_2));

    auto leafStub = std::make_shared<VERSION::commonapi::tests::managed::LeafInterfaceStubDefault>();

    //match with declared addresses in commonapi-dbus.ini
    const std::string leafInstanceName = "commonapi.tests.managed.config.affects.LeafInterface.Managed";
    const std::string leafDbusServiceName = "commonapi.tests.managed.config.affects.interface.managed";
    const std::string leafDbusObjectPath = "/commonapi/tests/managed/RootInterface/LeafInterface/Managed";

    ASSERT_TRUE(rootStub->registerManagedStubLeafInterface(leafStub, leafInstanceName));

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_EQ(CommonAPI::AvailabilityStatus::AVAILABLE, leafInstanceAvailability);

    //check that root manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_FALSE(dbusObjectPathAndInterfacesDict.empty());
    ASSERT_TRUE(isManaged(leafDbusObjectPath, leafDbusInterfaceName, dbusObjectPathAndInterfacesDict));

    rootStub->getStubAdapter()->deactivateManagedInstances();

    std::this_thread::sleep_for(std::chrono::microseconds(50000));

    ASSERT_TRUE(leafInstanceAvailability == CommonAPI::AvailabilityStatus::NOT_AVAILABLE);

    //check that root no longer manages leaf
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName, rootDbusObjectPath, manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    runtime_->unregisterService(domain, VERSION::commonapi::tests::managed::RootInterfaceStubDefault::StubInterface::getInterface(), rootInstanceName);

    //check that root is unregistered
    dbusObjectPathAndInterfacesDict.clear();
    dbusObjectPathAndInterfacesDict = getManagedObjects(rootDbusServiceName,"/", manualDBusConnection_);
    ASSERT_TRUE(dbusObjectPathAndInterfacesDict.empty());

    proxyConnection->disconnect();
}

#ifndef __NO_MAIN__
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
#endif
