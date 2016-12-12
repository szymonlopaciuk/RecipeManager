using Gtk;
using Pango;
using GLib;
using Cairo;

[GtkTemplate (ui = "/org/gtk/recipe/ui/recipe_window.ui")]
public class RecipeWindow : ApplicationWindow
{
    private Recipe recipe;
    string last_folder = GLib.Environment.get_home_dir();
    private IngredientsList list;
    private DescriptionView desc;
    private RecipePopover popover;
    private string? saved_file_path = null;

    [GtkChild] private HeaderBar header;

    [GtkChild] private Button del_button;
    [GtkChild] private Button add_button;
    [GtkChild] private Button save_button;
    [GtkChild] private Button rename_button;
    [GtkChild] private Button print_button;
    [GtkChild] private Button convert_button;
    [GtkChild] private MenuButton open_recipe_button;

    [GtkChild] private ScrolledWindow scroll1;
    [GtkChild] private ScrolledWindow scroll2;

    public RecipeWindow(RecipeApplication application)
    {
        GLib.Object(application: application);

        var bg_color = Gdk.RGBA();
        bg_color.parse("white");
        this.override_background_color(Gtk.StateFlags.NORMAL, bg_color);

	    add_button.clicked.connect (() => {
            recipe.add_ingredient("", "", "unnamed");
            list.add_ingredient("", "", "unnamed");
        });

        del_button.clicked.connect (() => {
            list.remove_selected();
        });

        popover = new RecipePopover();
        popover.recipe_clicked.connect((path) => {
            open_recipe(path);
        });
        popover.recipe_save_as.connect(() => { save_as(); });
        popover.recipe_open_other.connect(() => { open_other(); });
        popover.recipe_new.connect (() => {
            string name = "Unnamed recipe";
            saved_file_path = null;
            var entry = new Entry();
            entry.text = name;
            var dialog = new Gtk.Dialog.with_buttons("What's the name of this recipe?",
                                               this,
                                               Gtk.DialogFlags.USE_HEADER_BAR |
                                               Gtk.DialogFlags.MODAL |
                                               Gtk.DialogFlags.DESTROY_WITH_PARENT);
            dialog.set_transient_for(this);
            dialog.set_border_width(10);
            dialog.set_default_size(500, 133);
            dialog.get_content_area().add(entry);
            dialog.add_button("Create", Gtk.ResponseType.ACCEPT);
            dialog.add_button("Cancel", Gtk.ResponseType.CANCEL);
            dialog.set_default_response(ResponseType.ACCEPT);
            dialog.show_all();

            entry.activate.connect(() => {
                new_recipe(entry.text);
                dialog.destroy();
            });
            dialog.response.connect((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT)
                {
                    new_recipe(entry.text);
                }
                dialog.destroy();
            });
        });

        open_recipe_button.set_popover(popover);

        print_button.clicked.connect(() => {
            var r = new Recipe(recipe.title);
            r.notes = desc.get_notes();
            r.directions = desc.get_directions();
            r.meal = desc.get_meal();
            r.course = desc.get_course();
            r.locale = desc.get_locale();
            Gtk.TreeModelForeachFunc process_ingredients = (model, path, iter) => {
                GLib.Value amount = "", unit = "", name = "";
                list.listmodel.get_value(iter, 0, out amount);
                list.listmodel.get_value(iter, 1, out unit);
                list.listmodel.get_value(iter, 2, out name);
                r.add_ingredient((string)amount, (string)unit, (string)name);
                return false;
            };
            list.listmodel.foreach(process_ingredients);
            new PrintRecipe(r, this);
        });

        convert_button.clicked.connect(() => {
            var dialog = new ConverterDialog(this);
            var ing = recipe.all_ingredients();
            int j = 0;
            dialog.convert.connect((unit_system, response) => {
                Gtk.TreeModelForeachFunc convert = (model, path, iter) => {
                    var i = Recipe.Ingredient();
                    i.amount = (string)ing[j].amount;
                    i.unit = (string)ing[j].unit;
                    i.name = (string)ing[j].name;
                    int current_row = path.get_indices()[0];

                    var converter = new Converter(unit_system, recipe.locale);
                    i = converter.convert(i);

                    list.listmodel.set(iter, 0, i.amount, 1, i.unit, 2, i.name);

                    if (response == Gtk.ResponseType.APPLY)
                        recipe.edit_ingredient(current_row, i.amount, i.unit, i.name);
                    j++;
                    return false;
                };
                list.listmodel.foreach(convert);
            });
            dialog.show_all();
        });

