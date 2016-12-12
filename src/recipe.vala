using GLib;

public class Recipe
{
    public struct Ingredient
    {
        string amount;
        string unit;
        string name;
    }

    public string locale = "";
    public string title = "";
    public string directions = "";
    public string notes = "";
    public string course = "";
    public string meal = "";

    private Ingredient[] ingredients = {};

    public Recipe(string name)
    {
        this.ingredients = {};
        this.title = name;
        this.locale = PreferenceStorage.settings.get_string_member("locale");
    }

    public void add_ingredient(string amount, string unit, string name)
    {
        ingredients += Ingredient() {amount = amount, unit = unit, name = name};
    }

    public Ingredient[] all_ingredients()
    {
        return this.ingredients;
    }

    public void serialize(string path) throws GLib.Error
    {
        var obj = new Json.Object();
        obj.set_string_member("title", title);
        var arr = new Json.Array();
        foreach (var i in ingredients)
        {
            var elem = new Json.Object();
            elem.set_string_member("amount", i.amount);
            elem.set_string_member("unit", i.unit);
            elem.set_string_member("name", i.name);
            arr.add_object_element(elem);
        }
        obj.set_array_member("ingredients", arr);
        obj.set_string_member("directions", directions);
        obj.set_string_member("notes", notes);
        obj.set_string_member("course", course);
        obj.set_string_member("meal", meal);
        obj.set_string_member("locale", locale);
        var generator = new Json.Generator();
        generator.set_pretty(true);
        generator.set_indent(2);
        generator.set_indent_char(' ');
        var root = new Json.Node(Json.NodeType.OBJECT);
        root.set_object(obj);
        generator.set_root(root);
        generator.to_file(path);
    }

    public Recipe deserialize(string path) throws GLib.Error
    {
        var parser = new Json.Parser();
        parser.load_from_file(path);
        var root = parser.get_root();
        var obj = root.get_object();
        this.title = obj.get_string_member("title");
        this.directions = obj.get_string_member("directions");
        this.notes = obj.get_string_member("notes");
        this.course = obj.get_string_member("course");
        this.meal = obj.get_string_member("meal");
        this.locale = obj.get_string_member("locale");
        if (locale == null) locale = PreferenceStorage.settings.get_string_member("locale");
        var arr = obj.get_array_member("ingredients");
        ingredients = {};
        for (int i = 0; i < arr.get_length(); i++)
        {
            var elem = arr.get_object_element(i);
            add_ingredient(
                elem.get_string_member("amount"),
                elem.get_string_member("unit"),
                elem.get_string_member("name")
            );
        }
        return this;
    }

    public void edit_ingredient(int index, string? amount, string? unit, string? name)
    {
        if (amount != null) ingredients[index].amount = amount;
        if (unit != null) ingredients[index].unit = unit;
        if (name != null) ingredients[index].name = name;
    }

    public void delete_ingredient(int index)
    {
        Ingredient[] new_ing = {};
        for (int i = 0; i < ingredients.length; i++)
        {
            if (i != index) new_ing += ingredients[i];
        }
        ingredients = new_ing;
    }
}
