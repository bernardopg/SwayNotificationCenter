namespace SwayNotificationCenter.Widgets {
    public enum ClickType {
        LEFT,
        MIDDLE,
        RIGHT;

        public static ClickType from_button (uint button) {
            switch (button) {
                case 1:
                    return ClickType.LEFT;
                case 2:
                    return ClickType.MIDDLE;
                case 3:
                    return ClickType.RIGHT;
                default:
                    return ClickType.LEFT;
            }
        }
    }

    public struct ClickAction {
        string? command;
        string? update_command;
        bool active;
    }

    /**
     * A button that supports different actions for left, middle, and right clicks.
     * Can work as both a normal button and a toggle button.
     */
    class ClickableButton : Gtk.Button {
        private bool is_toggle_mode;
        private ClickAction? left_action;
        private ClickAction? middle_action;
        private ClickAction? right_action;
        private bool toggle_state = false;
        private Gtk.GestureClick gesture;

        public ClickableButton (string label,
                                ClickAction? left,
                                ClickAction? middle,
                                ClickAction? right,
                                bool is_toggle) {
            this.label = label;
            this.left_action = left;
            this.middle_action = middle;
            this.right_action = right;
            this.is_toggle_mode = is_toggle;
            this.set_has_frame (true);

            // Initialize toggle state if in toggle mode
            if (is_toggle && left_action != null) {
                this.toggle_state = left_action.active;
                if (this.toggle_state) {
                    this.add_css_class ("active");
                }
            }

            // Create gesture controller for mouse button detection
            gesture = new Gtk.GestureClick ();
            gesture.set_button (0); // Listen to all buttons
            gesture.released.connect (on_button_released);
            this.add_controller (gesture);
        }

        private void on_button_released (int n_press, double x, double y) {
            uint button = gesture.get_current_button ();
            ClickType click_type = ClickType.from_button (button);

            ClickAction? action = get_action_for_click (click_type);
            if (action == null || action.command == null) {
                return;
            }

            // Handle toggle mode for left click only
            if (is_toggle_mode && click_type == ClickType.LEFT) {
                toggle_state = !toggle_state;
                if (toggle_state) {
                    this.add_css_class ("active");
                } else {
                    this.remove_css_class ("active");
                }
            }

            // Execute command
            execute_action.begin (action, click_type);
        }

        private ClickAction? get_action_for_click (ClickType click_type) {
            switch (click_type) {
                case ClickType.LEFT:
                    return left_action;
                case ClickType.MIDDLE:
                    return middle_action;
                case ClickType.RIGHT:
                    return right_action;
                default:
                    return null;
            }
        }

        private async void execute_action (ClickAction action, ClickType click_type) {
            if (action.command == null || action.command == "") {
                return;
            }

            string msg = "";
            string[] env_additions = {};

            // Add toggle state for toggle buttons
            if (is_toggle_mode && click_type == ClickType.LEFT) {
                env_additions = { "SWAYNC_TOGGLE_STATE=" + toggle_state.to_string () };
            }

            yield Functions.execute_command (action.command, env_additions, out msg);
        }

        public async void on_update () {
            if (!is_toggle_mode || left_action == null || left_action.update_command == "") {
                return;
            }

            string msg = "";
            string[] env_additions = { "SWAYNC_TOGGLE_STATE=" + toggle_state.to_string () };
            yield Functions.execute_command (left_action.update_command, env_additions, out msg);

            try {
                // Remove trailing whitespaces
                Regex regex = new Regex ("\\s+$");
                string res = regex.replace (msg, msg.length, 0, "");
                // Temporarily block the gesture to prevent triggering during update
                gesture.set_propagation_phase (Gtk.PropagationPhase.NONE);
                if (res.up () == "TRUE") {
                    toggle_state = true;
                    this.add_css_class ("active");
                } else {
                    toggle_state = false;
                    this.remove_css_class ("active");
                }
                gesture.set_propagation_phase (Gtk.PropagationPhase.BUBBLE);
            } catch (RegexError e) {
                stderr.printf ("RegexError: %s\n", e.message);
            }
        }
    }
}
