using GLib;
using Pango;
using Gtk;

public class RecipePopover : Gtk.Popover
{
    private Pango.FontDescription title_font;
    private Pango.FontDescription path_font;
    private Box list_container;
    private CssProvider css_provider;
    private int button_height = 55;
    private int popover_width = 300;
    private int max_children_at_once = 8;
    private ScrolledWindow scroll;
    
    public signal void recipe_clicked(string path);
    public signal void recipe_open_other();
    public signal void recipe_save_as();
    public signal void recipe_new();
    
    public RecipePopover()
    {
        this.title_font = Pango.FontDescription.from_string("12");
        this.path_font = Pango.FontDescription.from_string("9");
    
        this.border_width = 10;
        
        scroll = new ScrolledWindow(null, null);
        
        var box = new Box(Gtk.Orientation.VERTICAL, 5);
        list_container = new Box(Gtk.Orientation.VERTICAL, 0);
        
        string css =
            "GtkButton {
                background: #FFFFFF;
                border-width: 1px;
                border-top-width: 0px;
                border-color: #AAAAAA;
                padding: 10px;
                border-radius: 0;
            }
            
            GtkButton:first-child {
                border-top-width: 1px;
            }
            
            GtkButton:hover {
                background-image: none;
                border-image: none;
                transition: 0.3s linear;
                background: #F2F2F2;
                border-radius: 0;
            }";
            
        css_provider = new CssProvider();
        css_provider.load_from_data(css, css.length);
        
        refresh();
        
        scroll.add(list_container);
        
        var file_manip = new Box(Gtk.Orientation.HORIZONTAL, 0);
        
        var open_other_button = new Button.with_label("Other Recipes...");
        open_other_button.set_size_request(popover_width/3, -1);
        open_other_button.clicked.connect(() => {
            this.hide();
            recipe_open_other();
        });
        file_manip.add(open_other_button);
        var save_as_button = new Button.with_label("Save As...");
        save_as_button.set_size_request(popover_width/3, -1);
        save_as_button.clicked.connect(() => {
            this.hide();
            recipe_save_as();
        });
        file_manip.add(save_as_button);
        var new_button = new Button.with_label("Create new...");
        new_button.set_size_request(popover_width/3, -1);
        new_button.clicked.connect(() => {
            this.hide();
            recipe_new();
        });
        file_manip.add(new_button);
        file_manip.get_style_context().add_class("linked");
        
        box.add(file_manip);
        
        box.add(scroll);
        this.add(box);
        box.show_all();
    }
    
    /*public override void show()
    {
        refresh();
        base.show();
    }*/
    
    public void refresh()
    {
        list_container.foreach((widget) => {
            widget.destroy();
        });
        
        var dir = Dir.open(current_application.library);
        string file_name;
        TreeIter iter;
        int n_children = 0;
        while ((file_name = dir.read_name()) != null)
        {
            var file_box = make_file_label(file_name);
            if (file_box == null) continue;
            file_box.get_preferred_height(null, out this.button_height);
            list_container.add(file_box);
            var style_context = file_box.get_style_context();
            style_context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            n_children++;
        }
        if (n_children > max_children_at_once) n_children = max_children_at_once;
        int height = 1 + (8 + button_height) * n_children;
        scroll.set_size_request(popover_width, height);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    }
    
    private Button? make_file_label(string fname)
    {
        Recipe r;
        try {
            r = new Recipe("").deserialize(current_application.library + fname);
        } catch (GLib.Error e)
        {
            return null;
        }
        var button = new Button();
        button.clicked.connect(() => {
            recipe_clicked(current_application.library + fname);
            this.hide();
        });
        var box = new Box(Gtk.Orientation.VERTICAL, 5);
        var title = new Label(r.title);
        var location = new Label("fname");
        location.set_markup("<span color=\"#AAAAAA\">" + fname + "</span>");
        title.set_alignment(0, 0);
        location.set_alignment(0, 0);
        title.override_font(title_font);
        location.override_font(path_font);
        box.add(title);
        box.add(location);
        button.add(box);
        button.show_all();
        return button;
    }
}
