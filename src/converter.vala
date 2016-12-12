using GLib;
using Gtk;

public class Converter
{
    public enum UnitSystem
    {
        REVERT,
        MIXED_METRIC,
        US,
        UK,
        METRIC;

        public string to_string() {
            switch (this) {
                case REVERT: return "Revert to original";
                case MIXED_METRIC: return "Traditional Metric";
                case US: return "Traditional US";
                case UK: return "Traditional UK";
                case METRIC: return "Fully Metric";
                default: assert_not_reached();
            }
        }

        public bool is_in(UnitSystem[]? systems)
        {
            if (systems == null) return false;
            foreach (var sys in systems)
            {
                if (sys == this) return true;
            }
            return false;
        }

        public bool is_based_on_fractions()
        {
            return (this == US || this == UK);
        }

        public static UnitSystem[] all() {
            return { REVERT, MIXED_METRIC, US, UK, METRIC };
        }
    }

    private struct UnitSpecification
    {
        string name;
        UnitClass type;
        Regex pattern;
        unowned Conversion to;
        unowned Conversion from;
        UnitSystem[] systems;
        bool can_be_frac;
        double precision;
        bool traditional; //e.g. teaspoons and cups are traditional, oz an g are not -- traditional units are preferred

        public UnitSpecification add(HashTable<string, UnitSpecification?> units)
        {
            units.insert(name, this);
            return this;
        }

        public UnitSpecification basic(HashTable<string, UnitSpecification?> units)
        {
            units.insert(type.to_string(), this);
            return this;
        }
    }

    private enum UnitClass
    {
        VOLUME,
        WEIGHT,
        LENGTH,
        TEMPERATURE
    }


    private UnitSystem system;
    private HashTable<string, UnitSpecification?> units;
    private delegate double Conversion(double n);
    private const int max_traditional = 6; // max reasonable amount of traditional units, e.g. 6 cups
    private string preferred_locale;

    public Converter(UnitSystem unit_system, string locale)
    {
        this.preferred_locale = locale;
        if (unit_system == UnitSystem.REVERT) return;

        units = new HashTable<string, UnitSpecification?>(GLib.str_hash, GLib.str_equal);
        system = unit_system;
        try {
            create_units();
        }
        catch (RegexError e)
        {
            Gtk.main_quit();
        }
    }

