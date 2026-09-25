# DaVinci

The *Creation of Adam* hands, drawn entirely from 1s and 0s, with a Laravel-style cursor glow.

Inspired by the binary-art hero on Laravel's error page: move your mouse and nearby digits flip and burn red-orange, then cool back down.

![demo](https://raw.githubusercontent.com/pembasmikuman/DaVinci/main/screenshot.png)

## Run

Open `index.html` in a browser. That's it — one file, no dependencies, works offline.

## KDE Plasma live wallpaper

```sh
./install.sh
```

Installs the wallpaper and sets it on every desktop. Run it again after editing `index.html` to update. Needs `qt6-webengine`.

## How it works

- A grayscale image of the hands is embedded in the file as a data URI.
- The page samples the image's brightness on a grid and places a `0` or `1` at each lit pixel, dimmer or brighter to match the painting's shading.
- Each digit tracks a "heat" value: the cursor raises it (digit flips randomly and glows Laravel red-orange), then it decays each frame.

## Tweaks

All in `index.html`:

| What | Line |
|------|------|
| Glow radius | `const R = 220` |
| Glow color | `hsl(14 ...)` — hue 14 is red-orange, 220 blue, 140 green |
| Digit density | `const CELL = 8` |
