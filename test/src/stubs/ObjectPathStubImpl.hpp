/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef OBJECTPATHSTUB_H
#define OBJECTPATHSTUB_H

#include "v1/test/objectpath/TestInterfaceStubDefault.hpp"

namespace v1 {
namespace test {
namespace objectpath {

class ObjectPathStub : public v1_0::test::objectpath::TestInterfaceStubDefault {
public:
    ObjectPathStub();
    virtual ~ObjectPathStub();
    void stubCmd(const std::shared_ptr<CommonAPI::ClientId> _client,
        uint8_t _cmd, stubCmdReply_t _reply);

private:
};

} /* namespace objectpath */
} /* namespace test */
} /* namespace v1 */

#endif /* OBJECTPATHSTUB_H */
