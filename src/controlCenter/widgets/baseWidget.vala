namespace SwayNotificationCenter.Widgets {
    public abstract class BaseWidget : Gtk.Box {
        public abstract string widget_name { get; }

        public weak string css_class_name {
            owned get {
                return "widget-%s".printf (widget_name);
            }
        }

        public string key { get; private set; }
        public string suffix { get; private set; }

        public unowned SwayncDaemon swaync_daemon;
        public unowned NotiDaemon noti_daemon;

        public enum ButtonType {
            TOGGLE,
            NORMAL;

            public static ButtonType parse (string value) {
                switch (value) {
                    case "toggle":
                        return ButtonType.TOGGLE;
                    default:
                        return ButtonType.NORMAL;
                }
            }
        }

        protected BaseWidget (string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon) {
            this.suffix = suffix;
            this.key = widget_name + (suffix.length > 0 ? "#%s".printf (suffix) : "");
            this.swaync_daemon = swaync_daemon;
            this.noti_daemon = noti_daemon;

            set_overflow (Gtk.Overflow.HIDDEN);
            add_css_class ("widget");
            add_css_class (css_class_name);
            if (suffix.length > 0) {
                add_css_class (suffix);
            }
        }

        protected Json.Object ?get_config (Gtk.Widget widget) {
            unowned OrderedHashTable<Json.Object> config
                = ConfigModel.instance.widget_config;
            string ?orig_key = null;
            Json.Object ?props = null;
            bool result = config.lookup_extended (key, out orig_key, out props);
            if (!result || orig_key == null || props == null) {
                warning ("%s: Config not found! Using default config...\n", key);
                return null;
            }
            return props;
        }

        public virtual void on_cc_visibility_change (bool value) {
        }

        protected T ?get_prop<T> (Json.Object config, string value_key, out bool found = null) {
            found = false;
            if (!config.has_member (value_key)) {
                debug ("%s: Config doesn't have key: %s!\n", key, value_key);
                return null;
            }
            var member = config.get_member (value_key);

            Type base_type = Functions.get_base_type (member.get_value_type ());

            Type generic_base_type = Functions.get_base_type (typeof (T));
            // Convert all INTs to INT64
            if (generic_base_type == Type.INT) {
                generic_base_type = Type.INT64;
            }

            if (!base_type.is_a (generic_base_type)) {
                warning ("%s: Config type %s doesn't match: %s!\n",
                         key,
                         typeof (T).name (),
                         member.get_value_type ().name ());
                return null;
            }
            found = true;
            switch (generic_base_type) {
                case Type.STRING :
                    return member.get_string ();
                case Type.INT64 :
                    return (int) member.get_int ();
                case Type.BOOLEAN :
                    return member.get_boolean ();
                default:
                    found = false;
                    return null;
            }
        }

        protected Json.Array ?get_prop_array (Json.Object config, string value_key) {
            if (!config.has_member (value_key)) {
                debug ("%s: Config doesn't have key: %s!\n", key, value_key);
                return null;
            }
            var member = config.get_member (value_key);
            if (member.get_node_type () != Json.NodeType.ARRAY) {
                debug ("Unable to find Json Array for member %s", value_key);
            }
            return config.get_array_member (value_key);
        }

        protected Action[] parse_actions (Json.Array actions) {
            Action[] res = new Action[actions.get_length ()];
            for (int i = 0; i < actions.get_length (); i++) {
                string label =
                    actions.get_object_element (i).get_string_member_with_default ("label",
                                                                                   "label");
                string command =
                    actions.get_object_element (i).get_string_member_with_default ("command", "");
                string t = actions.get_object_element (i).get_string_member_with_default ("type",
                                                                                          "normal");
                ButtonType type = ButtonType.parse (t);
                string update_command =
                    actions.get_object_element (i).get_string_member_with_default ("update-command",
                                                                                   "");
                bool active =
                    actions.get_object_element (i).get_boolean_member_with_default ("active",
                                                                                    false);
                string tooltip =
                    actions.get_object_element (i).get_string_member_with_default ("tooltip", "");
                res[i] = Action () {
                    label = label,
                    command = command,
                    type = type,
                    update_command = update_command,
                    active = active,
                    tooltip = tooltip
                };
            }
            return res;
        }

        /**
         * Parse on-click configuration for multi-click button support.
         * Returns true if on-click is present, false otherwise.
         */
        protected bool parse_on_click (Json.Object action_obj,
                                       out ClickAction? left,
                                       out ClickAction? middle,
                                       out ClickAction? right,
                                       ButtonType type) {
            left = null;
            middle = null;
            right = null;

            if (!action_obj.has_member ("on-click")) {
                return false;
            }

            var on_click = action_obj.get_member ("on-click");
            if (on_click.get_node_type () != Json.NodeType.OBJECT) {
                debug ("on-click must be an object");
                return false;
            }

            Json.Object click_obj = on_click.get_object ();
            bool is_toggle = (type == ButtonType.TOGGLE);

            // Parse left click
            if (click_obj.has_member ("left")) {
                left = parse_click_action (click_obj.get_member ("left"), is_toggle, action_obj);
            }

            // Parse middle click
            if (click_obj.has_member ("middle")) {
                middle = parse_click_action (click_obj.get_member ("middle"), false, action_obj);
            }

            // Parse right click
            if (click_obj.has_member ("right")) {
                right = parse_click_action (click_obj.get_member ("right"), false, action_obj);
            }

            return true;
        }

        private ClickAction parse_click_action (Json.Node node, bool is_toggle, Json.Object parent) {
            ClickAction action = ClickAction () {
                command = null,
                update_command = "",
                active = false
            };

            // If it's a string, it's a simple command
            if (node.get_node_type () == Json.NodeType.VALUE) {
                action.command = node.get_string ();
                return action;
            }

            // If it's an object, parse command, update-command, and active
            if (node.get_node_type () == Json.NodeType.OBJECT) {
                Json.Object obj = node.get_object ();
                action.command = obj.get_string_member_with_default ("command", "");
                if (is_toggle) {
                    action.update_command = obj.get_string_member_with_default ("update-command", "");
                    action.active = obj.get_boolean_member_with_default ("active", false);
                }
            }

            return action;
        }

        protected async void execute_command (string cmd, string[] env_additions = {}) {
            string msg = "";
            yield Functions.execute_command (cmd, env_additions, out msg);
        }
    }
}
