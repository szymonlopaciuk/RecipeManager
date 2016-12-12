using Gtk;
using Pango;
using GLib;
using Cairo;

[GtkTemplate (ui = "/org/gtk/recipe/ui/description_view.ui")]
public class DescriptionView : Box
{
    private TextView directions;
    private TextView notes;
    private Pango.FontDescription font;
    private ComboBox course_combo;
    private ComboBox meal_combo;
    private ComboBox locale_combo;
    public signal void recipe_change_locale(string locale);

    public DescriptionView()
    {
        this.set_orientation(Gtk.Orientation.VERTICAL);
        this.set_spacing(10);
        this.set_border_width(10);

        font = Pango.FontDescription.from_string("bold 12");

        var category_box = new Box(Gtk.Orientation.HORIZONTAL, 10);
        var course_box = make_combo_and_label("Course: ", food_courses, out course_combo);
        var meal_box = make_combo_and_label("Meal: ", food_meals, out meal_combo);
        var locale_box = make_combo_and_label("Language: ", recipe_locale_names.data, out locale_combo);
        locale_combo.changed.connect(() => {
            recipe_change_locale(get_locale());
        });

        category_box.add(course_box);
        category_box.add(meal_box);
        category_box.add(locale_box);

        var directions_title = new Label("Directions");
        directions_title.override_font(font);
        directions_title.set_alignment(0, 0);

        var notes_title = new Label("Notes");
        notes_title.override_font(font);
        notes_title.set_alignment(0, 0);

        directions = new TextView();
        directions.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
        directions.set_justification(Gtk.Justification.FILL);

        notes = new TextView();
        notes.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
        notes.set_justification(Gtk.Justification.FILL);

        this.add(category_box);
        this.add(directions_title);
        this.add(directions);
        this.add(notes_title);
        this.add(notes);
    }

    public void set_directions(string? text)
    {
        if (text != null)
            directions.get_buffer().set_text(text);
    }

    public void set_notes(string? text)
    {
        if (text != null)
            notes.get_buffer().set_text(text);
    }

    public string get_directions()
    {
        return directions.get_buffer().text;
    }

    public string get_notes()
    {
        return notes.get_buffer().text;
    }

    public void set_course(string? str)
    {
        if (str != null)
            course_combo.set_active(index_of(str, food_courses));
    }

    public void set_meal(string? str)
    {
        if (str != null)
            meal_combo.set_active(index_of(str, food_meals));
    }

    public void set_locale(string? str)
    {
        if (str != null)
            locale_combo.set_active(index_of(str, recipe_locales.data));
    }

    public string get_course()
    {
        return food_courses[course_combo.get_active()];
    }

    public string get_meal()
    {
        return food_meals[meal_combo.get_active()];
    }

    public string get_locale()
    {
        return recipe_locales.data[locale_combo.get_active()];
    }

    public Box make_combo_and_label(string title, string[] items, out ComboBox combo)
    {
        var store = new Gtk.ListStore(1, typeof(string));
        for (int i = 0; i < items.length; i++)
        {
            var item = items[i];
            TreeIter iter;
	        store.append(out iter);
	        store.set(iter, 0, item);
        }

        combo = new ComboBox.with_model(store);
        var cell = new Gtk.CellRendererText();
        combo.pack_start(cell, false);
        combo.set_attributes(cell, "text", 0);
        combo.set_active(0);

        var box = new Box(Gtk.Orientation.HORIZONTAL, 10);
        box.set_border_width(0);
        var label = new Label(title);
        box.add(label);
        box.add(combo);
        return box;
    }
}
