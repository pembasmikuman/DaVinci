# DaVinci

The *Creation of Adam* hands, drawn entirely from 1s and 0s, with a Laravel-style cursor glow.

Inspired by the binary-art wordmark on Laravel's error page: move your mouse and a soft spotlight follows it, lighting up the characters underneath.

![The hands in 1s and 0s over a cloudy sky, glowing orange where the cursor passes](demo/demo.gif)

## Customize
Open `index.html` in a browser.

![Edit mode: selecting the right hand, moving, rotating and resizing it, then changing the glow color](demo/edit-mode.gif)


To save :

1. Click **Save for wallpaper**. It downloads `davinci.html` with your settings inside.
2. Run `./install.sh ~/Downloads/davinci.html`. It keeps only your settings, in `~/.config/davinci/settings.json`, and updates the wallpaper. `index.html` in the repo is never changed, so it keeps the defaults.

Later `./install.sh` runs, for example after pulling new code, reuse your saved settings. Delete `~/.config/davinci/settings.json` and run `./install.sh` again to go back to the defaults.

The settings button is hidden when the page runs as the wallpaper.

## Apply as wallpaper

### 1. KDE ( Needs `qt6-webengine`)

```sh
./install.sh <downloaded .html>
```

Installs the wallpaper and sets it on every desktop.

### 2. Other Distro & OS

Not yet but open to collaborate.

## How it works

- A grayscale image of the hands is embedded in the file as a data URI.
- The page splits the image into a grid of small cells and draws a character in each lit one, tinted dimmer or brighter to match the painting's shading. The **Style** picker chooses how: **Detail** (default) picks the character whose shape best matches the picture inside the cell (`/` or `\` on slanted edges, `|` and `-` on straight ones, `#` and `0` on bright areas). **Laravel** packs your Characters side by side in tight lines, in a fixed random mix, like the wordmark on Laravel's error page. **Classic** is an even grid of random Characters.
- The glow has two styles, picked in the panel. **Spotlight** (default) works like the radial mask on Laravel's error page: a soft round light follows the cursor, and each character blends from its gray toward the glow color the closer it is. **Heat** is the older look: the cursor heats nearby cells, their digits flip and burn toward the glow color, then cool back down. Either way the glow pauses while you drag, rotate or resize a picture.
- The background is plain black by default. Pick **Sky** or upload your own image in the panel, and the image behind the hands is blurred and darkened in a soft hand-shaped patch so the digits stay readable.
- On KDE, the desktop icon layer sits above the wallpaper and eats mouse events, so the wallpaper plugin reads the cursor with a see-through layer on top and hands it to the page.

## The math

### Making the ASCII

**1. Brightness of each pixel.** Every picture is drawn onto the screen, then each pixel becomes one brightness number from 0 to 255. Green counts the most because our eyes are most sensitive to it:

$$L = (0.3R + 0.59G + 0.11B) \cdot \frac{A}{255}$$

$A$ is how see-through the pixel is, so clear pixels count as dark. Where two pictures overlap, the brighter one wins.

**2. Light backgrounds get flipped.** A picture like R2-D2 is dark lines on white. The page first clears the white around it: starting from the edges, it spreads through every pixel within 40 of the corner color in each of R, G and B, and makes those see-through. Then it looks at what's left. If more of it is near-white ($L > 200$) than near-black ($L < 80$), like R2-D2, it flips it, so dark details turn into bright ink:

$$L' = 40 + (255 - L)\left(1 - \frac{40}{255}\right)$$

