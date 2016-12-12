using GLib;
using Gtk;

[GtkTemplate (ui = "/org/gtk/recipe/ui/preferences_window.ui")]
public class PreferencesWindow : Window
{
    [GtkChild] private FileChooserButton rc_file_chooser;
    [GtkChild] private ComboBox locale_chooser;
    [GtkChild] private FontButton print_font_chooser;
    private RecipeWindow parent;

    public PreferencesWindow(RecipeWindow parent)
    {
        this.parent = parent;
        if (current_application.library != null)
        {
            rc_file_chooser.select_filename(current_application.library);
        }
        rc_file_chooser.file_set.connect(set_library_location);


        var store = new Gtk.ListStore(1, typeof(string));
        Json.Object locales = PreferenceStorage.settings.get_object_member("locale_list");
        int i = 0, n = 0;
        locales.foreach_member((object, member_name, member_node) => {
            TreeIter iter;
	        store.append(out iter);
	        store.set(iter, 0, member_name);
	        if (member_name == PreferenceStorage.settings.get_string_member("locale")) n = i;
	        i++;
        });

        locale_chooser.set_model(store);
        var cell = new Gtk.CellRendererText();
        locale_chooser.pack_start(cell, false);
        locale_chooser.set_attributes(cell, "text", 0);
        locale_chooser.set_active(n);
        locale_chooser.changed.connect(set_locale);

        string? font = PreferenceStorage.settings.get_string_member("print_font");
        if (font == null) font = "Pira Sans 11";
        print_font_chooser.set_font_name(font);
        print_font_chooser.font_set.connect(set_font);
    }

    private void set_font()
    {
        string font = print_font_chooser.get_font_name();
        PreferenceStorage.settings.set_string_member("print_font", font);
        PreferenceStorage.save();
    }

    private void set_locale()
    {
        TreeIter iter;
        locale_chooser.get_active_iter(out iter);
        GLib.Value locale;
        locale_chooser.get_model().get_value(iter, 0, out locale);
        current_application.locale = (string?)locale;
        PreferenceStorage.settings.set_string_member("locale", current_application.locale);
        PreferenceStorage.save();
    }

    private void set_library_location()
    {
        current_application.library = rc_file_chooser.get_filename() + "/";
        PreferenceStorage.settings.set_string_member("library", current_application.library);
        PreferenceStorage.save();
        parent.notify_library_changed();
    }
}
