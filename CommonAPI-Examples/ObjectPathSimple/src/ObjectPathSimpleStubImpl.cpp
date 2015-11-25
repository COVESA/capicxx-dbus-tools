/* Copyright (C) 2014, 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "ObjectPathSimpleStubImpl.hpp"

using namespace v1::commonapi::examples;

ObjectPathSimpleStubImpl::ObjectPathSimpleStubImpl() {
    cnt = 0;
}

ObjectPathSimpleStubImpl::~ObjectPathSimpleStubImpl() {
}

void ObjectPathSimpleStubImpl::incCounter() {
    cnt++;
    std::string x1 = "plain string";
    std::string x2 = "/path/to/object/" + std::to_string(cnt);
    fireTestbEvent(x1, x2);
    std::cout << "New counter value = " << cnt << "!" << std::endl;
}


void ObjectPathSimpleStubImpl::test(const std::shared_ptr<CommonAPI::ClientId> _client,
                std::string _x1,
                std::string _x2,
                testReply_t _reply) {

    std::cout << "method called, setting new values." << std::endl;

    std::string y1 = "plain return";
    std::string y2 = "/path/return";
    _reply(y2, y1);
}

