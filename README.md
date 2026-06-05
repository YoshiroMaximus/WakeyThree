# WakeyThree

A simple, minimalist [Wake-on-LAN](https://en.wikipedia.org/wiki/Wake-on-LAN) utility for Apple platforms. WakeyThree wakes computers on your local network by broadcasting a UDP "magic packet" to a saved MAC address.

- **macOS** — lives in the menu bar; click a server to wake it.
- **iOS / iPadOS / visionOS** — tap a server to wake it.

WakeyThree is a multiplatform SwiftUI rewrite of [WakeyToo](https://ieesizaq.com/wakeytoo/), targeting modern OS releases.

## Features

- Add, **edit**, and remove servers (name + MAC address)
- Wake a server with a single click/tap
- Most-recently-used servers float to the top
- Built-in log viewer for troubleshooting failed wakes
- Servers persist locally via SwiftData

## Requirements

- Xcode 26+
- macOS 26 / iOS 26 / visionOS 26 (deployment target 26.5)
- The target computer must support Wake-on-LAN and have it enabled
- Both devices must be on the **same local network**, and you must know the target's MAC address

See the original end-user docs (including per-platform setup guides for macOS, Windows, and Linux) at <https://ieesizaq.com/wakeytoo/>.

## Credits & license

Based on **WakeyToo** by [echo / ieesizaq](https://ieesizaq.com/wakeytoo/), whose [open-source repo](https://github.com/) is licensed under **GPL-3.0**. As a derivative work, WakeyThree is likewise distributed under the GPL-3.0.