    private void create_units() throws RegexError
    {
        /* VOLUME */
        UnitSpecification()
        {
            name = "ml",
            type = UnitClass.VOLUME,
            pattern = new Regex("^(m(l|L)|mililit(er|re))$"),
            to = (n) => { return n; },
            from = (n) => { return n; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC },
            can_be_frac = false,
            precision = 1,
            traditional = false
        }.add(units).basic(units);

        UnitSpecification()
        {
            name = "l",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((L|l)\\.?|lit(er|re))$"),
            to = (n) => { return n * (1 / 1000.0); },
            from = (n) => { return n * 1000.0; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC },
            can_be_frac = false,
            precision = 0.01,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "US cup",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((US |U\\.S\\. )?(C|cup))$"),
            to = (n) => { return n * (1 / 236.59); },
            from = (n) => { return n * 236.59; },
            systems = { UnitSystem.US },
            can_be_frac = true,
            precision = 0.1,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "UK cup",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((UK|U\\.K\\.) (C|cup))$"),
            to = (n) => { return n * (1 / 284.1); },
            from = (n) => { return n * 284.1; },
            systems = { UnitSystem.UK },
            can_be_frac = true,
            precision = 0.1,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "intl cup",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((intl|international|Intl) (C|cup))$"),
            to = (n) => { return n * (1 / 250.0); },
            from = (n) => { return n * 250.0; },
            systems = { UnitSystem.MIXED_METRIC },
            can_be_frac = true,
            precision = 0.1,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "tsp",
            type = UnitClass.VOLUME,
            pattern = new Regex("^(t(\\.|ea)?( )?sp(\\.|oon)?)$"),
            to = (n) => { return n * (1 / 5.0); },
            from = (n) => { return n * 5.0; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.US, UnitSystem.UK },
            can_be_frac = true,
            precision = 0.5,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "tbsp",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((table|tb|Tb|T)?\\.?( )?sp(\\.|oon)?)$"),
            to = (n) => { return n * (1 / 15.0); },
            from = (n) => { return n * 15.0; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.US, UnitSystem.UK },
            can_be_frac = true,
            precision = 0.5,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "US fl.oz.",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((US |U\\.S\\. )?(fl\\.?|fluid)( )?(oz\\.?|ounce))$"),
            to = (n) => { return n * (1 / 29.57); },
            from = (n) => { return n * 29.57; },
            systems = { UnitSystem.US },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "UK fl oz",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((UK|U\\.K\\.)( )(fl\\.?|fluid)( )?(oz\\.?|ounce))$"),
            to = (n) => { return n * (1 / 28.41); },
            from = (n) => { return n * 28.41; },
            systems = { UnitSystem.UK },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "US pt.",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((US |U\\.S\\. )?(pt\\.?|pint))$"),
            to = (n) => { return n * (1 / 473.18); },
            from = (n) => { return n * 473.18; },
            systems = { UnitSystem.US },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "UK pt",
            type = UnitClass.VOLUME,
            pattern = new Regex("^((UK|U\\.K\\.)( )(pt\\.?|pint))$"),
            to = (n) => { return n * (1 / 568.26); },
            from = (n) => { return n * 568.26; },
            systems = { UnitSystem.UK },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        /* WEIGHT */
        UnitSpecification()
        {
            name = "g",
            type = UnitClass.WEIGHT,
            pattern = new Regex("^((g|G)\\.?|gram(me)?|gr\\.?)$"),
            to = (n) => { return n; },
            from = (n) => { return n; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC },
            can_be_frac = false,
            precision = 1,
            traditional = false
        }.add(units).basic(units);

        UnitSpecification()
        {
            name = "kg",
            type = UnitClass.WEIGHT,
            pattern = new Regex("^((k|K)(g|G)\\.?|kilogram(me)?|(K|k)gr\\.?)$"),
            to = (n) => { return n * (1 / 1000.0); },
            from = (n) => { return n * 1000.0; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC },
            can_be_frac = false,
            precision = 0.01,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "lb",
            type = UnitClass.WEIGHT,
            pattern = new Regex("^(libre|libr\\.|lb(m)?\\.?|℔|pound(s)?)$"),
            to = (n) => { return n * (1 / 453.59); },
            from = (n) => { return n * 453.59; },
            systems = { UnitSystem.US, UnitSystem.UK },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        UnitSpecification()
        {
            name = "stick",
            type = UnitClass.WEIGHT,
            pattern = new Regex("^stick(s)?$"),
            to = (n) => { return n * (1 / 113.5); },
            from = (n) => { return n * 113.5; },
            systems = { /*UnitSystem.US*/ },
            can_be_frac = true,
            precision = 0.1,
            traditional = true
        }.add(units);

        UnitSpecification()
        {
            name = "oz",
            type = UnitClass.WEIGHT,
            pattern = new Regex("^(oz?\\.?|℥|ounce(s)?)$"),
            to = (n) => { return n * (1 / 28.35); },
            from = (n) => { return n * 28.35; },
            systems = { UnitSystem.US, UnitSystem.UK },
            can_be_frac = true,
            precision = 0.05,
            traditional = false
        }.add(units);

        /* LENGTH */
        UnitSpecification()
        {
            name = "cm",
            type = UnitClass.LENGTH,
            pattern = new Regex("^(cm\\.?|centimet(er|re))$"),
            to = (n) => { return n; },
            from = (n) => { return n; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC },
            can_be_frac = false,
            precision = 0.1,
            traditional = false
        }.add(units).basic(units);

        UnitSpecification()
        {
            name = "in.",
            type = UnitClass.LENGTH,
            pattern = new Regex("^(in\\.?|inch(es)?|\")$"),
            to = (n) => { return n * (1 / 2.54); },
            from = (n) => { return n * 2.54; },
            systems = { UnitSystem.US, UnitSystem.UK },
            can_be_frac = true,
            precision = 0.1,
            traditional = false
        }.add(units);

        /* TEMPERATURE */
        UnitSpecification()
        {
            name = "°C",
            type = UnitClass.TEMPERATURE,
            pattern = new Regex("^(°|\\*|deg(\\.|ree)? )((C|c)(elsius)?)$"),
            to = (n) => { return n; },
            from = (n) => { return n; },
            systems = { UnitSystem.MIXED_METRIC, UnitSystem.METRIC, UnitSystem.UK },
            can_be_frac = false,
            precision = 10,
            traditional = false
        }.add(units).basic(units);

        UnitSpecification()
        {
            name = "°F",
            type = UnitClass.TEMPERATURE,
            pattern = new Regex("^(°|\\*|deg(\\.|ree)? )((F|f)(ahrenheit)?)$"),
            to = (n) => { return 32 + (9.0/5.0) * n; },
            from = (n) => { return (5.0/9.0) * (n - 32); },
            systems = { UnitSystem.US },
            can_be_frac = false,
            precision = 10,
            traditional = false
        }.add(units);
    }

    public Recipe.Ingredient convert(Recipe.Ingredient ingredient)
    {
        if (system == UnitSystem.REVERT)
        {
            return ingredient;
        }

        Regex frac_regex, dec_regex;
        bool frac = false, dec = false;

        try {
            frac_regex = new Regex("^(\\d+ )?\\d+⁄\\d+$");
            frac = frac_regex.match(ingredient.amount);
            dec_regex = new Regex("^\\d+(\\.\\d+)?$");
            dec = dec_regex.match(ingredient.amount);
        } catch (GLib.RegexError e)
        {
            Gtk.main_quit();
        }

        double n = -1;

        if (frac)
        {
            n = frac_to_dec(ingredient.amount);
        }
        else if (dec)
        {
            n = double.parse(ingredient.amount);
        }

        string new_unit = "";
        UnitSystem[] accepted_systems = {};
        bool can_be_frac = false;
        double precision = 0.01;
        double converted = arithm_conv(n, ingredient.unit, ref new_unit, ref accepted_systems, ref can_be_frac, ref precision);
        if (ingredient.unit == new_unit && converted == n)
        {
            return ingredient;
        }

        var new_ingredient = Recipe.Ingredient();
        new_ingredient.name = ingredient.name;
        new_ingredient.unit = new_unit;

        if (can_be_frac)
        {
            new_ingredient.amount = to_frac_string(converted);
        }
        else
        {
            char[] buf = new char[double.DTOSTR_BUF_SIZE];
            int precision_f = -(int)Math.log10(precision);
            string num = round(converted, precision).format(buf, "%." + (precision_f > 0 ? precision_f : 0).to_string() + "f");
            new_ingredient.amount = num;
        }
        return new_ingredient;
    }

    public int gcd(int a, int b)
    {
        while (b != 0)
        {
            int t = a % b;
            a = b;
            b = t;
        }
        return a;
    }

    public string to_frac_string(double n)
    {
        int integer, numerator, denominator;
        to_frac(n, out integer, out numerator, out denominator);

        string x = "";
        if (integer == 0 && numerator == 0)
        {
            char[] buf = new char[double.DTOSTR_BUF_SIZE];
            return n.format(buf, "%.2f");
        }
        if (integer != 0) x += integer.to_string();
        if (numerator != 0)
            x += (integer != 0 ? " " : "") + numerator.to_string() + "⁄" + denominator.to_string();
        return x;
    }

    public void to_frac(double n, out int integer, out int numerator, out int denominator)
    {
        integer = (int)Math.floor(n);
        double frac = n - integer;

        denominator = 2;
        int[] denominators = {2, 3, 4, 5, 6};
        numerator = (int)Math.round(frac * denominator);

        foreach (int denom_tmp in denominators)
        {
            double tmp_numerator = Math.round(frac * denom_tmp);
            if (Math.fabs((double)numerator/denominator - frac) > Math.fabs(tmp_numerator/denom_tmp - frac))
            {
                denominator = denom_tmp;
                numerator = (int)tmp_numerator;
            }
        }

        if (numerator == denominator)
        {
            integer++;
            numerator = 0;
        }
    }

    public double round(double n, double precision)
    {
        return Math.floor(n * (1.0 / precision) + 0.5) / (1.0 / precision);
    }

    public double frac_to_dec(string frac)
    {
        MatchInfo mi;
        Regex frac_regex;
        string integer = null, numerator = null, denominator = null;
        try {
            frac_regex = new Regex("(?:(\\d+) )?(\\d+)⁄(\\d+)");
            frac_regex.match(frac, 0, out mi);
            integer = mi.fetch(1);
            numerator = mi.fetch(2);
            denominator = mi.fetch(3);
        } catch (GLib.RegexError e) {
            // This definately shouldn't happen
            Gtk.main_quit();
        }
        double n = 0;
        if (integer != null) n = long.parse(integer);
        n += double.parse(numerator)/long.parse(denominator);
        return n;
    }

    private UnitSpecification? match_unit(string in_unit)
    {
        Json.Object locales = PreferenceStorage.settings.get_object_member("locale_list");
        Json.Object locale_opt = locales.get_object_member(preferred_locale)
            .get_object_member("units");

        UnitSpecification? suitable_locale_unit = null;
        locale_opt.foreach_member((object, member_name, member_node) => {
            var regex = new Regex(member_node.get_string());
            if (regex.match(in_unit))
            {
                suitable_locale_unit = units.get(member_name);
            }
        });
        if (suitable_locale_unit != null) return suitable_locale_unit;

        foreach (string name in units.get_keys())
        {
            UnitSpecification unit = units.get(name);
		    if (unit.pattern.match(in_unit))
		    {
		        return unit;
		    }
	    }
	    return null;
    }

    private double arithm_conv(
        double amount, string in_unit, ref string out_unit, ref UnitSystem[] sys, ref bool can_be_frac, ref double prec)
    {
        var unit_original = match_unit(in_unit);
        if (unit_original == null || (system.is_in(unit_original.systems)))
        {
            out_unit = in_unit;
            if (unit_original != null)
            {
                sys = unit_original.systems;
                can_be_frac = unit_original.can_be_frac;
                prec = unit_original.precision;
            }
            return amount;
        }

        UnitSpecification[] prospective_destinations = {};

	    foreach (string name in units.get_keys())
        {
            UnitSpecification current_unit = units.get(name);
		    if(current_unit.type == unit_original.type && system.is_in(current_unit.systems))
		    {
		        prospective_destinations += current_unit;
		    }
	    }

	    var unit_destination = choose_best_unit(amount, unit_original, prospective_destinations);
	    out_unit = unit_destination.name;
	    can_be_frac = unit_destination.can_be_frac;
	    prec = unit_destination.precision;
        return unit_destination.to(unit_original.from(amount));
    }

    private int bool_to_int(bool x)
    {
        return x ? 1 : -1;
    }

    private UnitSpecification choose_best_unit(double orig_amount, UnitSpecification in_unit, UnitSpecification[] candidates)
    {
        var list = new List<UnitSpecification?>();
        foreach (var unit in candidates)
        {
            list.append(unit);
        }

        list.sort_with_data((a, b) => {
            double c_a, c_b, e_a, e_b;
            e_a = conversion_error(orig_amount, in_unit, a, out c_a);
            e_b = conversion_error(orig_amount, in_unit, b, out c_b);
            if (a.traditional && !b.traditional)
            {
                return bool_to_int(e_a <= 0.07 && c_a <= max_traditional);
            }
            if (b.traditional && !a.traditional)
            {
                return bool_to_int(!(e_b <= 0.07 && c_b <= max_traditional));
            }
            if (a.traditional && b.traditional)
            {
                if (c_a >= max_traditional || c_b >= max_traditional) return bool_to_int(c_a <= c_b);
                if (e_a > 0.07 || e_b > 0.07) return bool_to_int(e_a <= e_b);
                return bool_to_int(c_a <= c_b);
            }
            // if !a.traditional and !b.traditional:
            if (c_a < 1 && c_b < 1) return bool_to_int(c_a >= c_b);
            if (c_a > 1 && c_b > 1) return bool_to_int(c_b > c_a);
            return bool_to_int(c_a >= c_b);
        });

        return list.last().data;
    }

    private double conversion_error(double original, UnitSpecification source, UnitSpecification destination, out double c)
    {
        double converted = destination.to(source.from(original));
        double n;
        if (destination.can_be_frac)
        {
            int integer, numerator, denominator;
            to_frac(converted, out integer, out numerator, out denominator);
            n = integer + (double)numerator/denominator;
        }
        else
        {
            n = round(converted, destination.precision);
        }
        double converted_back = source.to(destination.from(n));
        c = converted;
        return Math.fabs(original - converted_back)/original;
    }
}
