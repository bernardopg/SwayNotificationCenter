using GLib;

namespace SwayNotificationCenter.Widgets {
    public class ButtonsGrid : BaseWidget {
        public override string widget_name {
            get {
                return "buttons-grid";
            }
        }

        Action[] actions;
        // 7 is the default Gtk.FlowBox.max_children_per_line
        int buttons_per_row = 7;
        List<ToggleButton> toggle_buttons;
        List<ClickableButton> clickable_buttons;

        public ButtonsGrid (string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon) {
            base (suffix, swaync_daemon, noti_daemon);

            Json.Object ?config = get_config (this);
            Json.Array ?actions_array = null;

            if (config != null) {
                actions_array = get_prop_array (config, "actions");
                if (actions_array != null) {
                    actions = parse_actions (actions_array);
                }

                bool bpr_found = false;
                int bpr = get_prop<int> (config, "buttons-per-row", out bpr_found);
                if (bpr_found) {
                    buttons_per_row = bpr;
                }
            }

            Gtk.FlowBox container = new Gtk.FlowBox ();
            container.set_max_children_per_line (buttons_per_row);
            container.set_selection_mode (Gtk.SelectionMode.NONE);
            container.set_hexpand (true);
            append (container);

            // Add actions to container
            if (actions_array != null) {
                for (int i = 0; i < actions_array.get_length (); i++) {
                    Json.Object action_obj = actions_array.get_object_element (i);
                    Action act = actions[i];

                    // Try to parse on-click configuration first
                    ClickAction? left, middle, right;
                    bool has_multi_click = parse_on_click (action_obj, out left, out middle,
                                                           out right, act.type);

                    if (has_multi_click) {
                        // Create multi-click button
                        bool is_toggle = (act.type == ButtonType.TOGGLE);
                        ClickableButton cb = new ClickableButton (act.label, left, middle,
                                                                  right, is_toggle);
                        if (act.tooltip != null && act.tooltip != "") {
                            cb.set_tooltip_text (act.tooltip);
                        }
                        container.insert (cb, -1);
                        if (is_toggle) {
                            clickable_buttons.append (cb);
                        }
                    } else {
                        // Use legacy button creation
                        switch (act.type) {
                            case ButtonType.TOGGLE :
                                ToggleButton tb = new ToggleButton (act.label, act.command,
                                                                    act.update_command, act.active);
                                if (act.tooltip != null && act.tooltip != "") {
                                    tb.set_tooltip_text (act.tooltip);
                                }
                                container.insert (tb, -1);
                                toggle_buttons.append (tb);
                                break;
                            default:
                                Gtk.Button b = new Gtk.Button.with_label (act.label);
                                if (act.tooltip != null && act.tooltip != "") {
                                    b.set_tooltip_text (act.tooltip);
                                }
                                b.clicked.connect (() => execute_command.begin (act.command));
                                container.insert (b, -1);
                                break;
                        }
                    }
                }
            }
        }

        public override void on_cc_visibility_change (bool value) {
            if (value) {
                foreach (var tb in toggle_buttons) {
                    tb.on_update.begin ();
                }
                foreach (var cb in clickable_buttons) {
                    cb.on_update.begin ();
                }
            }
        }
    }
}