        rename_button.clicked.connect(() => {
            var entry = new Entry();
            entry.text = this.recipe.title;
            var dialog = new Gtk.Dialog.with_buttons("What's the name of this recipe?",
                                               this,
                                               Gtk.DialogFlags.USE_HEADER_BAR |
                                               Gtk.DialogFlags.MODAL |
                                               Gtk.DialogFlags.DESTROY_WITH_PARENT);
            dialog.set_transient_for(this);
            dialog.set_border_width(10);
            dialog.set_default_size(500, 133);
            dialog.get_content_area().add(entry);
            dialog.add_button("Create", Gtk.ResponseType.ACCEPT);
            dialog.add_button("Cancel", Gtk.ResponseType.CANCEL);
            dialog.set_default_response(ResponseType.ACCEPT);
            dialog.show_all();

            entry.activate.connect(() => {
                this.recipe.title = entry.text;
                load_recipe(this.recipe);
                dialog.destroy();
            });
            dialog.response.connect((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT)
                {
                    this.recipe.title = entry.text;
                    load_recipe(this.recipe);
                }
                dialog.destroy();
            });
        });

        save_button.clicked.connect(() => {
            save();
        });

        this.border_width = 0;
        this.window_position = WindowPosition.CENTER;

        list = new IngredientsList();
        scroll1.add(list);
        desc = new DescriptionView();
        scroll2.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll2.add(desc);
        new_recipe("Unnamed Recipe");

        desc.recipe_change_locale.connect((locale) => {
            recipe.locale = locale;
        });
    }

    public void open_other()
    {
        var file_chooser = new FileChooserDialog("Open recipe file...", this, FileChooserAction.OPEN);

        file_chooser.add_button("Cancel", ResponseType.CANCEL);
        file_chooser.add_button("Open", ResponseType.ACCEPT);
        file_chooser.set_current_folder(last_folder);
        file_chooser.set_default_response(ResponseType.ACCEPT);

        if (file_chooser.run() == ResponseType.ACCEPT)
        {
            try
            {
                open_recipe(file_chooser.get_filename());
                last_folder = file_chooser.get_current_folder();
            }
            catch (GLib.Error e)
            {
                var dialog = new Gtk.MessageDialog(null,
                                                   Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.ERROR,
                                                   Gtk.ButtonsType.OK,
                                                   e.message);
                dialog.set_title("Error while reading the file");
                dialog.run();
                dialog.destroy();
                file_chooser.destroy();
                return;
            }
        }
        file_chooser.destroy();
    }

    public void save()
    {
        if (saved_file_path == null)
        {
            save_as();
        }
        else
        {
            try
            {
                save_recipe(saved_file_path);
                popover.refresh();
            }
            catch (GLib.Error e)
            {
                var dialog = new Gtk.MessageDialog(null,
                                                   Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.ERROR,
                                                   Gtk.ButtonsType.OK,
                                                   e.message);
                dialog.set_title("Error while saving");
                dialog.run();
                dialog.destroy();
            }
        }
    }

    private void save_as()
    {
        var file_chooser = new FileChooserDialog("Save recipe file...", this, FileChooserAction.SAVE);
        file_chooser.set_current_folder(last_folder);

        file_chooser.add_button("Cancel", ResponseType.CANCEL);
        file_chooser.add_button("Save", ResponseType.ACCEPT);
        file_chooser.set_default_response(ResponseType.ACCEPT);

        if (file_chooser.run() == ResponseType.ACCEPT)
        {
            var file = File.new_for_path(file_chooser.get_filename());
            if (file.query_exists())
            {
                var dialog = new Gtk.MessageDialog(null,
                                                   Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.WARNING,
                                                   Gtk.ButtonsType.YES_NO,
                                                   "Are you sure you want to overwrite selected file?");
                dialog.set_title("File already exists");
                int response = dialog.run();
                dialog.destroy();
                if (response == Gtk.ResponseType.NO)
                {
                    file_chooser.destroy();
                    return;
                }
            }
            try
            {
                last_folder = file_chooser.get_current_folder();
                save_recipe(file_chooser.get_filename());
            }
            catch (GLib.Error e)
            {
                var dialog = new Gtk.MessageDialog(null,
                                                   Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.ERROR,
                                                   Gtk.ButtonsType.OK,
                                                   e.message);
                dialog.set_title("Error while saving");
                dialog.run();
                dialog.destroy();
            }
        }
        file_chooser.destroy();
    }

    private void new_recipe(string name)
    {
        this.recipe = new Recipe(name);
        load_recipe(this.recipe);
    }

    [GtkCallback]
    private void on_destroy()
    {
        application.quit();
    }

    public void set_last_folder(string fname)
    {
        this.last_folder = fname;
    }

    public void save_recipe(string fname) throws GLib.Error
    {
        this.recipe.notes = desc.get_notes();
        this.recipe.directions = desc.get_directions();
        this.recipe.meal = desc.get_meal();
        this.recipe.course = desc.get_course();
        this.recipe.locale = desc.get_locale();
        this.recipe.serialize(fname);
        saved_file_path = fname;
        popover.refresh();
    }

    public void open_recipe(string fname) throws GLib.Error
    {
        this.recipe.deserialize(fname);
        saved_file_path = fname;
        load_recipe(this.recipe);
    }

    public void load_recipe(Recipe r)
    {
        this.recipe = r;
	    header.set_subtitle(this.recipe.title);
	    list.clear();
	    foreach (Recipe.Ingredient i in recipe.all_ingredients())
        {
            list.add_ingredient(i.amount, i.unit, i.name);
        }
        list.query_recipe.connect((ref r) => { r = this.recipe; });
        desc.set_notes(recipe.notes);
        desc.set_directions(recipe.directions);
        desc.set_meal(recipe.meal);
        desc.set_course(recipe.course);
        desc.set_locale(recipe.locale);
    }

    public void notify_library_changed()
    {
        popover.refresh();
    }
}
