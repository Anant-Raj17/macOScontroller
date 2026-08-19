# PadControl

A native macOS menu-bar app that maps a game controller to the pointer, clicks, Mission Control, keyboard shortcuts, and text-field focus.

Swift / SwiftUI only. No Electron, no background daemon, no App Sandbox. The app lives in the menu bar (`LSUIElement`) and has no Dock icon.

PadControl posts mouse and keyboard events with `CGEvent` and reads the focused window’s accessibility tree. Grant **Accessibility** in System Settings before it can control other apps. The source is public so that permission grant is inspectable.

## Requirements

- macOS 14 or later
- A controller macOS already sees (Xbox, DualSense, Switch Pro, 8BitDo in XInput mode, and other MFi / HID pads with an extended gamepad profile)
- Accessibility permission

## Quick start

1. Build and run (see [Build](#build)).
2. Look for the game-controller symbol in the menu bar.
3. System Settings → Privacy & Security → Accessibility → enable **PadControl**.
4. Connect a controller. Mapping is on by default once Accessibility is granted.

If the menu-bar icon is a warning triangle, Accessibility is not granted yet. Choose **Grant Accessibility…** from the menu.

## Default bindings

All of these are remappable in Settings.

| Control | Action |
| --- | --- |
| D-pad up | Mission Control |
| Right stick | Move pointer |
| Left trigger | Left click (hold to drag) |
| Right trigger | Right click |
| A / Cross | Highlight and focus the next text field in the focused window |

Unbound controls do nothing. Analog sticks can be assigned **Move pointer** or **Scroll**; buttons and triggers can be assigned clicks, a keyboard shortcut, Mission Control, App Exposé, Show Desktop, or text-field focus.

## Using the app

The menu bar extra lets you enable or disable mapping, see the connected controller, open Settings, and quit.

Settings include:

- Launch at login
- Stick deadzone, pointer speed, and scroll speed
- A live controller diagram that highlights the last input
- Per-control action assignment and a shortcut recorder
- Reset bindings to defaults

Mappings are stored at `~/Library/Application Support/PadControl/profile.json`.

## Build

```bash
brew install xcodegen   # only needed to regenerate the Xcode project
xcodegen generate
open PadControl.xcodeproj
```

Then Run in Xcode. The app has no Dock icon; look for the game-controller symbol in the menu bar.

The menu-bar icon is filled when mapping is enabled and a controller is connected, outlined when idle, and a warning triangle when Accessibility is missing.

Release build from the command line:

```bash
xcodebuild -scheme PadControl -configuration Release -derivedDataPath build
```

The `.app` lands under `build/Build/Products/Release/PadControl.app`.

## Permissions

System Settings → Privacy & Security → Accessibility → enable **PadControl**.

macOS keys Accessibility grants to the specific binary. After a rebuild, mapping often does nothing until you **remove PadControl from the list and add the new binary again**. Toggling the switch is often not enough.

## How it works

- `GameController.shouldMonitorBackgroundEvents` keeps pad input flowing while other apps are focused
- Analog sticks are sampled with `CADisplayLink` only while they sit outside the deadzone
- Pointer motion is posted as HID mouse events (not a cursor warp), so hover and drag work
- Mission Control is opened via `/System/Applications/Mission Control.app`
- Text-field focus walks the accessibility tree of the focused window, draws a short overlay, then focuses the field (click fallback)

Layout:

```
PadControl/
  App/            Menu bar extra, app model, launch-at-login
  Controller/     GameController discovery and input
  Mapping/        Bindings, profile store, mapping engine
  Actions/        Mouse, keyboard, and system actions
  Accessibility/  Text-field walk and highlight overlay
  Permissions/    Accessibility trust gate
  Settings/       Bindings UI and controller diagram
```

## Not in v1

Per-app profiles, gyro, haptics, virtual HID, and HID fallback for unrecognized pads.

## License

[MIT](LICENSE)
