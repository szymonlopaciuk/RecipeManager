using Gtk;
using Pango;
using GLib;
using Cairo;

public string? application_conf_file = null;
public string? application_library = null;

int main (string[] args)
{
    application_conf_file = GLib.Environment.get_user_config_dir() + "/recipe-manager.conf";
    var file = File.new_for_path(application_conf_file);
    try {
        if (file.query_exists())
        {
            var dis = new DataInputStream(file.read());
            application_library = dis.read_line(null);
            stdout.printf("%s\n", application_library);
        }
    } catch (Error e)
    {
        error("%s", e.message);
    }

    Gtk.init (ref args);
    
    var window = new RecipeWindow();
    window.set_last_folder(application_library);
    window.show_all();
    
    Gtk.main();
    return 0;
}
