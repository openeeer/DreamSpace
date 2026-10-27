"""Regenerate Deep Tide dream artworks + backgrounds, overwriting old ones."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from gen_asset import generate

STYLE = ("dreamy matte painting, deep teal and midnight petrol-blue palette, "
         "warm ivory moonlight glow, soft volumetric light, painterly grain, "
         "cinematic night atmosphere, no text, no watermark")

DREAMS = {
    'moon_library':      "a floating library of open books drifting among soft clouds under a huge luminous full moon",
    'ocean_without_end': "a tiny wooden rowboat on a calm endless ocean reflecting stars, a silver moonpath on the water",
    'red_forest':        "a surreal night forest with crimson foliage and deep teal shadows, a glowing doorway of light between two trees",
    'empty_city':        "an empty night city street, warmly lit cafe windows with steaming cups, wet asphalt reflections",
    'glass_staircase':   "a translucent glass staircase ascending into a starry night sky above the clouds, moon reflected in the steps",
    'last_train':        "an old train waiting at a foggy night platform, warm light in the carriage windows, an old clock tower",
    'sky_islands':       "floating sky islands with a giant tree glowing soft gold, waterfalls dissolving into clouds below",
    'door_under_water':  "a wooden door standing on the deep ocean floor, warm light behind it, a short staircase and drifting bubbles",
}
for name, prompt in DREAMS.items():
    out = f'assets/dreams/{name}.png'
    ok = generate(f'{prompt}, {STYLE}', out, '1536x1024')
    if not ok:
        generate(f'{prompt}, {STYLE}', out, '1024x1024')

print('--- backgrounds ---', flush=True)
generate(f"a vast deep night sky, very dark petrol blue, subtle distant nebula haze, dense tiny sharp stars, minimal and quiet, {STYLE}",
         'assets/backgrounds/cosmic_background.png', '1024x1536')
generate(f"wisps of glowing teal and jade aurora clouds, wispy tendrils, on a pure solid black background, {STYLE}",
         'assets/backgrounds/nebula_foreground.png', '1536x1024')
print('--- profile ---', flush=True)
generate(f"a glowing sphere like a small dream planet made of swirling luminous teal clouds and tiny stars, centered, on a pure solid black background, {STYLE}",
         'assets/profile/dream_sphere.png', '1024x1024')
generate(f"a soft dreamlike alien coastline at night with glowing luminous tide lines and a low moon, on a pure solid black background, {STYLE}",
         'assets/profile/profile_landscape.png', '1536x1024')
print('--- launch ---', flush=True)
generate(f"a very deep quiet night sky, thin elegant crescent moon, scattered stars, a faint comet trail, almost black petrol blue, {STYLE}",
         'assets/launch/background.png', '1024x1536')
print('DONE', flush=True)
