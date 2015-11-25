/* Copyright (C) 2014, 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef OBJECTPATHSIMPLESTUBIMPL_H_
#define OBJECTPATHSIMPLESTUBIMPL_H_

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/examples/ObjectPathSimpleStubDefault.hpp>

class ObjectPathSimpleStubImpl: public v1::commonapi::examples::ObjectPathSimpleStubDefault {

public:
    ObjectPathSimpleStubImpl();
    virtual ~ObjectPathSimpleStubImpl();
    virtual void incCounter();
    virtual void test(const std::shared_ptr<CommonAPI::ClientId> _client,
            std::string _x1,
            std::string _x2,
            testReply_t _reply);

private:
    int cnt;
};

#endif /* OBJECTPATHSIMPLESTUBIMPL_H_ */

