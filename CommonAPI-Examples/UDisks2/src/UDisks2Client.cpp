/* Copyright (C) 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <unistd.h>
#include <iostream>

#include <CommonAPI/CommonAPI.hpp>
#include <v2/org/freedesktop/UDisks2/RootProxy.hpp>

using namespace v2::org::freedesktop::UDisks2;

void newBlockDeviceAvailable(const std::string address, const CommonAPI::AvailabilityStatus status) {
    if (status == CommonAPI::AvailabilityStatus::AVAILABLE) {
        std::cout << "New block device available: " << address << std::endl;
    }

    if (status == CommonAPI::AvailabilityStatus::NOT_AVAILABLE) {
        std::cout << "Block device removed: " << address << std::endl;
    }
}

int main(const int argc,  const char * const argv[]) {
    CommonAPI::Runtime::setProperty("LibraryBase", "UDisks2");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    const std::string & domain = "local";
    const std::string & instance = "org.freedesktop.UDisks2.Root";

    std::shared_ptr<RootProxy<>> rootProxy = runtime->buildProxy<RootProxy>(domain, instance, "udisks2");

    std::cout << "Checking 'org.freedesktop.UDisks2' availability.." << std::endl;
    while (!rootProxy->isAvailable()) {
        usleep(10);
    }
    std::cout << "\t..available." << std::endl;

    /*
     * Subscribe for block device event
     */
    CommonAPI::ProxyManager::InstanceAvailabilityStatusChangedEvent& blockEvent =
            rootProxy->getProxyManagerBlock().getInstanceAvailabilityStatusChangedEvent();

    std::function<void(const std::string, const CommonAPI::AvailabilityStatus)> newBlockDeviceAvailableFunc = newBlockDeviceAvailable;
    blockEvent.subscribe(newBlockDeviceAvailableFunc);

    while (true) {
        std::cout << "Waiting for events... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(30));
    }

    return 0;
}
