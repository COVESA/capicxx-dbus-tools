/* Copyright (C) 2014, 2015 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <gio/gio.h>
#include <stdlib.h>

#ifdef G_OS_UNIX
#include <gio/gunixfdlist.h>
/* For STDOUT_FILENO */
#include <unistd.h>
#endif

GMainLoop *loop;
static int methodcounter = 0;

/* ---------------------------------------------------------------------------------------------------- */
static void on_method_call_done(GDBusConnection *connection,
                                GAsyncResult *res,
                                gpointer user_data) {
    GError *error;
    GVariant *result;
    const gchar *_plain;
    const gchar *_path;
    error = NULL;
    result = g_dbus_connection_call_finish(connection, res, &error);

    g_variant_unref(result);
}


static gboolean
on_timeout_cb (gpointer user_data)
{
    GDBusConnection *connection = G_DBUS_CONNECTION(user_data);
    methodcounter = (methodcounter + 1) % 3;
    switch (methodcounter) {
    case 0:
        g_dbus_connection_call(connection,
            "commonapi.examples.LegacyTest_commonapi.examples.LegacyTest",
            "/commonapi/examples/LegacyTest",
            "commonapi.examples.LegacyTest",
            "test",
            g_variant_new("(so)", "plain", "/object/path/example"),
            g_variant_type_new ("(os)"),
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            NULL,
            (GAsyncReadyCallback) on_method_call_done,
            NULL);
        break;
    case 1:
        g_dbus_connection_call(connection,
            "commonapi.examples.LegacyTest_commonapi.examples.LegacyTest",
            "/commonapi/examples/LegacyTest",
            "commonapi.examples.LegacyTest",
            "teststruct",
            g_variant_new("((os))", "/object/path/example", "plain string"),
            g_variant_type_new ("((os))"),
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            NULL,
            (GAsyncReadyCallback) on_method_call_done,
            NULL);
        break;
    case 2:
        {
            GVariant *var = g_variant_new("o", "/path/in/a/variant");
            g_dbus_connection_call(connection,
                "commonapi.examples.LegacyTest_commonapi.examples.LegacyTest",
                "/commonapi/examples/LegacyTest",
                "commonapi.examples.LegacyTest",
                "testunion",
                g_variant_new("(iv)", 1, var),
                g_variant_type_new ("(iv)"),
                G_DBUS_CALL_FLAGS_NONE,
                -1,
                NULL,
                (GAsyncReadyCallback) on_method_call_done,
                NULL);
        }
        break;
    }
    return TRUE;
}

static void on_test_broadcast(GDBusConnection *connection,
                       const gchar *sender_name,
                       const gchar *object_path,
                       const gchar *interface_name,
                       const gchar *signal_name,
                       GVariant *parameters,
                       gpointer user_data)
{
    const gchar *_plain;
    const gchar *_path;
    g_variant_get(parameters, "(so)", &_plain, &_path);
}


static void
on_name_appeared (GDBusConnection *connection,
                 const gchar *name,
                 const gchar *name_owner,
                 gpointer user_data)
{
    /* subscribe to the broadcast */
    guint id;
    id = g_dbus_connection_signal_subscribe(connection,
        NULL,
        "commonapi.examples.LegacyTest",
        "testb",
        "/commonapi/examples/LegacyTest",
        NULL,
        G_DBUS_SIGNAL_FLAGS_NONE,
        on_test_broadcast,
        NULL,
        NULL);

    /* set up a periodic callback */
    g_timeout_add_seconds (1,
                           on_timeout_cb,
                           connection);
}

static void
on_name_vanished (GDBusConnection *connection,
                  const gchar     *name,
                  gpointer         user_data)
{
    /* Exit when the bus disappears (the service has quit) */
    g_main_loop_quit(loop);
}

int
main (int argc, char *argv[])
{
    guint watcher_id;

    // give the server time to set itself up
    g_usleep(1000000);

    watcher_id = g_bus_watch_name(G_BUS_TYPE_SESSION,
      "commonapi.examples.LegacyTest_commonapi.examples.LegacyTest",
      G_BUS_NAME_WATCHER_FLAGS_NONE,
      on_name_appeared,
      on_name_vanished,
      NULL,
      NULL);

    loop = g_main_loop_new (NULL, FALSE);
    g_main_loop_run (loop);

    g_bus_unwatch_name(watcher_id);

    return 0;
}
