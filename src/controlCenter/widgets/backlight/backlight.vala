using GLib;

namespace SwayNotificationCenter.Widgets {
    public class Backlight : BaseWidget {
        public override string widget_name {
            get {
                return "backlight";
            }
        }

        BacklightUtil client;

        Gtk.Label label_widget = new Gtk.Label (null);
        Gtk.Scale slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
        Gtk.Label percentage_label = new Gtk.Label ("0%");

        public Backlight (string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon) {
            base (suffix, swaync_daemon, noti_daemon);

            Json.Object ?config = get_config (this);
            if (config != null) {
                string ?label = get_prop<string> (config, "label");
                label_widget.set_label (label ?? "Brightness");
                string device = (get_prop<string> (config, "device") ?? "intel_backlight");
                string subsystem = (get_prop<string> (config, "subsystem") ?? "backlight");
                int min = int.max (0, get_prop<int> (config, "min"));

                switch (subsystem) {
                    default :
                    case "backlight":
                        if (subsystem != "backlight") {
                            info ("Invalid subsystem %s for device %s. " +
                                  "Use 'backlight' or 'leds'. Using default: 'backlight'",
                                  subsystem, device);
                        }
                        client = new BacklightUtil ("backlight", device);
                        slider.set_range (min, 100);
                        break;
                    case "leds":
                        client = new BacklightUtil ("leds", device);
                        slider.set_range (min, this.client.get_max_value ());
                        break;
                }
            }

            this.client.brightness_change.connect ((percent) => {
                if (percent < 0) { // invalid device path
                    set_visible (false);
                } else {
                    slider.set_value (percent);
                    percentage_label.set_label ("%d%%".printf ((int) percent));
                }
            });

            slider.set_draw_value (false);
            slider.set_round_digits (0);
            slider.set_hexpand (true);
            slider.value_changed.connect (() => {
                int percent = (int) slider.get_value ();
                this.client.set_brightness.begin ((float) percent);
                slider.tooltip_text = percent.to_string ();
                percentage_label.set_label ("%d%%".printf (percent));
            });

            percentage_label.add_css_class ("percentage-label");
            percentage_label.set_width_chars (4);
            percentage_label.set_xalign (1.0f);

            Gtk.Box container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            container.append (label_widget);
            container.append (slider);
            container.append (percentage_label);
            append (container);
        }

        public override void on_cc_visibility_change (bool val) {
            if (val) {
                this.client.start ();
            } else {
                this.client.close ();
            }
        }
    }
}
