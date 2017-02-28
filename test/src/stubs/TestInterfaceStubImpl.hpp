/* Copyright (C) 2014 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TESTINTERFACESTUBIMPL_HPP_
#define TESTINTERFACESTUBIMPL_HPP_

#include "v1/commonapi/tests/TestInterfaceStubDefault.hpp"

namespace v1 {
namespace commonapi {
namespace tests {

class TestInterfaceStubImpl : public TestInterfaceStubDefault {
public:
    TestInterfaceStubImpl();
    virtual ~TestInterfaceStubImpl();

    void testErrorReplyMethod(const std::shared_ptr<CommonAPI::ClientId> _client,
                              const CommonAPI::CallId_t _callId,
                              std::string _name, testErrorReplyMethodReply_t _reply,
                              testErrorReplyMethodDisconnectedErrorReply_t _testErrorReplyMethodDisconnectedErrorReply);

    void testOverloadedMethod(const std::shared_ptr<CommonAPI::ClientId> _clientId, uint8_t _x,
                              testOverloadedMethodReply_t _reply);

    void testOverloadedMethod(const std::shared_ptr<CommonAPI::ClientId> _clientId, uint8_t _x, uint8_t _y,
                              testOverloadedMethodReply_t _reply);

    std::string getErrorReplyMessage() const;
    std::string getErrorReplyDescription() const;
    int32_t getErrorReplyCode() const;
private:

    const std::string errorReplyMessage_;
    const std::string errorReplyDescription_;
    const int32_t errorReplyCode_;
};

} /* namespace v1 */
} /* namespace commonapi */
} /* namespace tests */

#endif /* TESTINTERFACESTUBIMPL_HPP_ */
