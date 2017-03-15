VALAC=valac
VALA_PKGS=--pkg gtk+-3.0 --pkg cairo --pkg pango --pkg json-glib-1.0 --pkg posix
VALA_FLAGS=--Xcc="-lm" --gresources gresource.xml --target-glib=2.38

all: ./src/resource.c
	valac $(VALA_PKGS) $(VALA_FLAGS) -o recipe ./src/*.vala ./src/resources.c

debug: ./src/resource.c
	valac $(VALA_PKGS) $(VALA_FLAGS) -g -o recipe ./src/*.vala ./src/resources.c

./src/resource.c: gresource.xml
	glib-compile-resources gresource.xml --generate-dependencies
	glib-compile-resources gresource.xml --target=./src/resources.c --generate-source

clean:
	rm ./src/resources.c
	rm recipe

install:
	cp -f recipe /usr/bin/
	cp -f desktop/RecipeManager.desktop /usr/share/applications/
	cp -f desktop/recipe-manager.svg /usr/share/icons/hicolor/scalable/apps/
	cp -f recipe-manager-conf.json $(HOME)/.config/

uninstall:
	rm -f /usr/bin/recipe
	rm -f /usr/share/applications/RecipeManager.desktop
	rm -f /usr/share/icons/hicolor/scalable/apps/recipe-manager.svg
	rm -f $(HOME)/.config/recipe-manager-conf.json
