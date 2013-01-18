/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#include <commonapi/tests/TestInterfaceStubDefault.h>
#include <iostream>

namespace commonapi {
namespace tests {

class StubTest: public TestInterfaceStubDefault {

};

inline void StubTest::TestInterfaceStubDefault::testUnionMethod(
                                                                DerivedTypeCollection::TestUnionIn inParam,
                                                                DerivedTypeCollection::TestUnionIn& outParam) {
    std::cout << "Union Method received ";
    if (inParam.isType<std::string>()) {
        std::cout << inParam.get<std::string>() << "\n";
    } else if (inParam.isType<int16_t>()) {
        std::cout << inParam.get<int16_t>() << "\n";
    } else if (inParam.isType<double>()) {
        std::cout << inParam.get<double>() << "\n";
    }

    outParam = inParam;

}

} // namespace tests
} // namespace commonapi
