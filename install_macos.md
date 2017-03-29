---
layout: default
title: Install on macOS
date_modified: 2017-03-29 21:59
categories: [ sidebar, gallery ]
---

# Installation on macOS

## Installing dependencies

You can install dependencies in whichever method you prefer.
My personal favourite is Homebrew, it makes it easy to install packages on macOS.
You can go to [Homebrew's website](https://brew.sh) to find out more, or just run the following command to install it.

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Below is the complete list of dependencies you will need:

    libatk-1.0.0
    libcairo-gobject.2
    libcairo.2
    libgdk-3.0
    libgdk_pixbuf-2.0.0
    libgio-2.0.0
    libglib-2.0.0
    libgobject-2.0.0
    libgtk-3.0
    libjson-glib-1.0.0
    libpango-1.0.0
    libpangocairo-1.0.0

However, you should be able to install all of them just executing:

    brew install pango --without-x11
    brew install cairo --without-x11
    brew install gtk+3 --without-x11
    brew install json-glib

Since we want the app to run natively, we pass the additional option `without-x11`. This will enable GTK to run under Quartz instead of XQuartz.

In order to be able to build the app, you will also need Vala toolchain:

    brew install vala

## Compile

In order to compile the application just execute `make`, the same way you would do it on Linux.
After installing all the dependencies the process should finish without errors.
Recipe Manager is now compiled, however in order to run it properly you will have to install the preferences file manually, since `make install` might mess up with your macOS directory structure, additionally installing things you will not need.

Just copy the `recipe-manager-conf.json` file to `~/.config/` directory:

    cp recipe-manager-conf.json ~/.config/

If you want to use the nice, new Gnome theme with GTK (and you do) you should also create a `settings.ini` file for Gtk.

    nano ~/.config/gtk-3.0/settings.ini

Paste the following contents to the file:

    [Settings]
    gtk-application-prefer-dark-theme = false
    gtk-theme-name = Adwaita
    gtk-icon-theme-name = Adwaita
    gtk-fallback-icon-theme = gnome

These were all the required steps for me. However you you do encounter some problems,
see [this](https://sshader.wordpress.com/2013/12/18/installing-gtk3-with-the-quartz-backend-from-source/) post, as it helped me figure some things out. (Thank you, random stranger on the Internet!)

## Make an App bundle (optional)

This step is absolutely not required, however if you're anything like me,
you like to have a nice app bundle, instead of a random executable file.
If you run into problems, [this guy on StackOverflow](http://stackoverflow.com/a/3251285/7471530)
has some more advice.

### 1. Generate directory structure

A macOS app bundle is nothing else, than a directory with a special structure, like this:

    RecipeManager.app/
     ↳ Contents/
        ↳ Info.plist
          MacOS/
          Resources/

Create these directories/files, I'm going to assume `RecipeManager.app` is in the top-level directory of the repo.
In `Info.plist` paste:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleGetInfoString</key>
        <string>Recipe Manager</string>
        <key>CFBundleExecutable</key>
        <string>recipe</string>
        <key>CFBundleIdentifier</key>
        <string>name.szymonlopaciuk.recipe</string>
        <key>CFBundleName</key>
        <string>Recipe Manager</string>
        <key>CFBundleIconFile</key>
        <string>icon.icns</string>
        <key>CFBundleShortVersionString</key>
        <string>0.01</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>NSHighResolutionCapable</key>
        <true/>
        <key>IFMajorVersion</key>
        <integer>0</integer>
        <key>IFMinorVersion</key>
        <integer>1</integer>
      </dict>
    </plist>

### 2. Install the executable

    mv recipe RecipeManager.app/Contents/MacOS/recipe

### 3. Create an icon

Icons on macOS are in special ICNS format, so you will need to convert it from SVG.
I did it by converting `desktop/recipe-manager.svg` to png using AI (you could probably use Preview.app),
and then used [https://iconverticons.com/online/](https://iconverticons.com/online/) tool to get ICNS file.
If you get some better ideas on how to do it let me know!

Assuming ICNS file is called `recipe.icns` execute the following to install the icon:

    cp recipe.icns RecipeManager.app/Contents/Resources/recipe.icns

To refresh the icon in Finder, run `touch RecipeManager.app`. Some people also need to touch `Info.plist`,
however I didn't need to.

### 4. Install dylibs (even more optional)

Currently `recipe` is linked against libraries installed on your system, which makes it not portable,
i.e. it will not work if you just copy it to a different Mac. In order to make the app portable you will need
to copy the required libraries to `MacOS` and modify the executable file to use them.

Firstly, let's change the working directory to `MacOS`:

    cd RecipeManager.app/Contents/MacOS/

To figure out, what libraries are used by your executable you can run:

    otool -L recipe

This will spit out a list of paths to the dynamically linked libraries.
Copy all the ones not in `/System/Libraries` or `/usr/lib/` to `MacOS`.

    cp /path/to/library.dylib .

When all the libraries are copied, you can modify the executable file. For each dylib run:

    install_name_tool -change /path/to/original/library.dylib @executable_path/library.dylib recipe

## Et voilà!

The process is now finished. If you completed all the steps, you should now have a working
copy of Recipe Manager on your Mac, nicely packed as a native app bundle.
If you feel like at any point I made a mistake, or you would like me to clear anything up,
don't hesitate to drop me an email. Same goes for if you have any suggestions:
[szymonlopaciuk@protonmail.ch](szymonlopaciuk@protonmail.ch).

## Too tedious?

You can just grab a binary from [here]({{ site.baseurl }}/download/RecipeManager.zip).
However I cannot guarantee that this file will always be up to date, and working for you.
Feel free to [get in touch](szymonlopaciuk@protonmail.ch) in case you have any issues.
