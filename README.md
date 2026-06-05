# MacStatus

A lightweight macOS dashboard for checking the current time and running apps.

## Features

- Live clock and date.
- Running app list from `NSWorkspace`.
- Search by app name or bundle identifier.
- Optional background-process visibility.
- Keyboard shortcuts:
  - `Command R`: refresh running apps.
  - `Command Shift H`: hide the app.
  - `Command F`: search.
  - `Command W`: close the window.

## Local Run

```bash
./script/build_and_run.sh
```

## App Store Notes

The app uses App Store-friendly APIs for the first version. It does not inspect windows, keystrokes, screen content, network traffic, or private process memory.

Before App Store submission, build with full Xcode, configure your Apple Developer Team, enable App Sandbox, use `Sources/MacStatusApp/Resources/MacStatus.entitlements`, archive, validate, and upload through Organizer or Transporter.

Privacy policy page source: `docs/privacy/index.html`.
