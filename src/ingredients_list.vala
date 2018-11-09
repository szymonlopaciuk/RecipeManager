using Gtk;
using Pango;
using GLib;
using Cairo;

[GtkTemplate (ui = "/org/gtk/recipe/ui/ingredients_list.ui")]
public class IngredientsList : TreeView
{
    public Gtk.ListStore listmodel;
    private TreeIter iter;
    public signal void query_recipe(ref Recipe? recipe);

    public IngredientsList()
    {
        listmodel = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));
        this.set_model(listmodel);

        var cell_amt = new CellRendererText();
        cell_amt.set("xalign", 1.0);
        cell_amt.editable = true;
        cell_amt.edited.connect((path, text) => {
            string new_text = text.replace("/", "⁄");
            int index = cell_edited(path, new_text, 0);
            Recipe? r = null;
            query_recipe(ref r);
            r.edit_ingredient(index, new_text, null, null);
        });

        var cell_unit = new CellRendererText();
        cell_unit.editable = true;
        cell_unit.edited.connect((path, new_text) => {
            int index = cell_edited(path, new_text, 1);
            Recipe? r = null;
            query_recipe(ref r);
            r.edit_ingredient(index, null, new_text, null);
        });

        var cell_ing = new CellRendererText();
        cell_ing.editable = true;
        cell_ing.edited.connect((path, new_text) => {
            int index = cell_edited(path, new_text, 2);
            Recipe? r = null;
            query_recipe(ref r);
            r.edit_ingredient(index, null, null, new_text);
        });

        this.insert_column_with_attributes(-1, "Amt", cell_amt, "text", 0);
        this.insert_column_with_attributes(-1, "Unit", cell_unit, "text", 1);
        this.insert_column_with_attributes(-1, "Ingredient", cell_ing, "text", 2, "foreground", 3);
    }

    private int cell_edited(string path, string new_text, int column)
    {
        var tree_path = new TreePath.from_string(path);
        int index = tree_path.get_indices()[0];
        TreeIter it;
        listmodel.get_iter_from_string(out it, path);
        listmodel.set(it, column, new_text);
        return index;
    }

    public void add_ingredient(string ammount, string unit, string name)
    {
        listmodel.append(out iter);
        listmodel.set(iter, 0, ammount, 1, unit, 2, name);
    }

    public void clear()
    {
        listmodel.clear();
    }

    public int get_selected_index()
    {
        TreeModel model;
        List<TreePath> path = this.get_selection().get_selected_rows(out model);
        if (path != null && model != null)
        {
            var p = path.nth_data(0);
            return p.get_indices()[0];
        }
        else return -1;
    }

    public void remove_selected()
    {
        TreeModel model;
        List<TreePath> paths = this.get_selection().get_selected_rows(out model);
        if (paths != null && model != null)
        {
            foreach (var p in paths)
            {
                TreeIter it;

                int index = p.get_indices()[0];
                Recipe? r = null;
                query_recipe(ref r);
                r.delete_ingredient(index);

                model.get_iter(out it, p);
                listmodel.remove(ref it);
            }
        }
    }
}
