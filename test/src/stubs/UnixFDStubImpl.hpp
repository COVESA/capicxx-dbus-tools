/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef UNIXFDSTUB_H
#define UNIXFDSTUB_H

#include "v1/test/unixfd/TestInterfaceStubDefault.hpp"

namespace v1 {
namespace test {
namespace unixfd {

class UnixFDStub : public v1_0::test::unixfd::TestInterfaceStubDefault {
public:
    UnixFDStub();
    virtual ~UnixFDStub();
    void stubCmd(const std::shared_ptr<CommonAPI::ClientId> _client,
        uint8_t _cmd, stubCmdReply_t _reply);

private:
};

} /* namespace unixfd */
} /* namespace test */
} /* namespace v1 */

#endif /* UNIXFDSTUB_H */
