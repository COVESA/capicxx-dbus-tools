/* Copyright (C) 2018 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef VARIANTTYPESTUB_H
#define VARIANTTYPESTUB_H

#include "v1/test/varianttype/TestInterfaceStubDefault.hpp"

namespace v1 {
namespace test {
namespace varianttype {

class VariantTypeStub : public v1_0::test::varianttype::TestInterfaceStubDefault {
public:
    VariantTypeStub();
    virtual ~VariantTypeStub();
    void stubCmd(const std::shared_ptr<CommonAPI::ClientId>& _client,
                 const uint8_t& _cmd, const stubCmdReply_t& _reply);

private:
};

} /* namespace varianttype */
} /* namespace test */
} /* namespace v1 */

#endif /* VARIANTTYPESTUB_H */
