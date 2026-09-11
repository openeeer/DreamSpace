# WaveSpeed generation

## Update: user artwork integrated

The user supplied the first five images and a genuine RGBA nebula in `assets.zip`.
All eight dream covers and the cosmic background now have runtime WebP derivatives.
The native-alpha user nebula replaces the processed fallback and is used as a subtle
animated foreground layer. `user_assets.json` records source dimensions and hashes.
The superseded WaveSpeed nebula source is retained in `superseded/nebula_foreground.png`.
The old `nebula_foreground_alpha.png` is a historical derivative, not used by the app.
Only explicit WebP runtime files are bundled; PNG source masters stay in the project.

## Original generation record

Model: `openai/gpt-image-2.5-sunburst/text-to-image`.
All six successful jobs explicitly requested `resolution: 2k`, `quality: medium`, `output_format: png`.

| Asset | API output size | Source |
|---|---|---|
| Glass staircase | 2224×1664 | `assets/dreams/glass_staircase.png` |
| Last train | 2224×1664 | `assets/dreams/last_train.png` |
| Sky islands | 2224×1664 | `assets/dreams/sky_islands.png` |
| Door under water | 2224×1664 | `assets/dreams/door_under_water.png` |
| Nebula foreground | 2352×1568 | `assets/backgrounds/nebula_foreground.png` |
| App icon | 1920×1920 | `assets/branding/app_icon.png` |

The dimensions are the service's native 2K outputs, not locally upscaled images. Each adjacent JSON receipt includes task ID, exact prompt, request parameters and file size. No API key is stored in these files or scripts.

Four WebP cover derivatives at 1600×1197 are provided alongside PNG masters. They match existing application asset paths and will appear on the next app build.

The nebula model output is RGB with a baked checkerboard, despite the transparency prompt. `nebula_foreground_alpha.png` and `nebula_foreground.webp` are locally processed, softened chroma-matte derivatives, not native model transparency. `nebula_preview.jpg` shows the derivative on the app background. This soft background overlay is suitable for restrained use; fine cloud detail and edges need visual review at integration.

The icon PNG is the 2K master; platform icon sizes are not regenerated in this task.

One icon submission received HTTP 429 before a task was created. Retrying only that missing asset succeeded; completed image tasks were reused without resubmission.

Regeneration tooling: `tools/generate_assets.py` reads `WAVESPEED_API_KEY` from the process environment and resumes stored task IDs. `tools/prepare_generated_assets.py` requires Pillow and produces local derivatives.
