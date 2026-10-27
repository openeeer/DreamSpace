import os, json, urllib.request

key = None
model = None
with open('.env', encoding='utf-8') as f:
    for line in f:
        if '=' in line:
            k, v = line.strip().split('=', 1)
            if k == 'OPENROUTER_API_KEY': key = v
            if k == 'OPENROUTER_IMAGE_MODEL': model = v

req = urllib.request.Request(
    'https://openrouter.ai/api/v1/images/generations',
    data=json.dumps({
        'model': model,
        'prompt': 'A tiny glowing jellyfish drifting in deep dark teal water, minimal, dreamy',
    }).encode(),
    headers={'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'},
)
try:
    with urllib.request.urlopen(req, timeout=180) as r:
        body = r.read().decode()
        print('STATUS', r.status)
        print(body[:2000])
except urllib.error.HTTPError as e:
    print('HTTP', e.code)
    print(e.read().decode()[:2000])
