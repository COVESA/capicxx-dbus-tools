/* Copyright (C) 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <unistd.h>

#include <iostream>

#include <CommonAPI/CommonAPI.hpp>
#include <v0/commonapi/examples/VariantSimpleProxy.hpp>


using namespace v0::commonapi::examples;

void dumpProperties(const VariantSimple::tPropertiesDict & properties) {
    VariantSimple::tPropertiesDict::const_iterator it;
    for (it = properties.begin(); it != properties.end(); it++) {
        const VariantSimple::SampleUnion & var = it->second;

        if (var.isType<int>()) {
            std::cout << "  key: '" << it->first << "' value (int): " << var.get<int>() << std::endl;
        }
        else if (var.isType<std::string>()) {
            std::cout << "  key: '" << it->first << "' value (std::string): '" << var.get<std::string>() << "'" << std::endl;
        }
        else {
            std::cout << "  key: '" << it->first << "' value: UNKNOWN TYPE!!" << std::endl;
        }
    }
}

void getPropertiesAsyncCB(const CommonAPI::CallStatus& callStatus, const VariantSimple::tPropertiesDict& properties) {
    std::cout << "Async callStatus: " << ((CommonAPI::CallStatus::SUCCESS == callStatus) ? "SUCCESS" : "NO_SUCCESS") << std::endl;
    if (CommonAPI::CallStatus::SUCCESS == callStatus) {
        dumpProperties(properties);
    }
}

int main(int argc, const char * const argv[])
{
    CommonAPI::Runtime::setProperty("LibraryBase", "VariantSimple");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::cout << "Client" << std::endl;

    const std::string &domain = "local";
    const std::string &instance = "commonapi.examples.VariantSimple";
    std::shared_ptr<VariantSimpleProxyDefault> myProxy = runtime->buildProxy<VariantSimpleProxy>(domain, instance);

    std::cout << "Checking availability!" << std::endl;
    while (!myProxy->isAvailable()) {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
    }
    std::cout << "Available..." << std::endl;

    /*
     *  Subscribe to "GotToTell" broadcast
     */
    myProxy->getGotToTellEvent().subscribe([&](const int32_t& count, const VariantSimple::ComplexUnion & anything) {
        if (anything.isType<int>()) {
            std::cout << "Received 'GotToTell' event: " << count << "' anything (int): " << anything.get<int>() << std::endl;
        }
        else if (anything.isType<std::string>()) {
            std::cout << "Received 'GotToTell' event: " << count << "' anything (string): " << anything.get<std::string>() << std::endl;
        }
        else if (anything.isType<VariantSimple::SampleUnion>()) {
            std::cout << "Received 'GotToTell' event: " << count << "' anything (SampleUnion)" << std::endl;
        }
        else {
            std::cout << "Received 'GotToTell' event: " << count << "' anything UNKNOWN TYPE!!" << std::endl;
        }
    });

    /*
     *  Subscribe to "DeviceFound" broadcast
     */
    myProxy->getDeviceFoundEvent().subscribe([&](const std::string & address, const VariantSimple::tPropertiesDict & values) {
        std::cout << "Receive 'DeviceFound' event: address: '" << address << "'" << std::endl;
        dumpProperties(values);
    });
    CommonAPI::CallStatus callStatus;
    CommonAPI::CallInfo info(1000);
    int step(50);
    VariantSimple::SampleUnion varOut;
    std::string strOut;

    /*
     * invoke 'callMe' several times in a row
     */
    while (0 < step--) {
        if (0 == (step & 0x01)) {
            VariantSimple::SampleUnion varArg(step);
            myProxy->callMe("int", varArg, callStatus, strOut, varOut, &info);
        }
        else
        {
            static const std::string strArg("/var/string");
            VariantSimple::SampleUnion varArg(strArg);
            myProxy->callMe("str", varArg, callStatus, strOut, varOut, &info);
        }

        if (varOut.isType<int>()) {
            std::cout << "'callMe' returned: " << strOut << "' varOut (int): " << varOut.get<int>() << std::endl;
        }
        else if (varOut.isType<std::string>()) {
            std::cout << "'callMe' returned: " << strOut << "' varOut (string): " << varOut.get<std::string>() << std::endl;
        }
        else {
            std::cout << "'callMe' returned: " << strOut << "' varOut UNKNOWN TYPE!!" << std::endl;
        }
    }

    /*
     * Subscribe to "SignedUp" selective broadcast
     */
    myProxy->getSignedUpSelectiveEvent().subscribe([&](const std::string & sth, const VariantSimple::SampleUnion & more) {
        if (more.isType<int>()) {
            std::cout << "Received 'SignedUp' event: " << sth << "' more (int): " << more.get<int>() << std::endl;
        }
        else if (more.isType<std::string>()) {
            std::cout << "Received 'SignedUp' event: " << sth << "' more (string): " << more.get<std::string>() << std::endl;
        }
        else {
            std::cout << "Received 'SignedUp' event: " << sth << "' more UNKNOWN TYPE!!" << std::endl;
        }
    });

    /*
     * retrieving "Properties" hence string <> union/variant map (dictionary)
     */
    VariantSimple::tPropertiesDict properties;
    myProxy->getProperties(callStatus, properties, &info);
    dumpProperties(properties);

    /*
     * asynchronous calls
     */

    std::function<void(const CommonAPI::CallStatus&, const VariantSimple::tPropertiesDict&)> async_cb = getPropertiesAsyncCB;
    myProxy->getPropertiesAsync(async_cb);

    std::this_thread::sleep_for(std::chrono::seconds(10));

    return 0;
}
