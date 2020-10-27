/* Copyright (C) 2014 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include "ObjectPathStubImpl.hpp"

namespace v1 {
namespace test {
namespace objectpath {

ObjectPathStub::ObjectPathStub() {
}

ObjectPathStub::~ObjectPathStub() {
}

void ObjectPathStub::stubCmd(
        const std::shared_ptr<CommonAPI::ClientId> _client,
        const uint8_t _cmd, const stubCmdReply_t _reply) {

    (void)_client;
    switch (_cmd) {
    case 1: // send data through broadcast
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
            fireB0Event(goodpath, goodpath, str, u);
        }
        break;
    default:
        break;
    }
    _reply();
}


} /* namespace objectpath */
} /* namespace test */
} /* namespace v1 */
