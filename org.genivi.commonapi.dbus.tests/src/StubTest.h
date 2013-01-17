/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#include <commonapi/tests/TestInterfaceStubDefault.h>
#include <iostream>

namespace commonapi {
namespace tests {

class StubTest : public TestInterfaceStubDefault {

};

inline void StubTest::TestInterfaceStubDefault::testUnionMethod(DerivedTypeCollection::TestUnionIn inParam, DerivedTypeCollection::TestUnionOut& outParam) {
	    std::cout << "Union Method received ";
	    bool b;
	    if (inParam.isType<std::string>()) {
	    	std::cout << inParam.get<std::string>(b) << "\n";
	    } else if (inParam.isType<int16_t>()) {
	    	std::cout << inParam.get<int16_t>(b) << "\n";
	    }
	}

} // namespace tests
} // namespace commonapi
