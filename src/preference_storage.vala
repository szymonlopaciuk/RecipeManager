using GLib;

public class PreferenceStorage
{
    public static Json.Object settings;
    public static string conf_file;

    public static void init()
    {
        conf_file = GLib.Environment.get_user_config_dir() + "/recipe-manager-conf.json";
    }

    public static bool exists()
    {
        var file = File.new_for_path(conf_file);
        try {
            if (file.query_exists()) return true;
        } catch (Error e)
        {
            current_application.quit();
            error("%s", e.message);
        }
        return false;
    }

    public static void make()
    {
        //var file = File.new_for_path(conf_file);
        //var file_stream = file.create(FileCreateFlags.NONE);

        settings = new Json.Object();
        var generator = new Json.Generator();
        var root = new Json.Node(Json.NodeType.OBJECT);
        root.set_object(settings);
        generator.set_root(root);
        generator.set_pretty(true);
        generator.set_indent(2);
        generator.set_indent_char(' ');
        generator.to_file(conf_file);
    }

    public static void save() throws GLib.Error
    {
        var generator = new Json.Generator();
        var root = new Json.Node(Json.NodeType.OBJECT);
        root.set_object(settings);
        generator.set_root(root);
        generator.set_pretty(true);
        generator.set_indent(2);
        generator.set_indent_char(' ');
        generator.to_file(conf_file);

        update_locale_list();
    }

    public static void load() throws GLib.Error
    {
        var parser = new Json.Parser();
        parser.load_from_file(conf_file);
        var root = parser.get_root();
        settings = root.get_object();

        update_locale_list();
    }

    public static void update_locale_list()
    {
        recipe_locales = new Array<string>();
        recipe_locale_names = new Array<string>();
        settings.get_object_member("locale_list").foreach_member((object, member_name, member_node) => {
            recipe_locales.append_val(member_name);
            string n = member_node.get_object().get_string_member("name");
            recipe_locale_names.append_val(n);
        });
    }

    public static string translate_to_locale(string locale, string word)
    {
        string? translation = settings.get_object_member("locale_list")
            .get_object_member(locale)
            .get_object_member("translations")
            .get_string_member(word);
        if (translation == null) return word;
        else return translation;
    }
}
