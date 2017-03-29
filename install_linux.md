---
layout: default
title: Install on Linux
categories: [ sidebar, gallery ]
---

# Installation on Linux

## Installing dependencies

Full list of dependencies below:

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

You will also need to [install Vala](https://wiki.gnome.org/Projects/Vala/ValaOnLinux).
Install the dependencies with the package manager of your choice.
You will need the development versions of packages, since you're building from source.

## Building and installation

The following commands will build the project and install it.
The binary will be put in `/usr/bin`, additionally preference file,
desktop file and icon file will be installed on your system.
See `Makefile` for more information.

    make
    sudo make install