A mostly dark figure like Greninja keeps its brightness instead ($L' = 40 + L\,(1 - 40/255)$). If it were flipped, its white eyes would turn into gaps and its black outlines would blend into its dark blue body. Tux is the one built-in picture set by hand (`NO_FLIP` in `index.html`). He counts as mostly white because of his belly, but flipping him turns his eyes into dark boxes and hides his beak.

The 40 is a floor, so the dimmest parts become a faint fill instead of disappearing.

**3. The grid.** The screen is cut into square cells, **Spacing** pixels apart. A cell whose pixels are all 18 or darker stays empty.

**4. Picking a character by shape (Detail style).** Each candidate character (your Characters plus `. , - _ | / \ + = #`) is drawn once into a cell-sized square. That gives an ink amount $g_i$ from 0 to 1 for every pixel $i$. The picture inside the cell is turned into the same 0 to 1 scale by dividing by the brightest pixel on the whole screen, so a dim painting still reaches full ink:

$$p_i = \frac{L_i}{L_{\max}}$$

The winner is the character that looks most like the picture, meaning the smallest squared difference:

$$\text{best} = \arg\min_g \sum_i (p_i - g_i)^2 = \arg\min_g \left( \sum_i p_i^2 - 2\sum_i p_i g_i + \sum_i g_i^2 \right)$$

The first sum is the same for every character, so it can be dropped:

$$\text{score}(g) = \sum_i g_i^2 - 2\sum_i p_i g_i$$

$\sum g_i^2$ only depends on the character, so it's worked out once up front. For each cell, that leaves one multiply and add per pixel per character. This is why a slanted edge gets `/`: its ink sits right on the bright pixels, which makes $\sum p_i g_i$ big and the score low. It's the same idea the terminal art tool chafa uses.

**5. Gray level.** Each character's resting gray comes from the painting. $f$ is **Darkest digit** (0 to 1). $L$ is the brightest pixel in the cell for Detail, or the pixel at the cell's center for the other styles:

$$\text{base} = \left(f + \frac{L}{255}(1 - f)\right) \cdot 255$$

So the darkest parts of the painting sit at $f$, and the brightest reach full white.

### The glow

**How close the cursor is.** For a character $d$ pixels from the cursor, with glow **Size** $R$:

$$t = \max\left(0,\ 1 - \frac{d}{R}\right)$$

$t$ is 1 right under the cursor and fades in a straight line to 0 at $R$. That's the same fade as the mask on Laravel's error page, `radial-gradient(circle, black 0%, transparent 600px)`.

**Blending the color.** Each of R, G and B slides from the character's gray toward the glow color:

$$c = \text{base} + (\text{glow} - \text{base}) \cdot t$$

**Spotlight** uses $t$ as it is, so the light moves with the cursor and leaves nothing behind.

**Heat** gives each character its own heat $h$ that remembers the cursor. Every frame:

$$h \leftarrow \max(h, t), \qquad h \leftarrow 0.94\,h$$

and with a chance of $0.4\,h$ its digit flips to a random one. The blend then uses $h$ in place of $t$. At 60 frames a second, $0.94^n$ halves in about 11 frames (0.2s) and drops below 0.05 after about 48 frames (0.8s). At that point the character goes back to its resting shape.

**Pausing and resting.** While you drag, rotate or resize a picture, $R$ is set to 0, so $t$ is 0 everywhere (heat still cools off). Drawing stops 3 seconds after the mouse last moved, when every glow has faded, so an idle wallpaper uses almost no CPU.

### The digit styles

**Detail** uses the shape matching from step 4, in square cells.

**Laravel** packs characters like typed text. Columns step by the measured width of one `0` in the current font, so the characters touch. Rows stay **Spacing** apart. The character at column $x$, row $y$ comes from a small hash, with every step wrapping at 32 bits:

$$
\begin{aligned}
h &= 374761393\,x + 668265263\,y \\
h &= \bigl(h \oplus (h \gg 13)\bigr) \cdot 1274126177 \\
\text{index} &= \bigl(h \oplus (h \gg 16)\bigr) \bmod n
\end{aligned}
$$

$\oplus$ is XOR, $\gg$ shifts the bits right, and $n$ is how many Characters you typed. The same spot always gives the same character, so the pattern never flickers when the grid rebuilds, but neighbors look unrelated. Every character you type gets about the same share, so repeating one changes the mix: `11110` comes out about 80% ones, close to the 82% in Laravel's own wordmark.

**Classic** uses square cells, and each one gets a fresh random character every time the grid rebuilds.

With the **Heat** glow, hot cells in any style show a flipping random digit. Once they cool, Detail and Laravel go back to their own character, while Classic keeps whichever digit it landed on.
