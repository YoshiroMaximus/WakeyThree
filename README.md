<div align="center">

# WakeyThree

**Wake your servers with one click.**

[![CI](https://github.com/YoshiroMaximus/WakeyThree/actions/workflows/ci.yml/badge.svg)](https://github.com/YoshiroMaximus/WakeyThree/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/YoshiroMaximus/WakeyThree)](https://github.com/YoshiroMaximus/WakeyThree/releases/latest)

[![Get it on GitHub](https://cdn.jsdelivr.net/npm/@intergrav/devins-badges@3/assets/cozy/available/github_vector.svg)](https://github.com/YoshiroMaximus/WakeyThree/releases/latest)

</div>

A lightweight Wake-on-LAN app for Apple platforms. Save a server's name and MAC address once, then wake it whenever you need it.

**macOS 15+**: menu bar app · **iPhone / iPad / Vision Pro**: tap to wake (build from source)

- One-click wake from the menu bar
- Wake from Shortcuts and Siri
- Cross-subnet wake via host/IP and port
- Clear feedback on whether the packet was sent
- Local SwiftData storage, no accounts, nothing sent except the wake packet

## Install

Download the DMG from the [latest release](https://github.com/YoshiroMaximus/WakeyThree/releases/latest) and drag the app to /Applications.

> [!IMPORTANT]
> The build is unsigned: on first launch, right-click the app and choose **Open**, then confirm.

The target machine needs Wake-on-LAN enabled ([setup guides](https://ieesizaq.com/wakeytoo/)).

<details>
<summary><b>Building from source</b></summary>

Requires Xcode 26+. Clone, `open WakeyThree.xcodeproj`, and run the `WakeyThree` scheme. iPhone, iPad, and Vision Pro builds are available this way too.

</details>

## Credits

Forked from [WakeyToo](https://github.com/keapick/WakeyToo) by echo / ieesizaq, GPL-3.0 licensed, as is WakeyThree.
