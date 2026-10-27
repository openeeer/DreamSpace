"""Batch-generate all DreamSpace 'Deep Tide' assets via OpenRouter."""
import os, sys, json, base64, urllib.request
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from gen_asset import KEY, MODEL

STYLE = ("dreamy matte painting, deep teal and midnight petrol-blue palette, "
         "warm ivory moonlight glow, soft volumetric light, painterly grain, "
         "cinematic night atmosphere, no text, no watermark")

DREAMS = {
    'moon_library':      "a floating library of open books drifting among soft clouds under a huge luminous full moon",
    'ocean_without_end': "a tiny wooden rowboat on a calm endless ocean reflecting stars, a silver moonpath on the water",
    'red_forest':        "a surreal night forest with crimson foliage and deep blue shadows, a glowing doorway of light between two trees",
    'empty_city':        "an empty night city street, warmly lit cafe windows with steaming cups, wet asphalt reflections",
    'glass_staircase':   "a translucent glass staircase ascending into a starry night sky above the clouds, moon reflected in the steps",
    'last_train':        "an old train waiting at a foggy night platform, warm light in the carriage windows, an old clock tower",
    'sky_islands':       "floating sky islands with a giant tree glowing soft gold, waterfalls dissolving into clouds below",
    'door_under_water':  "a wooden door standing on the deep ocean floor, warm light behind it, a short staircase and drifting bubbles",
}

SPECIAL = {
    'assets/backgrounds/cosmic_background.png': (
        "a vast deep night sky, very dark petrol blue, subtle distant nebula haze, dense tiny sharp stars, minimal and quiet", '1024x1536'),
    'assets/backgrounds/nebula_foreground.png': (
        "wisps of glowing teal and jade aurora clouds, wispy tendrils, on a pure solid black background", '1536x1024'),
    'assets/profile/dream_sphere.png': (
        "a glowing sphere like a small dream planet made of swirling luminous teal clouds and tiny stars, centered, on a pure solid black background", '1024x1024'),
    'assets/profile/profile_landscape.png': (
        "a soft dreamlike alien coastline at night with glowing luminous tide lines and a low moon, on a pure solid black background", '1536x1024'),
    'assets/profile/quote_moon.png': (
        "a large crescent moon with a soft warm halo, alone on a pure solid black background, painterly", '1024x1024'),
    'assets/launch/background.png': (
        "a very deep quiet night sky, thin elegant crescent moon, scattered stars, a faint comet trail, almost black petrol blue", '1024x1536'),
}

def call(prompt, size):
    req = urllib.request.Request(
        'https://openrouter.ai/api/v1/images/generations',
        data=json.dumps({'model': MODEL, 'prompt': f'{prompt}, {STYLE}', 'size': size}).encode(),
        headers={'Authorization': f'Bearer {KEY}', 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=300) as r:
        body = json.loads(r.read().decode())
    b64 = (body.get('data') or [{}])[0].get('b64_json')
    if not b64:
        raise RuntimeError(f'no data: {str(body)[:200]}')
    return base64.b64decode(b64)

def save(raw, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(raw)
    print(f'OK {path} {os.path.getsize(path)//1024}KB', flush=True)

def to_alpha_sprite(src, dst, gain=1.0):
    """Luminance-max -> alpha; color kept. For black-background glow art."""
    im = Image.open(src).convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _ = px[x, y]
            a = max(r, g, b)
            if a > 0:
                f = min(255, int(a * gain))
                px[x, y] = (r, g, b, f)
            else:
                px[x, y] = (0, 0, 0, 0)
    im.save(dst)
    print(f'SPRITE {dst} {os.path.getsize(dst)//1024}KB', flush=True)

# 1. Dream artworks (landscape, fallback to square)
for name, prompt in DREAMS.items():
    out = f'assets/dreams/{name}.png'
    if os.path.exists(out):
        print(f'SKIP {out}', flush=True); continue
    try:
        save(call(prompt, '1536x1024'), out)
    except Exception as e:
        print(f'RETRY {name} square: {e}', flush=True)
        save(call(prompt, '1024x1024'), out)

# 2. Special assets
for path, (prompt, size) in SPECIAL.items():
    if os.path.exists(path):
        print(f'SKIP {path}', flush=True); continue
    save(call(prompt, size), path)

# 3. Alpha sprites from black-background art
to_alpha_sprite('assets/backgrounds/nebula_foreground.png', 'assets/backgrounds/nebula_foreground_alpha.png', 1.15)
print('ALL DONE', flush=True)
