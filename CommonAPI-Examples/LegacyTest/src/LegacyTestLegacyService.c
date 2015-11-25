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

/* ---------------------------------------------------------------------------------------------------- */

static GDBusNodeInfo *introspection_data = NULL;
static int cnt = 0;
GMainLoop *loop;

/* Introspection data for the service we are exporting */
static const gchar introspection_xml[] =
  "<node>"
  "  <interface name='commonapi.examples.LegacyTest'>"
        "<method name=\"getInterfaceVersion\">\n"
            "<arg name=\"value\" type=\"uu\" direction=\"out\" />"
        "</method>\n"
        "<property name=\"nopath\" type=\"s\" access=\"readwrite\" />\n"
        "<property name=\"objectpath\" type=\"o\" access=\"readwrite\" />\n"
        "<property name=\"defvalue\" type=\"s\" access=\"readwrite\" />\n"
        "<signal name=\"testb\">\n"
            "<arg name=\"plain3\" type=\"s\" />\n"
            "<arg name=\"path3\" type=\"o\" />\n"
        "</signal>\n"
        "<method name=\"test\">\n"
            "<arg name=\"_plain\" type=\"s\" direction=\"in\" />\n"
            "<arg name=\"_path\" type=\"o\" direction=\"in\" />\n"
            "<arg name=\"_path2\" type=\"o\" direction=\"out\" />\n"
            "<arg name=\"_plain2\" type=\"s\" direction=\"out\" />\n"
        "</method>\n"
        "<method name=\"teststruct\">\n"
            "<arg name=\"_pathsin\" type=\"(os)\" direction=\"in\" />\n"
            "<arg name=\"_pathsout\" type=\"(os)\" direction=\"out\" />\n"
        "</method>\n"
        "<method name=\"testunion\">\n"
            "<arg name=\"_intin\" type=\"i\" direction=\"in\" />\n"
            "<arg name=\"_pathuin\" type=\"v\" direction=\"in\" />\n"
            "<arg name=\"_intout\" type=\"i\" direction=\"out\" />\n"
            "<arg name=\"_pathuout\" type=\"v\" direction=\"out\" />\n"
        "</method>\n"
  "  </interface>"
  "  <interface name='org.freedesktop.DBus.ObjectManager'>"
        "<method name=\"GetManagedObjects\">\n"
            "<arg name=\"value\" type=\"a{oa{sa{sv}}}\" direction=\"out\" />\n"
        "</method>\n"
  "  </interface>"
  "</node>";

static void
handle_method_call (GDBusConnection       *connection,
                    const gchar           *sender,
                    const gchar           *object_path,
                    const gchar           *interface_name,
                    const gchar           *method_name,
                    GVariant              *parameters,
                    GDBusMethodInvocation *invocation,
                    gpointer               user_data)
{
    if (g_strcmp0(method_name, "test") == 0) {
        const gchar *_plain;
        const gchar *_path;
        g_variant_get(parameters, "(so)", &_plain, &_path);

        g_printf("(Legacy Service) 'test' method called\n");

        GVariant *returnvalue;
        returnvalue = g_variant_new("(os)", "/path/return", "plain return");
        g_dbus_method_invocation_return_value(invocation, returnvalue);

    } else if (g_strcmp0(method_name, "teststruct") == 0) {
        /* in: (os), out: (os) */
        const gchar *_plain;
        const gchar *_path;
        g_variant_get(parameters, "((os))", &_path, &_plain);

        g_printf("(Legacy Service) 'teststruct' method called\n");

        GVariant *returnvalue;
        returnvalue = g_variant_new("((os))", "/path/return", "plain return");
        g_dbus_method_invocation_return_value(invocation, returnvalue);

    } else if (g_strcmp0(method_name, "testunion") == 0) {
        /* in: iv, out: iv */
        GVariant *var;
        gint32 i;
        g_variant_get(parameters, "(iv)", &i, &var);
        g_printf("(Legacy Service) 'testunion' method called\n");

        GVariant *returnvalue;
        returnvalue = g_variant_new("(iv)", i, var);
        g_dbus_method_invocation_return_value(invocation, returnvalue);

    }
}

