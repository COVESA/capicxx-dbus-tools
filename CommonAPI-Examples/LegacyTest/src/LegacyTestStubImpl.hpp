/* Copyright (C) 2014, 2015 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef LEGACYTESTSTUBIMPL_H_
#define LEGACYTESTSTUBIMPL_H_

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/examples/LegacyTestStubDefault.hpp>

class LegacyTestStubImpl: public v1::commonapi::examples::LegacyTestStubDefault {

public:
    LegacyTestStubImpl();
    virtual ~LegacyTestStubImpl();
    virtual void incCounter();
    virtual void test(const std::shared_ptr<CommonAPI::ClientId> _client,
            std::string _x1,
            std::string _x2,
            testReply_t _reply);
    virtual void teststruct(const std::shared_ptr<CommonAPI::ClientId> _client,
            v1::commonapi::examples::LegacyTest::pathstruct _pathsin,
            teststructReply_t _reply);
    virtual void testunion(const std::shared_ptr<CommonAPI::ClientId> _client,
            int32_t _intin,
            v1::commonapi::examples::LegacyTest::pathunion _pathuin,
            testunionReply_t _reply);

private:
    int cnt;
};

#endif /* LEGACYTESTSTUBIMPL_H_ */

