using Gtk;
using Pango;
using GLib;
using Cairo;

RecipeApplication current_application;

int main (string[] args)
{    
    current_application = new RecipeApplication();
    return current_application.run(args);
}
