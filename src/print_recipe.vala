using Gtk;
using GLib;

public class PrintRecipe : Gtk.PrintOperation
{
    Gtk.Window parent;
    Pango.Layout layout;
    Recipe recipe;
    int[] page_breaks = {};
    delegate string TranslateLambda(string word);

    public PrintRecipe(Recipe _recipe, Gtk.Window _parent)
    {
        this.parent = _parent;
        this.recipe = _recipe;
        this.set_n_pages(1);
        this.draw_page.connect(this.on_draw_page);
        this.done.connect(this.on_done);
        this.begin_print.connect(this.on_begin_print);
        try {
            this.run(Gtk.PrintOperationAction.PRINT_DIALOG, parent);
        } catch (GLib.Error e)
        {
            on_done(Gtk.PrintOperationResult.ERROR);
        }
    }

    public void on_begin_print(PrintContext context)
    {
        layout = context.create_pango_layout();
        //var font = Pango.FontDescription.from_string("Source Serif Pro 11");
        //var font = Pango.FontDescription.from_string("Fira Sans 11");
        string? font_name = PreferenceStorage.settings.get_string_member("print_font");
        if (font_name == null) font_name = "Fira Sans 11";

        var font = Pango.FontDescription.from_string(font_name);

        layout.set_font_description(font);
        double width = 0.8 * context.get_width();
        double height = 0.8 * context.get_height();
        layout.set_width((int)(width * Pango.SCALE));
        layout.set_justify(true);

        TranslateLambda t = (word) => {
            return PreferenceStorage.translate_to_locale(recipe.locale, word);
        };

        string marked_up_text = "<b><span size=\"x-large\">" + recipe.title + "</span></b>\n";
        marked_up_text +=
            (recipe.course != "Not specified" ? t(recipe.course) : "") +
            (recipe.course != "Not specified" && recipe.meal != "Not specified" ? ", " : "") +
            (recipe.meal != "Not specified" ? t(recipe.meal) : "") +
            "\n\n";
        marked_up_text += "<b>" + t("Ingredients") + "</b>\n";
        foreach (var i in recipe.all_ingredients())
        {
            marked_up_text += "  &#8226;  ";
            if (i.amount != "") marked_up_text += i.amount + " ";
            if (i.unit != "") marked_up_text += i.unit + " ";
            marked_up_text += i.name + "\n";
        }
        marked_up_text += "\n<b>" + t("Directions") + "</b>\n" + recipe.directions + "\n\n";

        if (recipe.notes != "")
            marked_up_text += "<b>" + t("Notes") + "</b>\n" + recipe.notes;
        layout.set_markup(marked_up_text, -1);

        int line_count = layout.get_line_count();

        double page_height = 0;
        Pango.LayoutLine layout_line;
        for (int line = 0; line < line_count; ++line)
        {
            Pango.Rectangle ink_rect, logical_rect;

            layout_line = layout.get_line(line);
            layout_line.get_extents(out ink_rect, out logical_rect);

            double line_height = logical_rect.height / 1024.0;

            if (page_height + line_height > height)
            {
                page_breaks += line;
                page_height = 0;
            }

            page_height += line_height;
        }

        set_n_pages(page_breaks.length + 1);
    }

    public void on_draw_page(PrintContext context, int page_nr)
    {
        var cairo_ctx = context.get_cairo_context();
        double width = context.get_width();
        double height = context.get_height();
        cairo_ctx.set_source_rgb(0, 0, 0);

        int start_page_line = 0;
        int end_page_line = 0;

        if(page_nr == 0)
        {
            start_page_line = 0;
        }
        else
        {
            start_page_line = page_breaks[page_nr - 1];
        }

        if(page_nr < (int)(page_breaks.length))
        {
            end_page_line = page_breaks[page_nr];
        }
        else
        {
            end_page_line = layout.get_line_count();
        }

        var layout_iter = layout.get_iter();

        double start_pos = 0;
        int line_index = 0;

        do
        {
            if(line_index >= start_page_line)
            {
                Pango.Rectangle logical_rect;
                var layout_line = layout_iter.get_line_readonly();
                layout_iter.get_line_extents(null, out logical_rect);
                int baseline = layout_iter.get_baseline();

                if (line_index == start_page_line)
                {
                    start_pos = logical_rect.y / 1024.0;
                }

                cairo_ctx.move_to(width * 0.1 + logical_rect.x / 1024.0, height * 0.1 + baseline / 1024.0 - start_pos);

                Pango.cairo_show_layout_line(cairo_ctx, layout_line);
            }
            line_index++;
        }
        while(line_index < end_page_line && layout_iter.next_line());
    }

    void on_done(Gtk.PrintOperationResult result)
    {
        if (result == Gtk.PrintOperationResult.ERROR)
        {
            Gtk.MessageDialog error_dialog = new Gtk.MessageDialog(
                parent, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Printing error");
            error_dialog.run();
        }
    }
}
