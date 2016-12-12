using GLib;
using Gtk;

public class ConverterDialog
{
    public signal void convert(Converter.UnitSystem unit_system, int response);
    private Dialog dialog;
    public ConverterDialog(Gtk.Window parent)
    {
        var store = new Gtk.ListStore(1, typeof(string));
        foreach (var sys in Converter.UnitSystem.all())
        {
            TreeIter iter;
	        store.append(out iter);
	        store.set(iter, 0, sys.to_string());
        }
        var combo = new ComboBox.with_model(store);
        var cell = new Gtk.CellRendererText();
        combo.pack_start(cell, false);
        combo.set_attributes(cell, "text", 0);
        int active = 0;
        combo.set_active(active);

        var box = new Box(Gtk.Orientation.VERTICAL, 12);
        box.set_border_width(10);
        box.add(combo);

        var lbl_vol = this.add_unit_set("Volume:", "various", ref box);
        var lbl_len = this.add_unit_set("Length:", "various", ref box);
        var lbl_wei = this.add_unit_set("Weight:", "various", ref box);
        var lbl_tem = this.add_unit_set("Temperature:", "various", ref box);

        combo.changed.connect(() => {
            active = combo.get_active();
            switch (active)
            {
                case Converter.UnitSystem.REVERT:
                    lbl_vol.set_text("various");
                    lbl_len.set_text("various");
                    lbl_wei.set_text("various");
                    lbl_tem.set_text("various");
                    break;
                case Converter.UnitSystem.MIXED_METRIC:
                    lbl_vol.set_text("intl cup, l, ml, tsp, tbsp");
                    lbl_len.set_text("cm");
                    lbl_wei.set_text("intl cup, g, kg, tsp, tbsp");
                    lbl_tem.set_text("°C");
                    break;
                case Converter.UnitSystem.US:
                    lbl_vol.set_text("US cup, US pint, US fl.oz., tsp, tbsp");
                    lbl_len.set_text("inch");
                    lbl_wei.set_text("US cup, tsp, tbsp, lb, oz");
                    lbl_tem.set_text("°F");
                    break;
                case Converter.UnitSystem.UK:
                    lbl_vol.set_text("UK cup, UK pint, UK fl oz, tsp, tbsp");
                    lbl_len.set_text("inch");
                    lbl_wei.set_text("UK cup, tsp, tbsp, lb, oz");
                    lbl_tem.set_text("°C");
                    break;
                case Converter.UnitSystem.METRIC:
                    lbl_vol.set_text("l, ml");
                    lbl_len.set_text("cm");
                    lbl_wei.set_text("g, kg");
                    lbl_tem.set_text("°C");
                    break;
                default: assert_not_reached();
            }
        });

        dialog = new Dialog.with_buttons(
            "Select system of measurement",
            parent,
            Gtk.DialogFlags.USE_HEADER_BAR |
            Gtk.DialogFlags.MODAL |
            Gtk.DialogFlags.DESTROY_WITH_PARENT);

        dialog.set_transient_for(parent);
        dialog.set_default_size(545, 133);
        dialog.get_content_area().add(box);
        dialog.add_button("View", Gtk.ResponseType.ACCEPT);
        dialog.add_button("Convert", Gtk.ResponseType.APPLY);
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL);
        dialog.set_default_response(ResponseType.ACCEPT);
        dialog.response.connect((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT)
            {
                convert((Converter.UnitSystem)combo.get_active(), response_id);
            }
            else if (response_id == Gtk.ResponseType.APPLY)
            {
                var msg = new Gtk.MessageDialog(parent,
                                                   Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.ERROR,
                                                   Gtk.ButtonsType.YES_NO,
                                                   "All units will be changed. You will still be able to revert to your " +
                                                   "original file, until it's overwritten. Do you want to continue?");
                msg.set_title("Units will be changed");
                if (msg.run() == Gtk.ResponseType.YES)
                {
                    convert((Converter.UnitSystem)combo.get_active(), response_id);
                }
                msg.destroy();
            }
            dialog.destroy();
        });
    }

    public void show_all()
    {
        dialog.show_all();
    }

    private Label add_unit_set(string set, string units, ref Box box)
    {
        var font = Pango.FontDescription.from_string("bold");
        var box_unit = new Box(Gtk.Orientation.HORIZONTAL, 10);
        var lbl_unit = new Label(set);
        lbl_unit.override_font(font);
        var lbl_unit_desc = new Label(units);
        box_unit.add(lbl_unit);
        box_unit.add(lbl_unit_desc);
        box.add(box_unit);
        return lbl_unit_desc;
    }
}
