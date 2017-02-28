/* Copyright (C) 2014 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "TestInterfaceStubImpl.hpp"

namespace v1 {
namespace commonapi {
namespace tests {

TestInterfaceStubImpl::TestInterfaceStubImpl() :
    errorReplyMessage_("error.disconnected"),
    errorReplyDescription_("Dummy error description"),
    errorReplyCode_(6) {

}

TestInterfaceStubImpl::~TestInterfaceStubImpl() {

}

void TestInterfaceStubImpl::testErrorReplyMethod(const std::shared_ptr<CommonAPI::ClientId> _client,
                                                 const CommonAPI::CallId_t _callId,
                                                 std::string _name, testErrorReplyMethodReply_t _reply,
                                                 testErrorReplyMethodDisconnectedErrorReply_t _testErrorReplyMethodDisconnectedErrorReply) {
    (void)_reply;
    (void)_client;
    (void)_name;
    _testErrorReplyMethodDisconnectedErrorReply(_callId, errorReplyDescription_, errorReplyCode_);
}

void TestInterfaceStubImpl::testOverloadedMethod(const std::shared_ptr<CommonAPI::ClientId> _clientId, uint8_t _x,
                          testOverloadedMethodReply_t _reply) {
    (void)_clientId;

    uint8_t y = _x;
    _reply(y);
}

void TestInterfaceStubImpl::testOverloadedMethod(const std::shared_ptr<CommonAPI::ClientId> _clientId, uint8_t _x, uint8_t _y,
                          testOverloadedMethodReply_t _reply) {
    (void)_clientId;

    uint8_t z = (uint8_t)(_x + _y);
    _reply(z);
}


std::string TestInterfaceStubImpl::getErrorReplyMessage() const {
    return errorReplyMessage_;
}

std::string TestInterfaceStubImpl::getErrorReplyDescription() const {
    return errorReplyDescription_;
}

int32_t TestInterfaceStubImpl::getErrorReplyCode() const {
    return errorReplyCode_;
}


} /* namespace v1 */
} /* namespace commonapi */
} /* namespace tests */
