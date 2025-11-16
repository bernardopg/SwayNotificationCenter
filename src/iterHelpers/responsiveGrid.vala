using Gtk;

public class ResponsiveGrid : Gtk.Grid {
    public uint length { get; private set; default = 0; }
    public int columns { get; set; default = 1; }
    public bool responsive { get; set; default = false; }

    private List<Gtk.Widget> children = new List<Gtk.Widget> ();
    private int current_row = 0;
    private int current_col = 0;

    public ResponsiveGrid (int columns = 1, bool responsive = false) {
        Object (
            columns: columns,
            responsive: responsive,
            column_homogeneous: true,
            row_spacing: 0,
            column_spacing: 0
        );
        set_name ("responsive-grid");

        // Watch for size changes if responsive mode is enabled
        if (responsive) {
            this.notify["default-width"].connect (on_width_changed);
        }
    }

    public override void dispose () {
        foreach (Gtk.Widget child in children) {
            remove (child);
        }

        base.dispose ();
    }

    private void on_add (Gtk.Widget child) {
        length++;
        child.destroy.connect (() => {
            children.remove (child);
            reorganize_children ();
        });
    }

    private void on_width_changed () {
        if (!responsive) return;

        int width = get_allocated_width ();
        int new_columns = calculate_columns_for_width (width);

        if (new_columns != columns) {
            columns = new_columns;
            reorganize_children ();
        }
    }

    private int calculate_columns_for_width (int width) {
        // Responsive breakpoints
        if (width < 400) return 1;
        if (width < 800) return 2;
        if (width < 1200) return 3;
        return 4;
    }

    private void reorganize_children () {
        // Remove all children from grid
        foreach (Gtk.Widget child in children) {
            base.remove (child);
        }

        // Re-add children in new grid layout
        current_row = 0;
        current_col = 0;

        foreach (Gtk.Widget child in children) {
            attach (child, current_col, current_row, 1, 1);

            current_col++;
            if (current_col >= columns) {
                current_col = 0;
                current_row++;
            }
        }
    }

    public List<weak Gtk.Widget> get_children () {
        return children.copy ();
    }

    public void append (Gtk.Widget child) {
        children.append (child);
        Gtk.Widget added_child = children.last ().data;

        child.set_hexpand (true);
        child.set_vexpand (false);

        attach (added_child, current_col, current_row, 1, 1);

        current_col++;
        if (current_col >= columns) {
            current_col = 0;
            current_row++;
        }

        on_add (child);
    }

    public void prepend (Gtk.Widget child) {
        children.prepend (child);
        current_row = 0;
        current_col = 0;
        reorganize_children ();
        on_add (child);
    }

    public new void remove (Gtk.Widget child) {
        children.remove (child);
        base.remove (child);
        length--;
        reorganize_children ();
    }
}
