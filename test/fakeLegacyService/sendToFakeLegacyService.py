# Copyright (C) 2013 - 2015 BMW Group
# Author: Manfred Bathelt (manfred.bathelt@bmw.de)
# Author: Juergen Gehring (juergen.gehring@bmw.de)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import sys
import dbus
import dbus.service
import argparse

parser = argparse.ArgumentParser(description="""Finish fake Legacy Service""")
parser.add_argument("command", help="Command (e.g. finish)")
parser.add_argument("service", help="DBus Service Name")
parser.add_argument("object_path", help="DBus Object Path")
parser.add_argument("interface", help="DBus Interface name")
args = parser.parse_args()

COMMAND = args.command
SERVICE = args.service
OBJECT_PATH = args.object_path
INTERFACE = args.interface

def finish(interface):
    try:
        bus = dbus.SessionBus()
        remote_object = bus.get_object(SERVICE, OBJECT_PATH)
        iface = dbus.Interface(remote_object, interface)
        iface.finish()
        return 0
    except:
        print("Service not existing, therefore could not be stopped")
        return 1

def main():
    if COMMAND == "finish":
        return finish(INTERFACE)

    return 0

sys.exit(main())
