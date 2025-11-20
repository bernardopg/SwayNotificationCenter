namespace SwayNotificationCenter.Widgets {
    public class Dnd : BaseWidget {
        public override string widget_name {
            get {
                return "dnd";
            }
        }

        Gtk.Label title_widget;
        Gtk.Image icon_widget;
        Gtk.Switch dnd_button;

        // Default config values
        string title = "Do Not Disturb";
        bool show_label = true;

        public Dnd (string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon) {
            base (suffix, swaync_daemon, noti_daemon);

            Json.Object ?config = get_config (this);
            if (config != null) {
                // Get title
                string ?title = get_prop<string> (config, "text");
                if (title != null) {
                    this.title = title;
                }
                // Get show-label
                bool ?show_label = get_prop<bool> (config, "show-label");
                if (show_label != null) {
                    this.show_label = show_label;
                }
            }

            // Apply compact CSS class if label is hidden
            if (!show_label) {
                add_css_class ("compact");
            }

            // Icon (only visible in compact mode)
            icon_widget = new Gtk.Image.from_icon_name ("notifications-symbolic");
            icon_widget.set_pixel_size (20);
            icon_widget.set_visible (!show_label);
            append (icon_widget);

            // Title
            title_widget = new Gtk.Label (title);
            title_widget.set_hexpand (true);
            title_widget.set_halign (Gtk.Align.START);
            title_widget.set_visible (show_label);
            append (title_widget);

            // Dnd button
            dnd_button = new Gtk.Switch () {
                active = noti_daemon.dnd,
            };
            dnd_button.notify["active"].connect (switch_active_changed_cb);
            noti_daemon.on_dnd_toggle.connect ((dnd) => {
                dnd_button.notify["active"].disconnect (switch_active_changed_cb);
                dnd_button.set_active (dnd);
                dnd_button.notify["active"].connect (switch_active_changed_cb);
                // Update icon based on DND state
                update_icon (dnd);
            });

            dnd_button.valign = Gtk.Align.CENTER;
            // Backwards compatible towards older CSS stylesheets
            dnd_button.add_css_class ("control-center-dnd");
            append (dnd_button);

            // Set tooltip text (especially useful in compact mode)
            set_tooltip_text (title);

            // Initialize icon state
            update_icon (noti_daemon.dnd);

            // Set accessible name and label for screen readers
            dnd_button.update_property (
                Gtk.AccessibleProperty.LABEL,
                title,
                -1
            );
            dnd_button.update_property (
                Gtk.AccessibleProperty.DESCRIPTION,
                title,
                -1
            );
        }

        private void update_icon (bool dnd) {
            if (!show_label) {
                // Update icon based on DND state
                icon_widget.set_from_icon_name (dnd ? "notifications-disabled-symbolic" : "notifications-symbolic");
            }
        }

        private void switch_active_changed_cb () {
            noti_daemon.dnd = dnd_button.active;
        }
    }
}
