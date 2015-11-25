/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>
#include <thread>

#include <CommonAPI/CommonAPI.hpp>
#include "VariantSimpleStubImpl.hpp"

int main(int argc, const char * const argv[])
{
    CommonAPI::Runtime::setProperty("LibraryBase", "VariantSimple");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.examples.VariantSimple";

    std::shared_ptr<VariantSimpleStubImpl> myService = std::make_shared<VariantSimpleStubImpl>();
    runtime->registerService(domain, instance, myService);

    int cnt = 0;
    v0::commonapi::examples::VariantSimple::tPropertiesDict deviceFoundValues;

    deviceFoundValues["vendor"] = v0::commonapi::examples::VariantSimple::SampleUnion(std::string("/genuine/vendor"));
    while (true) {
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;

        /*
         * Generate "GotToTell" broadcast
         */
        v0::commonapi::examples::VariantSimple::SampleUnion varArgs(cnt++);
        v0::commonapi::examples::VariantSimple::ObjectStruct os("/path/123/asd", varArgs);
        v0::commonapi::examples::VariantSimple::ComplexUnion varArg(os);
        v0::commonapi::examples::VariantSimple::ComplexUnion varArgMap(deviceFoundValues);
        v0::commonapi::examples::VariantSimple::vArray a;
        v0::commonapi::examples::VariantSimple::PathStruct ps(cnt, "/test/path");
        a.push_back(ps);
        v0::commonapi::examples::VariantSimple::ComplexUnion varArgArray(a);
        myService->fireGotToTellEvent(cnt, varArg);
        myService->fireGotToTellEvent(cnt, varArgMap);
        myService->fireGotToTellEvent(cnt, varArgArray);
        /*
         * Generate "DeviceFound" broadcast (approximately every 5 seconds)
         */
        if (0 == cnt % 5) {
            deviceFoundValues["id"] = v0::commonapi::examples::VariantSimple::SampleUnion(4711+cnt);
            myService->fireDeviceFoundEvent(std::string("01:23:45:67:89:AB"), deviceFoundValues);
        }

        /*
         * Generate "GotToTell" broadcast
         */
        if (cnt & 0x01) {
            v0::commonapi::examples::VariantSimple::SampleUnion varArg(cnt++);
            myService->fireSignedUpSelective("hello", varArg);
        }

        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    return 0;
}
