static const string[] food_courses = {"Not specified", "Appetizer", "Beverage", "Bread", "Dessert", "Finger food", "Main dish",
                                      "Salad", "Side Dish",  "Snack", "Soup or stew"};

static const string[] food_meals = {"Not specified", "Breakfast", "Brunch", "Lunch", "Dinner", "Other"};

static Array<string> recipe_locales;
static Array<string> recipe_locale_names;

int index_of(string str, string[] list)
{
    for (int i = 0; i < list.length; i++)
        if (list[i] == str) return i;
    return 0;
}
