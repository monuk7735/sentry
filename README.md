<img src=".github/res/Sentry-Logo.png" width="200" alt="App icon" align="left"/>

<div>
<h3 style="font-size: 2.5rem; letter-spacing: 1px;">Sentry</h3>
<p style="font-size: 1.15rem; font-weight: 500;">
    <strong>Secure your workflow without stopping it.</strong><br>
    Sentry allows you to "lock" your Mac effectively—preventing unauthorized access with a Kiosk-style shield—while keeping the system technically unlocked. This ensures that long-running tasks like **compiling code, downloading large files, or rendering video** continue uninterrupted in the background, which would otherwise be paused by the native macOS sleep/lock.
  </p>

<br/><br/>

<div align="center">

[![GitHub License](https://img.shields.io/github/license/monuk7735/sentry)](LICENSE)
  [![Downloads](https://img.shields.io/github/downloads/monuk7735/sentry/total.svg)](https://github.com/monuk7735/sentry/releases)
  [![Issues](https://img.shields.io/github/issues/monuk7735/sentry.svg)](https://github.com/monuk7735/sentry/issues)
  [![Pull Requests](https://img.shields.io/github/issues-pr/monuk7735/sentry.svg)](https://github.com/monuk7735/sentry/pulls)
  [![macOS Version](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://www.apple.com/macos/)

<br/>

<a href="https://github.com/monuk7735/sentry/releases"><img src=".github/res/macOS-Download.png" width="160" alt="Download for macOS"/></a>

<br/>

<img src=".github/res/Screenshot.png" width="100%" alt="Sentry Preview"/><br/>

</div>

<hr>

## Features

- **Prevent Sleep** - Keeps your Mac awake and active (disables idle sleep) while locked, ensuring background tasks continue uninterrupted.
- **Kiosk-Style Security** - Hides the Dock, Menu Bar, and disables process switching (`Cmd+Tab`) while locked to prevent unauthorized access.
- **Biometric Unlock** - Integrated directly with **Touch ID** for seamless, fast unlocking.
- **Smart Fallback** - Detects when Touch ID is unavailable (e.g., Clamshell mode) and provides clear instructions to use standard system lock (`Cmd+Ctrl+Q`).
- **Multi-Display Support** - Automatically detects and covers all connected displays, including new connections while locked.
- **Visual Feedback** - Shake animations on interaction and smooth fade transitions.
- **Resilient Focus** - Aggressively maintains focus to prevent being bypassed by system shortcuts or other apps.
- **Menu Bar App** - Unobtrusive menu bar item for quick activation.
- **SwiftUI & AppKit** - built for modern macOS performance.

## Installation

1. Download the latest release from [GitHub Releases](https://github.com/monuk7735/sentry/releases).
2. Move the app to the Applications folder.
3. Run the app and grant necessary permissions if prompted.

### ⚠️ "Damaged" or "Unidentified Developer" Error?

> I don't have an Apple Developer account yet, so the application will display a popup on the first launch.

**Option 1 (Recommended): Allow via System Settings**

1. Open **System Settings** → **Privacy & Security**.
2. Scroll down to the **Security** section.
3. Look for "**Sentry** was blocked..." and click **Open Anyway**.
4. Click **Open** in the confirmation popup.

**Option 2 (Advanced): Run this command in Terminal**

```bash
xattr -cr /Applications/Sentry.app
```

This command simply removes the "quarantine" flag that macOS places on apps downloaded from the internet, resolving the false error.

- `xattr` : The utility to modify file attributes.
- `-c` : Clears all attributes (removes the "quarantine" flag).
- `-r` : Recursive (applies to all files inside the app bundle).

## Usage

1. Launch **Sentry**.
2. Click the shield icon in the menu bar.
3. Select **Activate** (or use `Cmd+Shift+L` if configured).
4. Your screen is now vigilant!
5. To unlock, simply use **Touch ID**.
   - If Touch ID is not available, the app will guide you to secure the system manually.

## Roadmap

- [x] ~~Implement Kiosk Mode (Sandboxed Input Capture).~~
- [x] ~~Multi-Display Support with dynamic connection handling.~~
- [x] ~~Touch ID Authentication.~~
- [x] ~~Smart focus stealing to prevent app switching.~~
- [x] ~~Touch ID Fallback UI.~~
- [ ] Intruder selfie capture (Future).
- [ ] Customizable lock screen backgrounds/widgets.
- [ ] Global keyboard shortcut for activation.

## Troubleshooting

**Touch ID not recognized?**
If Sentry fails to detect Touch ID or you are unable to unlock for any reason:
- Press **Command + Control + Q**.
- This will instantly trigger the native macOS system lock, securing your machine regardless of Sentry's state.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the [GPLv3 License](LICENSE).
