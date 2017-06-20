/* Copyright (C) 2014 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include "UnixFDStubImpl.hpp"

namespace v1 {
namespace test {
namespace unixfd {

UnixFDStub::UnixFDStub() {
}

UnixFDStub::~UnixFDStub() {
}

void UnixFDStub::stubCmd(const std::shared_ptr<CommonAPI::ClientId> _client,
    uint8_t _cmd, stubCmdReply_t _reply) {

    (void)_client;
    switch (_cmd) {
    case 1: // send data through broadcast
        {
            uint32_t outv = 1;
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
            fireB0Event(outv, outv, str, u);
        }
        break;
    default:
        break;
    }
    _reply();
}


} /* namespace unixfd */
} /* namespace test */
} /* namespace v1 */