static GVariant *
handle_get_property (GDBusConnection  *connection,
                     const gchar      *sender,
                     const gchar      *object_path,
                     const gchar      *interface_name,
                     const gchar      *property_name,
                     GError          **error,
                     gpointer          user_data)
{
    GVariant *ret;
    ret = NULL;
    if (g_strcmp0(property_name, "nopath") == 0) {
        ret = g_variant_new_string("normal string");
    } else if (g_strcmp0(property_name, "objectpath") == 0) {
        ret = g_variant_new("o", "/some/path/name");
    } else if (g_strcmp0(property_name, "defvalue") == 0) {
        ret = g_variant_new_string("default string");
    }
    return ret;
}

static gboolean
handle_set_property (GDBusConnection  *connection,
                     const gchar      *sender,
                     const gchar      *object_path,
                     const gchar      *interface_name,
                     const gchar      *property_name,
                     GVariant         *value,
                     GError          **error,
                     gpointer          user_data)
{
    GVariant *ret = NULL;
    if (g_strcmp0(property_name, "nopath") == 0) {
        /* check for special kill value */
        gchar * str;
        g_variant_get(value, "s", &str);
        if (g_strcmp0(str, "kill") == 0) {
             /* 'kill me' command received */
             g_main_loop_quit(loop);
             return TRUE;
        }
        ret = g_variant_new_string(str);
    } else if (g_strcmp0(property_name, "objectpath") == 0) {
        gchar * str;
        g_variant_get(value, "o", &str);
        ret = g_variant_new("o", str);
    } else if (g_strcmp0(property_name, "defvalue") == 0) {
        gchar * str;
        g_variant_get(value, "s", &str);
        ret = g_variant_new("s", str);
    }

    if (ret != NULL) {
        GVariantBuilder *builder;
        g_printf("(Legacy Service) '%s' attribute set\n", property_name);

        builder = g_variant_builder_new (G_VARIANT_TYPE_ARRAY);
        g_variant_builder_add (builder, "{sv}", property_name, ret);
        g_dbus_connection_emit_signal(connection,
                                      NULL,
                                      object_path,
                                      "org.freedesktop.DBus.Properties",
                                      "PropertiesChanged",
                                      g_variant_new("(sa{sv}as)",
                                                    interface_name,
                                                    builder,
                                                    NULL),
                                      NULL);
    }
    return *error == NULL;
}

static void
handle_om_method_call (GDBusConnection       *connection,
                    const gchar           *sender,
                    const gchar           *object_path,
                    const gchar           *interface_name,
                    const gchar           *method_name,
                    GVariant              *parameters,
                    GDBusMethodInvocation *invocation,
                    gpointer               user_data)
{
    if (g_strcmp0(method_name, "GetManagedObjects") == 0) {

        g_printf("(Legacy Service) 'GetManagedObjects' method called\n");

        GVariantBuilder *propdict;
        propdict = g_variant_builder_new (G_VARIANT_TYPE_DICTIONARY);
        g_variant_builder_init (propdict, "a{sv}");

        /* the CommonAPI client currently does not support Properties
           in the GetManagedObjects method. The property dictionary
           must be empty.
           
        GVariant *key1 = g_variant_new("s", "nopath");
        GVariant *value1 = g_variant_new("s", "normal_string");
        GVariant *d1 = g_variant_new_dict_entry(key1, g_variant_new_variant(value1));
        g_variant_builder_add_value(propdict, d1);
        GVariant *key2 = g_variant_new("s", "objectpath");
        GVariant *value2 = g_variant_new("o", "/some/path/name");
        GVariant *d2 = g_variant_new_dict_entry(key2, g_variant_new_variant(value2));
        g_variant_builder_add_value(propdict, d2);
        GVariant *key3 = g_variant_new("s", "defvalue");
        GVariant *value3 = g_variant_new("s", "default string");
        GVariant *d3 = g_variant_new_dict_entry(key3, g_variant_new_variant(value3));
        g_variant_builder_add_value(propdict, d3);
        */
        GVariant * pmap;
        pmap = g_variant_builder_end(propdict);

        GVariantBuilder *ifdict;
        ifdict = g_variant_builder_new (G_VARIANT_TYPE_DICTIONARY);
        GVariant *keyi = g_variant_new("s", "commonapi.examples.LegacyTest");

        GVariant *di = g_variant_new_dict_entry(keyi, pmap);
        g_variant_builder_add_value(ifdict, di);
        GVariant * imap;
        imap = g_variant_builder_end(ifdict);

        GVariant *key = g_variant_new("o", "/commonapi/examples/LegacyTest");
        GVariant *dv = g_variant_new_dict_entry(key, imap);

        GVariantBuilder *builder;
        builder = g_variant_builder_new (G_VARIANT_TYPE_DICTIONARY);
        g_variant_builder_add_value (builder, dv);

        GVariant * r;
        r = g_variant_builder_end(builder);

        GVariant *returnvalue;
        returnvalue = g_variant_new_tuple(&r, 1);

        g_dbus_method_invocation_return_value(invocation, returnvalue);

    }

}

