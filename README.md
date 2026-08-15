# PadControl

A lightweight macOS menu-bar app that maps a game controller to the pointer, clicks, Mission Control, keyboard shortcuts, and text-field focus. Native Swift / SwiftUI. No Electron, no background daemon, no sandbox.

PadControl injects mouse and keyboard events with `CGEvent` and reads the focused window’s accessibility tree. Grant **Accessibility** in System Settings before it can control other apps. The source is public so that permission grant is inspectable.

## Requirements

- macOS 14 or later
- A controller macOS already sees (Xbox, DualSense, Switch Pro, 8BitDo in XInput mode, and other MFi / HID pads)
- Accessibility permission

## Default bindings

All of these are remappable in Settings.

- **D-pad up** — Mission Control
- **Right stick** — move the pointer
- **Left trigger** — left click (hold to drag)
- **Right trigger** — right click
- **A / Cross** — highlight and focus the next text field in the focused window

## Build

```bash
brew install xcodegen   # only needed to regenerate the Xcode project
xcodegen generate
open PadControl.xcodeproj
```

Then Run in Xcode. The app has no Dock icon; look for the game-controller symbol in the menu bar.

Release build from the command line:

```bash
xcodebuild -scheme PadControl -configuration Release -derivedDataPath build
```

The `.app` lands under `build/Build/Products/Release/PadControl.app`.

## Permissions

System Settings → Privacy & Security → Accessibility → enable **PadControl**.

If mapping does nothing after a rebuild, remove PadControl from the list and add the new binary again. Toggling the switch is often not enough.

## How it works

- `GameController.shouldMonitorBackgroundEvents` keeps pad input flowing while other apps are focused
- Analog sticks are sampled with `CADisplayLink` only while they sit outside the deadzone
- Pointer motion is posted as HID mouse events (not a cursor warp), so hover and drag work
- Mission Control is opened via `/System/Applications/Mission Control.app`
- Text-field focus walks the accessibility tree of the frontmost app (skipping PadControl itself when Settings is open), draws a short overlay, then focuses the field (click fallback)
- Keyboard shortcuts accept chords, single keys, and lone modifiers (e.g. Right ⌥). Lone modifiers are held while the controller button is held — useful for push-to-talk dictation

Mappings are stored at `~/Library/Application Support/PadControl/profile.json`.

## To-do

- [ ] Replace the menu bar icon with something clearer and more on-brand
- [ ] Redesign the Settings page so it feels sleeker and more presentable
- [ ] Ideate better default mappings and other ways to use the remaining buttons (workflows, dictation, window management, etc.)

## Not in v1

Per-app profiles, gyro, haptics, virtual HID, and HID fallback for unrecognized pads.
