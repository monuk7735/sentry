<img src=".github/res/Sentry-Logo.png" width="200" alt="App icon" align="left"/>

<div>
<h3 style="font-size: 2.5rem; letter-spacing: 1px;">Sentry</h3>
<p style="font-size: 1.15rem; font-weight: 500;">
    <strong>Keep your Mac awake and secure.</strong><br>
    Sentry is a free, open-source macOS app that prevents your machine from sleeping while maintaining a vigilant, Kiosk-style lock screen. It uses biometrics to ensure only you can access the system, perfect for leaving your Mac running tasks in a secure state.
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

> ### <span style="color: yellow">Note!</span>
> I don't have an Apple Developer account yet, so the application will display a popup on the first launch. 
>
> Click Okay, then navigate to **Settings > Privacy & Security**, scroll down, and click **Open Anyway**. 
> 
> This only needs to be done once.

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
