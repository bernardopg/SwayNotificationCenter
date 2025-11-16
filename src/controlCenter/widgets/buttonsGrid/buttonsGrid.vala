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
        bool responsive = false;
        int button_width = 100;
        int button_height = -1;
        List<ToggleButton> toggle_buttons;
        Gtk.FlowBox container;

        public ButtonsGrid (string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon) {
            base (suffix, swaync_daemon, noti_daemon);

            Json.Object ?config = get_config (this);
            if (config != null) {
                Json.Array a = get_prop_array (config, "actions");
                if (a != null) {
                    actions = parse_actions (a);
                }

                bool bpr_found = false;
                int bpr = get_prop<int> (config, "buttons-per-row", out bpr_found);
                if (bpr_found) {
                    buttons_per_row = bpr;
                }

                bool responsive_found = false;
                bool resp = get_prop<bool> (
                    config, "responsive", out responsive_found
                );
                if (responsive_found) {
                    responsive = resp;
                }

                bool bw_found = false;
                int bw = get_prop<int> (config, "button-width", out bw_found);
                if (bw_found && bw > 0) {
                    button_width = bw;
                }

                bool bh_found = false;
                int bh = get_prop<int> (config, "button-height", out bh_found);
                if (bh_found) {
                    button_height = bh;
                }
            }

            container = new Gtk.FlowBox ();
            container.set_max_children_per_line (buttons_per_row);
            container.set_selection_mode (Gtk.SelectionMode.NONE);
            container.set_hexpand (true);

            if (responsive) {
                // In responsive mode, let FlowBox calculate based on button sizes
                container.set_min_children_per_line (1);
                container.set_homogeneous (false);
            }

            append (container);

            // add action to container
            foreach (var act in actions) {
                Gtk.Widget button_widget;

                switch (act.type) {
                    case ButtonType.TOGGLE :
                        ToggleButton tb = new ToggleButton (
                            act.label, act.command,
                            act.update_command, act.active
                        );
                        toggle_buttons.append (tb);
                        button_widget = tb;
                        break;
                    default:
                        Gtk.Button b = new Gtk.Button.with_label (act.label);
                        b.clicked.connect (() => execute_command.begin (act.command));
                        button_widget = b;
                        break;
                }

                // Apply size constraints
                if (responsive) {
                    button_widget.set_size_request (button_width, button_height);
                } else if (button_height > 0) {
                    button_widget.set_size_request (-1, button_height);
                }

                // Apply tooltip if provided
                if (act.tooltip != null && act.tooltip.length > 0) {
                    button_widget.set_tooltip_text (act.tooltip);
                }

                container.insert (button_widget, -1);
            }
        }

        public override void on_cc_visibility_change (bool value) {
            if (value) {
                foreach (var tb in toggle_buttons) {
                    tb.on_update.begin ();
                }
            }
        }
    }
}
