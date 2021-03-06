/*
* Copyright (c) 2017-2018 Carlos Suárez (https://github.com/bitseater)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; If not, see <http://www.gnu.org/licenses/>.
*
* Authored by: Carlos Suárez <bitseater@gmail.com>
*/
namespace Weather {

    public class MainWindow : Gtk.Window {

        public WeatherApp app;
        public AppIndicator.Indicator indicator;
        private Gtk.Grid view;
        public Weather.Widgets.Ticket ticket;

        public MainWindow (WeatherApp app) {
            this.app = app;
            this.set_application (app);
            this.set_default_size (750, 590);
            this.set_size_request (750, 590);
            window_position = Gtk.WindowPosition.CENTER;
            var header = new Weather.Widgets.Header (this, false);
            this.set_titlebar (header);

            //Define style
            var provider = new Gtk.CssProvider();
            provider.load_from_resource ("/com/github/bitseater/weather/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var setting = new Settings ("com.github.bitseater.weather");
            setting.get_boolean ("dark");
            if (setting.get_boolean ("dark")) {
                Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
            } else {
                Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", false);
            }

            //Create indicator and show if true:
            create_indicator ();
            if (setting.get_boolean ("indicator")) {
                show_indicator ();
                if (setting.get_boolean ("minimized")) {
                    this.no_show_all = true;
                }
            } else {
                hide_indicator ();
            }
            this.delete_event.connect (() => {
                if (setting.get_boolean ("indicator")) {
                    this.hide_on_delete ();
                } else {
                    (app as GLib.Application).quit ();
                }
                return true;
            });

            //create main view
            var overlay = new Gtk.Overlay ();
            view = new Gtk.Grid ();
            view.expand = true;
            view.halign = Gtk.Align.FILL;
            view.valign = Gtk.Align.FILL;
            view.attach (new Gtk.Label("Loading ..."), 0, 0, 1, 1);
            overlay.add_overlay (view);
            ticket = new Weather.Widgets.Ticket ("");
            overlay.add_overlay (ticket);

            // Set main content
            if (setting.get_string ("apiid") == "") {
                var apikey = new Weather.Widgets.Apikey (this, header);
                change_view (apikey);
            } else if (setting.get_boolean ("auto")) {
                if (Weather.Utils.geolocate ()) {
                    var view = new Weather.Widgets.Current (this, header);
                    change_view (view);
                } else {
                    var view = new Weather.Widgets.City (this, header);
                    change_view (view);
                    ticket.set_text (_("Unable to geolocalize you. Search for a location"));
                    ticket.reveal_child = true;
                }
            } else if (setting.get_string ("idplace") == "") {
                var city = new Weather.Widgets.City (this, header);
                change_view (city);
            } else {
                var current = new Weather.Widgets.Current (this, header);
                change_view (current);
            }
            add (overlay);
            this.show_all ();
        }

        public void set_icolabel (string icon, string label) {
            this.indicator.set_icon_full (icon, icon);
            this.indicator.label = label;
        }

        public void change_view (Gtk.Widget widget) {
            this.view.get_child_at (0,0).destroy ();
            widget.expand = true;
            this.view.attach (widget, 0, 0, 1, 1);
            widget.show_all ();
        }

        public void create_indicator () {
            indicator = new AppIndicator.Indicator ("weather", "weather-few-clouds-symbolic",
                                    AppIndicator.IndicatorCategory.APPLICATION_STATUS);
            indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);

            var menu = new Gtk.Menu();
            var show_item = new Gtk.MenuItem.with_label (_("Show Meteo"));
            show_item.activate.connect(() => {
                this.get_focus ();
                this.no_show_all = false;
                this.show_all ();
            });
            show_item.show();
            menu.append(show_item);

            var quit_item = new Gtk.MenuItem.with_label (_("Quit"));
            quit_item.show();
            quit_item.activate.connect(() => {
                (app as GLib.Application).quit ();
            });
            menu.append(quit_item);
            indicator.set_menu(menu);
            indicator.set_secondary_activate_target(quit_item);
        }

        public void show_indicator () {
            indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
        }

        public void hide_indicator () {
            indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
        }
    }
}
