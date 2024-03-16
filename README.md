# MyChat

By Grimmier

## Basic Chat Window.

This was inspired because I play on Project Lazarus, and we don't have tabbed chat windows. Combine that with EQ's horrible filtering. This lets you create your own event based filters.

## Features:

* Customizable channels and colors.
* Channels get their own tab's you can toggle on or off.
  * Main chat tab will show all channels always.
  * Right Clicking a tab will clear it.
* Reads settings from MyChat_SERVERNAME_CHARNAME.Lua in the MQ\Config dir.
* You can customize any event string you would like and create a channel for it that you can turn on of off at any time.
* Toggling a channel on or off will save that setting to the settings Lua as well.
* Edit and Add Channels and events through a GUI.
* ZOOM. right click a tab to turn on ZOOM mode. this will scale up the font size.
* ZOOM mode is not a true console, instead we are using a table with wrapped text rows.
  * When Selecting a row or hovering with the mouse over one, pressing Ctrl-C will copy that line of text to the clipboard.
  * for more refined copy toggle the zoom off and use the normal console.
  * Auto locking Auto-Scroll, in Zoom mode.
    * if you scroll up auto scrolling for that tab's zoom window will unlock.
    * Scrolling back to the bottom will relock scroll on.

## Sample Config.

https://github.com/grimmier378/MyChat/blob/main/default_settings.lua

## IMAGES

![Screenshot 2024-03-13 002355](https://github.com/grimmier378/MyChat/assets/124466615/2406f5ad-edf4-48b2-983e-d061e61a6deb)
![MyChat_Zoom (2)](https://github.com/grimmier378/MyChat/assets/124466615/a2ac3909-3470-4d33-8a7f-41cae9ba64da)
![MyChat_Config](https://github.com/grimmier378/MyChat/assets/124466615/f284f649-3ff0-4f58-b051-6c47c2572ca9)
![MyChat_Zoom](https://github.com/grimmier378/MyChat/assets/124466615/fc9473ff-34f8-46eb-b0e4-46e4994f6af3)