static const GDBusInterfaceVTable interface_vtable =
{
  handle_method_call,
  handle_get_property,
  handle_set_property
};

static const GDBusInterfaceVTable om_interface_vtable =
{
  handle_om_method_call,
  handle_get_property,
  handle_set_property
};

static gboolean
on_timeout_cb (gpointer user_data)
{
    GDBusConnection *connection = G_DBUS_CONNECTION(user_data);
    GError *local_error = NULL;
    gchar *counter_as_string;
    counter_as_string = g_strdup_printf("/path/to/object/%d", cnt);
    cnt++;

    g_dbus_connection_emit_signal(connection,
                                  NULL, /* to all listeners */
                                  "/commonapi/examples/LegacyTest",
                                  "commonapi.examples.LegacyTest",
                                  "testb",
                                  g_variant_new("(so)",
                                      "plain string",
                                      counter_as_string),
                                  &local_error);

    g_free(counter_as_string);

    return TRUE;
}

static void
on_bus_acquired (GDBusConnection *connection,
                 const gchar     *name,
                 gpointer         user_data)
{
    guint registration_id;

    registration_id = g_dbus_connection_register_object (connection,
                                                         "/commonapi/examples/LegacyTest",
                                                         introspection_data->interfaces[0],
                                                         &interface_vtable,
                                                         NULL,  /* user_data */
                                                         NULL,  /* user_data_free_func */
                                                         NULL); /* GError** */
    g_assert (registration_id > 0);

    registration_id = g_dbus_connection_register_object (connection,
                                                         "/",
                                                         introspection_data->interfaces[1],
                                                         &om_interface_vtable,
                                                         NULL,  /* user_data */
                                                         NULL,  /* user_data_free_func */
                                                         NULL); /* GError** */
    g_assert (registration_id > 0);

    /* Change property value every two seconds */
    g_timeout_add_seconds (2,
                           on_timeout_cb,
                           connection);
}

static void
on_name_acquired (GDBusConnection *connection,
                  const gchar     *name,
                  gpointer         user_data)
{
}

static void
on_name_lost (GDBusConnection *connection,
              const gchar     *name,
              gpointer         user_data)
{
    exit (1);
}

int
main (int argc, char *argv[])
{
    guint owner_id;

    introspection_data = g_dbus_node_info_new_for_xml (introspection_xml, NULL);
    g_assert (introspection_data != NULL);

    owner_id = g_bus_own_name (G_BUS_TYPE_SESSION,
                               "commonapi.examples.LegacyTest_commonapi.examples.LegacyTest",
                               G_BUS_NAME_OWNER_FLAGS_NONE,
                               on_bus_acquired,
                               on_name_acquired,
                               on_name_lost,
                               NULL,
                               NULL);

    loop = g_main_loop_new (NULL, FALSE);
    g_main_loop_run (loop);

    g_bus_unown_name (owner_id);

    g_dbus_node_info_unref (introspection_data);

    return 0;
}
