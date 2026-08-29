# Look & Feel Center (`bohar.looknfeel_center`)

A visual customization center and Quick Bar widget for **Omarchy Linux**. 
Provides responsive glass opacity cards, island bar transparency presets, frosted window blur controls, live terminal font scaling, and wallpaper interval rotation.

---

## Features

* **Glass Opacity Selector:** 8 discrete responsive stepping cards (`15% Ghost` to `100% Solid`).
* **Island Bar Opacity:** 6 preset cards (`0% Full Glass` to `100% Solid Bar`).
* **Frosted Window Blur:** 4-pill quick toggle (`4px`, `8px`, `12px`, `16px`).
* **Live Terminal Typography Scaler:** Dynamically adjusts and live-reloads font sizing across **Foot** and **Ghostty** terminals.
* **Wallpaper Interval Rotation:** Configurable timer daemon controls (`Off`, `30s`, `1m`, `5m`, `10m`, `18m`, `30m`).
* **100% Self-Contained:** Bundles all required helper binaries inside `scripts/` with relative PATH resolution.

---

## Installation

1. Clone into your Omarchy plugins directory:
   ```bash
   git clone https://github.com/bhjhmkpk-commits/bohar.looknfeel_center.git ~/.config/omarchy/plugins/bohar.looknfeel_center
   ```

2. Reload Omarchy Shell:
   ```bash
   omarchy restart shell
   ```

---

## Architecture & Compatibility

* **Compositor:** Hyprland 0.54+ / Wayland.
* **Shell Host:** Quickshell / Omarchy Shell.
* **Zero Host Modifications:** Operates entirely in user-space without modifying `/usr/share/omarchy/`.

---

## License
MIT License.
