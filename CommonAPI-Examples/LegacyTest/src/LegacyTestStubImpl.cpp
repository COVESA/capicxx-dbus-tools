/* Copyright (C) 2014, 2015 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "LegacyTestStubImpl.hpp"

using namespace v1::commonapi::examples;

LegacyTestStubImpl::LegacyTestStubImpl() {
    cnt = 0;
}

LegacyTestStubImpl::~LegacyTestStubImpl() {
}

void LegacyTestStubImpl::incCounter() {
    cnt++;
    std::string x1 = "plain string";
    std::string x2 = "/path/to/object/" + std::to_string(cnt);
    fireTestbEvent(x1, x2);
}


void LegacyTestStubImpl::test(const std::shared_ptr<CommonAPI::ClientId> _client,
                std::string _x1,
                std::string _x2,
                testReply_t _reply) {

    std::cout << "(CAPI Service) 'test' method called" << std::endl;

    std::string y1 = "plain return";
    std::string y2 = "/path/return";
    _reply(y2, y1);
}

void LegacyTestStubImpl::teststruct(const std::shared_ptr<CommonAPI::ClientId> _client,
                                          v1::commonapi::examples::LegacyTest::pathstruct _pathsin,
                                          teststructReply_t _reply) {

    std::cout << "(CAPI Service) 'teststruct' method called" << std::endl;

    v1::commonapi::examples::LegacyTest::pathstruct pathsout = _pathsin;
    _reply(pathsout);
}

void LegacyTestStubImpl::testunion(const std::shared_ptr<CommonAPI::ClientId> _client,
                                         int32_t _intin,
                                         v1::commonapi::examples::LegacyTest::pathunion _pathuin,
                                         testunionReply_t _reply) {

    std::cout << "(CAPI Service) 'testunion' method called" << std::endl;

    int32_t intout = _intin;
    v1::commonapi::examples::LegacyTest::pathunion pathuout = _pathuin;
    _reply(intout, pathuout);
}
