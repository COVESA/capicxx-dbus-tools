/* Copyright (C) 2018 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>

#include "VariantTypeStubImpl.hpp"

namespace v1 {
namespace test {
namespace varianttype {

VariantTypeStub::VariantTypeStub() {
}

VariantTypeStub::~VariantTypeStub() {
}

void VariantTypeStub::stubCmd(
        const std::shared_ptr<CommonAPI::ClientId>& _client,
        const uint8_t& _cmd, const stubCmdReply_t& _reply) {

    (void)_client;
    switch (_cmd) {
    case 1: // send data through broadcast
        break;
    default:
        break;
    }
    _reply();
}


} /* namespace varianttype */
} /* namespace test */
} /* namespace v1 */
