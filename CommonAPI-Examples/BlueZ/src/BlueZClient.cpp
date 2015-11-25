/* Copyright (C) 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <unistd.h>
#include <iostream>

#include <CommonAPI/CommonAPI.hpp>
#include <CommonAPI/DBus/CommonAPIDBus.hpp>
#include <v4/org/bluez/ManagerProxy.hpp>
#include <v4/org/bluez/AdapterProxy.hpp>

using namespace v4::org::bluez;

int main(int argc, const char * const argv[])
{
    CommonAPI::Runtime::setProperty("LibraryBase", "BlueZ");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    const std::string &domain = "local";
    const std::string &instanceManager = "org.bluez.Manager";
    std::shared_ptr<ManagerProxyDefault> mgrProxy = runtime->buildProxy<ManagerProxy>(domain, instanceManager, "bluez");

    std::cout << "Checking 'org.bluez.Manager' availability.." << std::endl;
    while (!mgrProxy->isAvailable()) {
        usleep(10);
    }
    std::cout << "\t..available." << std::endl;

    CommonAPI::CallStatus callStatus;
    CommonAPI::CallInfo info(1000);

    /*
     * determine & dump list of (available) adapters
     */
    std::vector<std::string> adapters;
    mgrProxy->ListAdapters(callStatus, adapters, &info);

    if (CommonAPI::CallStatus::SUCCESS != callStatus) {
        return -1;
    }

    if (0 < adapters.size()) {
        std::vector<std::string>::const_iterator it = adapters.begin();
        while (adapters.end() != it)
        {
            std::cout << "\tadapter: '" << *it++ << "'" << std::endl;
        }

        /*
         * use first found adapter for further action
         */
        const std::string & firstAdapter = adapters[0];
        const std::string & adapterInterface = "org.bluez.Adapter";

        /*
         * setup DBusAddressTranslator to create proxy with "non-standard" mapping
         *
         * note: the last element of CommonAPI address passed to insert(), should be unique as it
         *       will be used later to lookup of the address mapping!
         *       For simplicity just appending suffix #1 here (i.e. "org.bluez.Adapter#1"). This
         *       could also be derived from the object path in case more than one adapter is present
         *       in the system, though must adhere to DBusAddressTranslator's naming convention..
         */
        CommonAPI::DBus::DBusAddressTranslator::get()->insert("local:org.bluez.Adapter:org.bluez.Adapter#1", "org.bluez", firstAdapter, adapterInterface, true);

        /*
         *         .. now passing "org.bluez.Adapter#1" to build proxy whick invokes DBusAddressTranslator internally
         */
        std::shared_ptr<AdapterProxyDefault> adapterProxy = runtime->buildProxy<AdapterProxy>(domain, "org.bluez.Adapter#1", "bluez");

        std::cout << "Checking 'org.bluez.Adapter' " << firstAdapter << " availability.." << std::endl;

        while (!adapterProxy->isAvailable()) {
            usleep(10);
        }
        std::cout << "\t..available." << std::endl;

        /*
         * Sign up for 'PropertyChanged' events
         */
        adapterProxy->getPropertyChangedEvent().subscribe([&](const std::string& name, const Adapter::Variant & value) {
            if (value.isType<int>()) {
                std::cout << "Received 'org.bluez.Adapter.PropertyChanged' event: " << name << "' value (int): " << value.get<int>() << std::endl;
            }
            else if (value.isType<std::string>()) {
                std::cout << "Received 'org.bluez.Adapter.PropertyChanged' event: " << name << "' value (string): " << value.get<std::string>() << std::endl;
            }
            else if (value.isType<bool>()) {
                std::cout << "Received 'org.bluez.Adapter.PropertyChanged' event: " << name << "' value (bool): " << value.get<bool>() << std::endl;
            }
            else {
                std::cout << "Received 'org.bluez.Adapter.PropertyChanged' event" << name << "' value of UNKNOWN TYPE!!" << std::endl;
            }
        });

        /*
         * Sign up for 'DeviceFound' events
         */
        adapterProxy->getDeviceFoundEvent().subscribe([&](const std::string& address, const Adapter::tDeviceFound_valuesDict& values) {
            Adapter::tDeviceFound_valuesDict::const_iterator it;

            std::cout << "Received 'org.bluez.Adapter.DeviceFound' event" << std::endl;
            std::cout << "\tAddress: '" << address << "'" << std::endl;

            for (it = values.begin(); it != values.end(); it++) {
                const Adapter::Variant & value = it->second;
                if (value.isType<uint32_t>()) {
                    std::cout << "\t\t" << it->first << " (uint32):\t" << value.get<uint32_t>() << std::endl;
                }
                else if (value.isType<int32_t>()) {
                    std::cout << "\t\t" << it->first << " (int32):\t" << value.get<int32_t>() << std::endl;
                }
                else if (value.isType<std::string>()) {
                    std::cout << "\t\t" << it->first << " (string):\t" << value.get<std::string>() << std::endl;
                }
                else if (value.isType<bool>()) {
                    std::cout << "\t\t" << it->first << " (bool):\t" << (value.get<bool>()?"true":"false") << std::endl;
                }
                else if (value.isType<uint16_t>()) {
                    std::cout << "\t\t" << it->first << " (uint16):\t" << value.get<uint16_t>() << std::endl;
                }
                else if (value.isType<int16_t>()) {
                    std::cout << "\t\t" << it->first << " (int16):\t" << value.get<int16_t>() << std::endl;
                }
                else {
                    std::cout << "\t\t" << it->first << "' value: UNKNOWN TYPE!!" << std::endl;
                }
            }
        });

        while (true) {
            std::cout << "Waiting for events... (Abort with CTRL+C)" << std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(30));
        }
    }

    return 0;
}
