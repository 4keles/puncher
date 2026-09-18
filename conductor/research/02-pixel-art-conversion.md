# Research 02 — Image-to-Pixel-Art Conversion Algorithms

*Date: 2026-09-18 · Purpose: determine the algorithmic pipeline for the
`Pixelate` command.*

## Color Quantization

Median cut and Wu split the RGB box; k-means clusters pixels. Median cut is
the fastest, Wu has a better quality/speed balance. For small palettes (8-32
colors), **hybrid** approaches give the best result: a deterministic start
with Wu, followed by k-means / Voronoi iteration to pull toward a local
optimum.

**libimagequant / pngquant** does exactly this: it repeats variance-based
median cut while weighting poorly represented colors, then corrects with
Voronoi (k-means) iteration; it applies dithering only in homogeneous
non-edge regions (adaptive error diffusion). It gives a noticeably cleaner
result than plain median cut.

Sources: <https://pngquant.org/lib/>,
<http://blog.pkh.me/p/39-improving-color-quantization-heuristics.html>

## Palette Mapping and Color Space

CIELAB has perceptual flaws such as a hue shift toward purple in blue tones.
**OKLab / OKLCh** fixes this: there is no hue deviation across
lightness/darkness, Euclidean distance directly represents perceptual
difference, and the per-pixel cost is low. For mapping onto a fixed palette
(DB16, PICO-8, AAP-64), OKLab distance is noticeably more accurate than RGB.

**Hue shifting** (shifting toward cool/purple in shadow, warm/yellow in
light) is a classic pixel art technique, and can be modeled mathematically as
a linear/curved shift of the hue angle in HSL/OKLCh dependent on value —
ramp generation can be fully automated.

Sources: <https://bottosson.github.io/posts/oklab/>,
<https://www.pixel-editor.com/articles/color-theory-for-pixel-art>

## Dithering

| Method | Assessment |
| --- | --- |
| **Bayer (ordered)** | Regular, tile-friendly, **stable in animation** — the pattern doesn't shift between frames. Best suited for character sprites. |
| Floyd-Steinberg | Good for photos, dirty/noisy for pixel art. The "shifting" noise between frames creates **temporal noise (flicker) in animation** → eliminated. |
| Blue noise | Most organic but too much for a character sprite; suitable for textures/backgrounds. |
| Off | Best for small sprites, small palettes, and cases requiring a clear silhouette. |

The most balanced method is to apply dithering conditionally, only in
gradient regions, the way libimagequant does.

Sources: <https://www.ascii-magic.com/blog/complete-guide-to-dithering>,
<https://surma.dev/things/ditherpunk/>

## Downscaling and Gerstner et al.

"Pixelated Image Abstraction" (Gerstner, DeCarlo, Alexa, Finkelstein,
Gingold, Nealen — **NPAR 2012**) optimizes superpixel-like regions and a
reduced palette **together** ("mass-constrained deterministic annealing"):
region assignment and color centers are solved simultaneously. While simple
nearest-neighbor or area-average distorts thin lines and the silhouette,
this method gives a result close to what pixel artists do by hand (validated
by a user study).

**Cost:** iterative optimization, on the order of seconds — not real-time.
Not practical in Lua; a v2 target.

A cheaper alternative: detecting edges and shifting the downscale kernel
into alignment (content-adaptive / edge-aware downscaling; the same family
as Kopf et al. SIGGRAPH Asia 2013).

Sources:
<https://pixl.cs.princeton.edu/pubs/Gerstner_2012_PIA/index.php>,
<https://pixl.cs.princeton.edu/pubs/Gerstner_2012_PIA/Gerstner_2012_PIA_full.pdf>,
<https://yogthos.net/posts/2025-12-11-edge-aware-pixelation.html>

## Cleanup Steps

Anti-aliasing removal, jaggy correction, outline generation, and
isolated-pixel cleanup are combined in a single open-source tool:
**PixelRefiner** (browser-based) — OKLab + k-means quantization, 8-way/4-way
outline generation, "Off/Light/Auto/Strong" noise-cleanup modes. Valuable as
an architectural reference.

Source: <https://github.com/HappyOnigiri/PixelRefiner>

## Alpha

Simple thresholding is common practice: `alpha < threshold` → fully
transparent, above it → fully opaque. This reduces edge blur (alpha bleed)
to 1-bit alpha. Pixel art rarely requires gradient alpha.

## AI Approaches and Temporal Consistency

"Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization"
(SIGGRAPH Asia 2022) splits the process into cell-aware and aliasing-aware
stages; it regularizes grid/cell structure using reference pixel art.
However, this and diffusion-based approaches (Sprite Sheet Diffusion, arXiv
2412.03685) **can shift the palette and grid alignment when generating
frame-by-frame independently.**

What's needed for consistency: (a) fixing the palette once and forcing it
onto all frames, (b) detecting grid alignment on the first frame and keeping
it fixed, (c) character-identity constraints. In practice the AI step can
only be an initial draft; deterministic post-processing (palette locking +
grid alignment) afterward is mandatory.

Sources: <https://github.com/WuZongWei6/Pixelization>,
<https://arxiv.org/pdf/2412.03685>

## Libraries

On the Python side, Pillow, numpy/scikit-image
(`skimage.segmentation.slic`), **hitherdither**
(<https://github.com/hbldh/hitherdither>), and libimagequant bindings are
available. Median cut / k-means can be written in Lua; SLIC-based superpixel
optimization is not practical due to Lua's performance limits.

## Proposed Pipeline

Labels: **[L]** = can be done in Lua · **[X]** = requires an external tool
(our decision: **[X]** steps are deferred to v2, the MVP is built only with
**[L]** steps).

1. **[L]** Input normalization (optional blur/resize cleanup).
2. **[X]** Target resolution detection (edge-frequency / Fourier analysis) —
   taken from the user in the MVP.
3. **[X]** Edge-aware or Gerstner-style downscale — a simple area-average +
   edge-preservation heuristic in the MVP.
4. **[L/X]** Color quantization: an initial palette with Wu (8-32 colors) +
   k-means refinement, distance metric OKLab. Can be done in Lua over
   `Image.bytes`; may slow down on large, highly colorful images.
5. **[L]** Mapping to a fixed palette (if the user selected
   DB16/PICO-8/AAP-64): snap to the nearest color by OKLab distance.
6. **[L]** Dithering decision: **off by default** for character sprites;
   Bayer 4x4/8x8 if desired. Floyd-Steinberg never.
7. **[L]** Anti-aliasing / jaggy cleanup: isolated-pixel cleanup via 3x3
   neighborhood majority vote.
8. **[L]** Outline generation (optional): a fixed or darkened 4-way/8-way
   contour.
9. **[L]** Alpha thresholding (e.g., below 25% → 0, above → 255).
10. **[L]** **Palette and grid locking:** the palette and grid alignment
    produced in steps 4-5 are forcibly applied to ALL frames. Critical for
    animation consistency.
11. **[X, v2]** AI-based initial draft (GAN/diffusion pixelization) +
    passing it through the deterministic pipeline of steps 4-10.

MVP note: the most expensive part of steps 3-5 can be skipped; Wu + k-means
alone, with a simple downscale, gives an acceptable result.
